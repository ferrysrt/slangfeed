extends Node
## Dataset Loader — FIX #1 (plan1-revisi v2): fetch runtime CSV dari GitHub raw.
## Prioritas: (a) HTTPRequest online → (b) cache user://slang_cache.csv
## → (c) snapshot res://data/slang_dataset.csv (bundle saat export).
## Timeout keras DATASET_TIMEOUT_SEC di setiap tahap (SRS FR-B4).
## Autoloaded as "DatasetLoader".

signal dataset_loaded(entries: Array, source: String)  # source: "online"|"cache"|"snapshot"|"none"
signal dataset_failed(reason: String)

const CACHE_PATH := "user://slang_cache.csv"
const SNAPSHOT_PATH := "res://data/slang_dataset.csv"

var entries: Array = []            # Array of Dictionary {slang, definition, origin_context}
var source: String = "none"
var synced_at: String = ""
var dataset_hash: String = ""

var _http: HTTPRequest
var _loaded: bool = false

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = Config.DATASET_TIMEOUT_SEC
	_http.use_threads = true
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

## Dipanggil dari splash screen. Timeout total dikontrol per-request oleh HTTPRequest.timeout.
func load_dataset() -> void:
	if _loaded:
		dataset_loaded.emit(entries, source)
		return
	# (a) online
	var err := _http.request(Config.DATASET_URL)
	if err != OK:
		print("[DatasetLoader] Online request gagal di-start (err=%d), coba cache" % err)
		_load_cache_or_snapshot()
	else:
		print("[DatasetLoader] Fetching dataset dari: ", Config.DATASET_URL)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var parsed: Array = []
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var text := body.get_string_from_utf8()
		parsed = _parse_csv(text)
		if parsed.size() > 0:
			# Sukses online: simpan cache + metadata
			var file := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
			if file:
				file.store_string(text)
				file.close()
			entries = parsed
			source = "online"
			synced_at = Time.get_datetime_string_from_system()
			dataset_hash = text.md5_text()
			_loaded = true
			print("[DatasetLoader] ONLINE OK: %d entri" % entries.size())
			dataset_loaded.emit(entries, source)
			return
		else:
			print("[DatasetLoader] Online 200 tapi CSV invalid/kosong → cache")
	else:
		print("[DatasetLoader] Online gagal (result=%d http=%d) → cache" % [result, response_code])
	_load_cache_or_snapshot()

func _load_cache_or_snapshot() -> void:
	# (b) cache user://
	var text := _read_file(CACHE_PATH)
	if text != "":
		var parsed := _parse_csv(text)
		if parsed.size() > 0:
			entries = parsed
			source = "cache"
			synced_at = ""
			dataset_hash = text.md5_text()
			_loaded = true
			print("[DatasetLoader] CACHE OK: %d entri" % entries.size())
			dataset_loaded.emit(entries, source)
			return
	# (c) snapshot res://
	text = _read_file(SNAPSHOT_PATH)
	if text != "":
		var parsed := _parse_csv(text)
		if parsed.size() > 0:
			entries = parsed
			source = "snapshot"
			synced_at = ""
			dataset_hash = text.md5_text()
			_loaded = true
			print("[DatasetLoader] SNAPSHOT OK: %d entri" % entries.size())
			dataset_loaded.emit(entries, source)
			return
	# Gagal total
	entries = []
	source = "none"
	print("[DatasetLoader] FATAL: tidak ada sumber dataset apapun")
	dataset_failed.emit("Tidak ada sumber dataset (online/cache/snapshot semua gagal)")

func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return ""
	var text := file.get_as_text()
	file.close()
	return text

## Parser CSV 3-kolom comma-free (garansi FR-A9: backend men-strip koma/kutip).
## Header wajib: slang,definition,origin_context
func _parse_csv(text: String) -> Array:
	var out: Array = []
	var lines := text.split("\n")
	for i in lines.size():
		var line := lines[i].strip_edges()
		if line == "":
			continue
		var parts := line.split(",")
		if i == 0 and parts.size() >= 3 and parts[0].strip_edges().to_lower() == "slang":
			continue  # header
		if parts.size() < 3:
			continue  # baris rusak → skip (FR-B5 toleransi)
		var slang := parts[0].strip_edges()
		var definition := parts[1].strip_edges()
		var origin := parts[2].strip_edges() if parts.size() > 2 else ""
		if slang == "" or definition == "":
			continue
		out.append({"slang": slang, "definition": definition, "origin_context": origin})
	return out
