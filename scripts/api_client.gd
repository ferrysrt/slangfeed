extends Node
## API Client — LLM#2 Generator dengan RANTAI PROVIDER.
## Tier 1: Groq LPU (primary — sesuai proposal Batasan #3: latensi rendah, 500+ t/s)
## Tier 2: OpenRouter (fallback — agregator, model sama openai/gpt-oss-120b)
## Tier 3: fallback.json statis terkurasi (15 soal manual)
## Aturan per provider: 1 percobaan + 1 retry (SRS FR-C4).
## Kegagalan permanen (401/403 = key invalid) → langsung pindah provider tanpa retry.
## Kontrak output LLM (plan1-revisi 4.3): post_text, comment_text, options[4] unik,
## correct_index, explanation. Tidak terpenuhi = gagal → jalur retry/fallback.

signal batch_received(posts: Array, is_fallback: bool, adaptation_note: String)
signal batch_failed(error: String)

var _http: HTTPRequest
var _fallback_data: Dictionary = {}
var _provider_idx: int = 0
var _retry_count: int = 0
var _current_entries: Array = []
var _request_start_ms: int = 0
var _metrics := {"generated": 0, "fallback": 0, "invalid_json": 0, "provider_switches": 0, "last_latency_ms": 0, "last_provider": ""}

func _ready() -> void:
	randomize()
	_http = HTTPRequest.new()
	_http.timeout = Config.LLM_TIMEOUT_SEC
	_http.use_threads = true
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_load_fallback()
	var t1: Dictionary = Config.LLM_PROVIDERS[0]
	print("[APIClient] Init OK. Tier1: ", t1.get("name"), " (", t1.get("model"), ") key=", not _get_key_for(t1).is_empty(),
		" | Tier2: ", Config.LLM_PROVIDERS[1].get("name"), " key=", not _get_key_for(Config.LLM_PROVIDERS[1]).is_empty())

# ===== API KEY (SRS NFR-5: user:// file → env var; tidak dibundle) =====

func _get_key_for(provider: Dictionary) -> String:
	var fname := "user://" + str(provider.get("key_file", ""))
	if FileAccess.file_exists(fname):
		var f := FileAccess.open(fname, FileAccess.READ)
		if f:
			var key := f.get_as_text().strip_edges()
			f.close()
			if key != "":
				return key
	return OS.get_environment(str(provider.get("env_var", ""))).strip_edges()

# ===== FALLBACK STATIS (Tier 3) =====

