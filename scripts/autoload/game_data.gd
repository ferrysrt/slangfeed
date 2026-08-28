extends Node
## Singleton: Persistent game data across sessions. Autoloaded as "GameData".
## Kontrak persistensi: user://save_data.json (plan1-revisi v2 Bagian 4D):
## vocab_mastered (learned_slangs), stats (points/answered/correct),
## dataset_synced_at, dataset_hash + profil pemain.

signal badge_earned(badge_name: String)
signal points_changed(new_points: int)
signal notification_added(notification: Dictionary)

const SAVE_PATH := "user://save_data.json"

var player_username: String = ""
var display_name: String = ""
var total_followers: int = 0
var points: int = 0
var is_verified: bool = false
var learned_slangs: Array[Dictionary] = []  # vocab_mastered [{slang, meaning, origin_context, learned_at}]
var badges: Array[String] = []
var notifications: Array[Dictionary] = []

# Statistik kumulatif lintas sesi (SRS Bagian 7 — analitik penelitian)
var total_answered: int = 0
var total_correct: int = 0

# Metadata dataset (SRS FR-B6 — bukti klaim konten dinamis)
var dataset_synced_at: String = ""
var dataset_hash: String = ""

# Badge definitions
const BADGE_DEFS: Dictionary = {
	"slang_newbie": {"name": "Slang Newbie", "icon": "🎖️", "desc": "Answer 10 questions correctly", "threshold": 10},
	"slang_apprentice": {"name": "Slang Apprentice", "icon": "🥈", "desc": "Answer 25 questions correctly", "threshold": 25},
	"slang_expert": {"name": "Slang Expert", "icon": "🥇", "desc": "Answer 50 questions correctly", "threshold": 50},
	"slang_master": {"name": "Slang Master", "icon": "👑", "desc": "Answer 100 questions correctly", "threshold": 100},
	"no_cap_master": {"name": "No Cap Master", "icon": "🔥", "desc": "Reach 80%+ accuracy (min 20 answers)", "threshold": 0},
	"verified": {"name": "Verified Account", "icon": "✅", "desc": "Reach 500 points", "threshold": 500},
}

const POINTS_CORRECT := 10
const POINTS_WRONG := -5

func _ready() -> void:
	load_data()

# ===== PERSISTENCE =====

func save_data() -> void:
	var data := {
		"player_username": player_username,
		"display_name": display_name,
		"total_followers": total_followers,
		"points": points,
		"is_verified": is_verified,
		"vocab_mastered": learned_slangs,
		"badges": badges,
		"notifications": notifications,
		"stats": {
			"score": points,
			"answered": total_answered,
			"correct": total_correct,
		},
		"dataset_synced_at": dataset_synced_at,
		"dataset_hash": dataset_hash,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = json.data
	player_username = data.get("player_username", "")
	display_name = data.get("display_name", "")
	total_followers = data.get("total_followers", 0)
	points = data.get("points", 0)
	is_verified = data.get("is_verified", false)
	dataset_synced_at = str(data.get("dataset_synced_at", ""))
	dataset_hash = str(data.get("dataset_hash", ""))

	var stats: Dictionary = data.get("stats", {})
	total_answered = int(stats.get("answered", 0))
	total_correct = int(stats.get("correct", 0))

	var raw_slangs = data.get("vocab_mastered", data.get("learned_slangs", []))
	learned_slangs.clear()
	for s in raw_slangs:
		learned_slangs.append(s)

	var raw_badges = data.get("badges", [])
	badges.clear()
	for b in raw_badges:
		badges.append(b)

	var raw_notifs = data.get("notifications", [])
	notifications.clear()
	for n in raw_notifs:
		notifications.append(n)

# ===== DATASET METADATA =====

func set_dataset_meta(synced_at: String, hash: String) -> void:
	dataset_synced_at = synced_at
	dataset_hash = hash
	save_data()

func get_accuracy() -> float:
	if total_answered == 0:
		return 0.0
	return float(total_correct) / float(total_answered)

# ===== POINTS & FOLLOWERS =====

func add_points_correct() -> void:
	points += POINTS_CORRECT
	total_followers += 1
	total_answered += 1
	total_correct += 1
	points_changed.emit(points)
	check_badges()

func add_points_wrong() -> void:
	points = max(0, points + POINTS_WRONG)
	total_answered += 1
	points_changed.emit(points)

# ===== LEARNED SLANGS =====

func add_learned_slang(slang: String, meaning: String, origin_context: String = "") -> void:
	for s in learned_slangs:
		if s.get("slang", "").to_lower() == slang.to_lower():
			return
	learned_slangs.append({
		"slang": slang,
		"meaning": meaning,
		"origin_context": origin_context,
		"learned_at": Time.get_datetime_string_from_system()
	})
	add_notification("vocab", "📚 New Slang Learned!", "You learned what '%s' means" % slang)

# ===== BADGES =====

func check_badges() -> void:
	var total_correct_count := _count_correct_in_history()

	for badge_id in ["slang_newbie", "slang_apprentice", "slang_expert", "slang_master"]:
		var threshold: int = BADGE_DEFS[badge_id]["threshold"]
		if total_correct_count >= threshold and badge_id not in badges:
			_award_badge(badge_id)

	var total_answered_count: int = int(max(total_answered, learned_slangs.size()))
	if total_answered_count >= 20 and total_correct_count > 0:
		var accuracy := float(total_correct_count) / float(total_answered_count)
		if accuracy >= 0.8 and "no_cap_master" not in badges:
			_award_badge("no_cap_master")

	if points >= 500 and not is_verified:
		is_verified = true
		if "verified" not in badges:
			_award_badge("verified")
			add_notification("verified", "✅ Account Verified!", "Your account is now Official! You've reached 500 points.")

func _award_badge(badge_id: String) -> void:
	if badge_id in badges:
		return
	badges.append(badge_id)
	var badge_info: Dictionary = BADGE_DEFS.get(badge_id, {})
	var badge_name: String = badge_info.get("name", badge_id)
	var badge_icon: String = badge_info.get("icon", "🏆")
	badge_earned.emit(badge_name)
	add_notification("badge", "%s Badge Earned!" % badge_icon, "You earned the '%s' badge!" % badge_name)
	print("[GameData] Badge earned: ", badge_name)

func _count_correct_in_history() -> int:
	return max(total_correct, learned_slangs.size())

# ===== NOTIFICATIONS =====

func add_notification(type: String, title: String, body: String) -> void:
	var notif := {
		"type": type,
		"title": title,
		"body": body,
		"timestamp": Time.get_datetime_string_from_system(),
		"read": false,
	}
	notifications.insert(0, notif)
	if notifications.size() > 50:
		notifications.resize(50)
	notification_added.emit(notif)

func get_unread_count() -> int:
	var count := 0
	for n in notifications:
		if not n.get("read", false):
			count += 1
	return count

func mark_all_read() -> void:
	for n in notifications:
		n["read"] = true
