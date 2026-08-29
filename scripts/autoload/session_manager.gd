extends Node
## Singleton: Session state management.
## Autoloaded as "SessionManager".

const LOGS_DIR := "user://logs/"

var current_session_id: String = ""
var session_start_time: String = ""
var session_history: Array[Dictionary] = []  # Array of answer entries
var used_slangs: Array[String] = []
var batch_count: int = 0
var fallback_count: int = 0

# ===== SESSION LIFECYCLE =====

func start_session() -> void:
	current_session_id = _sanitize_filename(GameData.player_username) + "_" + str(Time.get_unix_time_from_system())
	session_start_time = Time.get_datetime_string_from_system()
	session_history.clear()
	used_slangs.clear()
	batch_count = 0
	fallback_count = 0

func end_session() -> void:
	save_session_log()
	GameData.save_data()

# ===== ANSWER LOGGING =====

func log_answer(entry: Dictionary) -> void:
	entry["entry_number"] = session_history.size() + 1
	entry["batch_number"] = batch_count
	entry["timestamp"] = Time.get_datetime_string_from_system()
	session_history.append(entry)
	
	# Track used slang
	var slang: String = entry.get("slang_tested", "")
	if slang != "" and slang not in used_slangs:
		used_slangs.append(slang)

# ===== STATISTICS =====

func get_total_correct() -> int:
	var count := 0
	for entry in session_history:
		if entry.get("is_correct", false):
			count += 1
	return count

func get_total_wrong() -> int:
	return session_history.size() - get_total_correct()

func get_followers_gained() -> int:
	return get_total_correct() - get_total_wrong()

func get_recent_performance(n: int = 5) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start: int = max(0, session_history.size() - n)
	for i in range(start, session_history.size()):
		var entry: Dictionary = session_history[i]
		result.append({
			"slang": entry.get("slang_tested", ""),
			"correct": entry.get("is_correct", false)
		})
	return result

func get_session_duration_minutes() -> float:
	if session_start_time == "":
		return 0.0
	var start: int = Time.get_unix_time_from_datetime_string(session_start_time)
	var now: float = Time.get_unix_time_from_system()
	return (now - start) / 60.0

func build_session_context() -> Dictionary:
	return {
		"total_answered": session_history.size(),
		"total_correct": get_total_correct(),
		"recent_performance": get_recent_performance(),
		"slangs_already_used": used_slangs.duplicate(),
		"follower_count": GameData.total_followers
	}

# ===== LOG FILE =====

func save_session_log() -> void:
	DirAccess.make_dir_recursive_absolute(LOGS_DIR)
	
	var slangs_learned: Array[Dictionary] = []
	for entry in session_history:
		slangs_learned.append({
			"slang": entry.get("slang_tested", ""),
			"correct": entry.get("is_correct", false),
			"explanation": entry.get("explanation", "")
		})
	
	var log_data := {
		"metadata": {
			"session_id": current_session_id,
			"player_name": GameData.player_username,
			"start_time": session_start_time,
			"end_time": Time.get_datetime_string_from_system(),
			"duration_minutes": snapped(get_session_duration_minutes(), 0.1),
			"total_posts_seen": session_history.size(),
			"total_answered": session_history.size(),
			"total_correct": get_total_correct(),
			"total_wrong": get_total_wrong(),
			"followers_gained": get_followers_gained(),
			"total_followers_after": GameData.total_followers,
			"batches_loaded": batch_count,
			"fallback_posts_used": fallback_count
		},
		"entries": session_history,
		"slangs_learned": slangs_learned
	}
	
	var filename := LOGS_DIR + current_session_id + ".json"
	var file := FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(log_data, "	"))
		file.close()
		print("[SessionManager] Log saved: ", filename)

## Audit fix #4: sanitasi nama file log dari input username (blokir path separator).
func _sanitize_filename(name: String) -> String:
	var out := ""
	for ch in name:
		if ch in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|", "\n", "\r", "	", " "]:
			out += "_"
		else:
			out += ch
	return out.substr(0, 40)