func _load_fallback() -> void:
	var file := FileAccess.open("res://data/fallback_posts.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_fallback_data = json.data
			print("[APIClient] Fallback loaded: ", _fallback_data.get("posts", []).size(), " posts")
			return
	print("[APIClient] WARNING: fallback_posts.json tidak bisa dibaca!")

# ===== REQUEST FLOW =====

func request_batch(session_context: Dictionary) -> void:
	var used: Array = session_context.get("slangs_already_used", [])
	var picked := _pick_entries(Config.BATCH_SIZE, used)
	if picked.is_empty():
		picked = _pick_entries(Config.BATCH_SIZE, [])
	if picked.is_empty():
		_use_fallback("Dataset kosong — tidak ada entri tersedia")
		return
	_current_entries = picked
	_provider_idx = 0
	_retry_count = 0
	_try_current_provider()

func _try_current_provider() -> void:
	if _provider_idx >= Config.LLM_PROVIDERS.size():
		_use_fallback("Semua provider LLM gagal")
		return
	var provider: Dictionary = Config.LLM_PROVIDERS[_provider_idx]
	var api_key := _get_key_for(provider)
	if api_key == "":
		print("[APIClient] [", provider.get("name"), "] key tidak tersedia → tier berikutnya")
		_next_provider("key kosong")
		return
	_send_request(provider, api_key)

func _send_request(provider: Dictionary, api_key: String) -> void:
	var body := JSON.stringify({
		"model": provider.get("model"),
		"temperature": Config.LLM_TEMPERATURE,
		"max_tokens": Config.LLM_MAX_TOKENS,
		"messages": [
			{"role": "system", "content": _build_system_prompt()},
			{"role": "user", "content": _build_user_prompt(_current_entries)},
		],
	})
	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key,
	]
	_request_start_ms = Time.get_ticks_msec()
	print("[APIClient] POST ", provider.get("name"), " (", provider.get("model"), "), attempt ", _retry_count + 1)
	var err := _http.request(str(provider.get("url")), headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_on_attempt_failed("request() error %d" % err)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_metrics.last_latency_ms = Time.get_ticks_msec() - _request_start_ms
	if result != HTTPRequest.RESULT_SUCCESS:
		_on_attempt_failed("result=%d (%s)" % [result, _result_name(result)])
		return
	if response_code == 401 or response_code == 403:
		# Key invalid/tercabut → retry di provider yang sama percuma
		_next_provider("HTTP %d (key invalid)" % response_code)
		return
	if response_code == 429:
		# Rate limit → retry di provider yang sama kemungkinan besar gagal juga
		_next_provider("HTTP 429 (rate limit)")
		return
	if response_code != 200:
		print("[APIClient] HTTP %d: %s" % [response_code, body.get_string_from_utf8().substr(0, 200)])
		_on_attempt_failed("HTTP %d" % response_code)
		return

	var text := body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		_on_attempt_failed("respons bukan JSON valid")
		return

	var content := ""
	var choices = parsed.get("choices", [])
	if choices.size() > 0 and choices[0] is Dictionary:
		var msg = choices[0].get("message", {})
		if msg is Dictionary:
			content = str(msg.get("content", ""))
	if content == "":
		_on_attempt_failed("choices kosong")
		return

	var posts := _validate_and_expand(content)
	if posts.is_empty():
		_metrics.invalid_json += 1
		_on_attempt_failed("kontrak JSON LLM tidak terpenuhi")
		return

	_metrics.generated += posts.size()
	var pname := str(Config.LLM_PROVIDERS[_provider_idx].get("name"))
	_metrics.last_provider = pname
	print("[APIClient] SUCCESS via ", pname, ": %d soal valid (%d ms)" % [posts.size(), _metrics.last_latency_ms])
	batch_received.emit(posts, false, "LLM#2 via " + pname)

func _on_attempt_failed(reason: String) -> void:
	print("[APIClient] Attempt gagal: ", reason)
	if _retry_count < 1:
		_retry_count += 1
		_try_current_provider()
	else:
		_next_provider(reason)

func _next_provider(reason: String) -> void:
	_provider_idx += 1
	_retry_count = 0
	_metrics.provider_switches += 1
	if _provider_idx < Config.LLM_PROVIDERS.size():
		var next: Dictionary = Config.LLM_PROVIDERS[_provider_idx]
		print("[APIClient] Pindah ke tier ", _provider_idx + 1, ": ", next.get("name"), " (alasan: ", reason, ")")
	_try_current_provider()

func _result_name(r: int) -> String:
	match r:
		HTTPRequest.RESULT_SUCCESS: return "SUCCESS"
		HTTPRequest.RESULT_CANT_CONNECT: return "CANT_CONNECT"
		HTTPRequest.RESULT_CANT_RESOLVE: return "CANT_RESOLVE"
		HTTPRequest.RESULT_CONNECTION_ERROR: return "CONNECTION_ERROR"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR: return "TLS"
		HTTPRequest.RESULT_NO_RESPONSE: return "NO_RESPONSE"
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED: return "BODY_LIMIT"
		HTTPRequest.RESULT_REQUEST_FAILED: return "REQUEST_FAILED"
		HTTPRequest.RESULT_TIMEOUT: return "TIMEOUT"
		_: return str(r)

# ===== SAMPLING ENTRI (FR-C1) =====

func _pick_entries(n: int, exclude: Array) -> Array:
	var pool := DatasetLoader.entries
	var exclude_lower: Array[String] = []
	for s in exclude:
		exclude_lower.append(str(s).to_lower())
	var available: Array = []
	for e in pool:
		if str(e.get("slang", "")).to_lower() not in exclude_lower:
			available.append(e)
	available.shuffle()
	return available.slice(0, min(n, available.size()))

# ===== PROMPT (FR-C2) =====

func _build_system_prompt() -> String:
	return """You are a question generator for SlangFeed, an educational game about English internet slang.
The player reads a social media post that naturally uses ONE slang term, then a confused commenter asks what it means. The player picks 1 of 4 options.

STRICT RULES:
1. Use ONLY the slang terms provided in the input list. Never invent slangs.
2. The post must use the slang naturally and contextually — its meaning must match the provided definition.
3. The post text must NEVER contain or reveal the definition.
4. Exactly 4 answer options. Exactly ONE is correct (correct_index 0-3).
5. Wrong options (distractors) must be: mutually exclusive, plausible but clearly incorrect, similar in length and part-of-speech to the correct answer, never absurd.
6. All content must be SFW: no profanity, no NSFW, no hate speech.
7. explanation: one short sentence stating what the slang means.

OUTPUT FORMAT — respond with ONLY a valid JSON array, no markdown, no code fences, no commentary:
[
  {
    "post_text": "The social media post (1-3 sentences, uses the slang naturally)",
    "comment_text": "A confused question about the slang, e.g. Wait, what does 'X' mean here?",
    "options": ["correct meaning", "distractor 1", "distractor 2", "distractor 3"],
    "correct_index": 0,
    "explanation": "Short explanation of the slang meaning.",
    "slang_tested": "the slang term"
  }
]"""

func _build_user_prompt(entries: Array) -> String:
	var compact: Array = []
	for e in entries:
		compact.append({
			"slang": e.get("slang", ""),
			"definition": e.get("definition", ""),
			"origin_context": e.get("origin_context", ""),
		})
	return """Generate %d questions, one for EACH slang in this list (in any order). Respond with ONLY the JSON array.

SLANGS:
%s

Remember: options[0] position does NOT have to be the correct answer — vary correct_index across questions. Distractors must be plausible, mutually exclusive, similar length/POS to the correct answer.""" % [
		entries.size(),
		JSON.stringify(compact, "  "),
	]

# ===== VALIDASI KONTRAK + EXPAND (FR-C3) =====

func _validate_and_expand(content: String) -> Array:
	var json_text := _extract_json_array(content)
	if json_text == "":
		print("[APIClient] Tidak ada JSON array di respons")
		return []
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null or not (parsed is Array):
		print("[APIClient] JSON array parse gagal")
		return []
	var out: Array = []
	for i in parsed.size():
		var q = parsed[i]
		if q == null or not (q is Dictionary):
			continue
		if not _valid_question(q):
			print("[APIClient] Soal #%d gagal validasi kontrak — dibuang" % (i + 1))
			continue
		out.append(_expand_to_rich_post(q, out.size() + 1))
	return out

func _valid_question(q: Dictionary) -> bool:
	var post_text := str(q.get("post_text", "")).strip_edges()
	var comment_text := str(q.get("comment_text", "")).strip_edges()
	var explanation := str(q.get("explanation", "")).strip_edges()
	var slang := str(q.get("slang_tested", "")).strip_edges()
	var options = q.get("options", null)
	if post_text == "" or comment_text == "" or explanation == "" or slang == "":
		return false
	if options == null or not (options is Array) or options.size() != 4:
		return false
	var seen := {}
	for o in options:
		var t := str(o).strip_edges()
		if t == "":
			return false
		if seen.has(t.to_lower()):
			return false
		seen[t.to_lower()] = true
	var ci = q.get("correct_index", -1)
	if not (ci is int or ci is float):
		return false
	ci = int(ci)
	if ci < 0 or ci > 3:
		return false
	return true

func _extract_json_array(text: String) -> String:
	var start := text.find("[")
	var end := text.rfind("]")
	if start == -1 or end == -1 or end <= start:
		return ""
	return text.substr(start, end - start + 1)

func _expand_to_rich_post(q: Dictionary, post_id: int) -> Dictionary:
	var slang := str(q.get("slang_tested", ""))
	var options: Array = q.get("options", [])
	var correct_index: int = int(q.get("correct_index", 0.0))
	var letters := ["A", "B", "C", "D"]
	var display_options: Array = []
	for i in 4:
		display_options.append("%s. %s" % [letters[i], str(options[i]).strip_edges()])
	var username := _rand_username(slang)
	return {
		"post_id": post_id,
		"author": {
			"username": username,
			"display_name": username.trim_prefix("@").replace("_", " ").capitalize(),
		},
		"content": str(q.get("post_text", "")),
		"likes": randi_range(500, 10000),
		"comments_count": randi_range(5, 50),
		"timestamp": "%dh ago" % randi_range(1, 9),
		"filler_comments": _rand_filler_comments(slang),
		"question_comment": {
			"user": _rand_curious_user(),
			"text": str(q.get("comment_text", "")),
		},
		"slang_tested": slang,
		"options": display_options,
		"correct_answer": letters[correct_index],
		"explanation": str(q.get("explanation", "")),
		"correct_response": {
			"user": _rand_curious_user(),
			"text": "ohh that makes sense! thanks!! 😊",
		},
		"wrong_response": {
			"corrector_user": "@slang_guru",
			"corrector_text": "not quite — '%s' actually means: %s" % [slang, str(q.get("explanation", ""))],
		},
	}

# ===== GENERATOR KOZMETIK LOKAL =====

const USERNAME_POOL := ["@daily_vibes", "@midnight.poster", "@urban.explorer", "@cafe.hopper", "@pixel.dreamer", "@neon.rider", "@soft.launch", "@retro.soul", "@cloud.nine", "@static.noise"]
const CURIOUS_POOL := ["@curious.carl", "@newbie_netizen", "@confused_kay", "@just.asking", "@wondering.wo", "@no.idea.ned"]
const FILLER_TEXTS := ["this is so real 😂", "why is this literally me", "ok but same tho", "no wayyy 😭", "the accuracy 💀", "saving this post fr", "obsessed with this energy ✨", "tell me why this is on my fyp rn"]

func _rand_username(slang_seed: String) -> String:
	var idx: int = abs(int(slang_seed.hash())) % USERNAME_POOL.size()
	return USERNAME_POOL[idx]

func _rand_curious_user() -> String:
	return CURIOUS_POOL[randi() % CURIOUS_POOL.size()]

func _rand_filler_comments(_slang: String) -> Array:
	var pool := FILLER_TEXTS.duplicate()
	pool.shuffle()
	var users := USERNAME_POOL.duplicate()
	users.shuffle()
	var out: Array = []
	for i in 3:
		out.append({"user": users[i], "text": pool[i]})
	return out

# ===== FALLBACK =====

func _use_fallback(reason: String) -> void:
	print("[APIClient] >>> FALLBACK (Tier 3): ", reason)
	var posts: Array = _fallback_data.get("posts", [])
	var used: Array[String] = []
	for s in SessionManager.used_slangs:
		used.append(str(s).to_lower())
	var available: Array = []
	for p in posts:
		if str(p.get("slang_tested", "")).to_lower() not in used:
			available.append(p)
	var selected: Array = available if available.size() <= Config.BATCH_SIZE else available.slice(0, Config.BATCH_SIZE)
	if selected.is_empty():
		selected = posts.slice(0, min(Config.BATCH_SIZE, posts.size()))
	if selected.is_empty():
		batch_failed.emit("Fallback kosong — fallback_posts.json tidak terbaca")
		return
	_metrics.fallback += selected.size()
	SessionManager.fallback_count += selected.size()
	batch_received.emit(selected, true, "Fallback: " + reason)

## Untuk layar debug/analitik (SRS Bagian 7: error rate & perilaku rantai provider)
func get_metrics() -> Dictionary:
	return _metrics.duplicate()
