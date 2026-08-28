extends Control
## Splash Screen — load dataset (FIX #1) dengan timeout keras, lalu ke home.
## SRS FR-E1: splash ≤ 5 detik kondisi apapun; badge "Offline" bila cache/snapshot.

const SPLASH_MAX_SEC := 6.0  # budget total (dataset timeout 5s + margin render)

var status_label: Label
var offline_badge: Label

func _ready() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	_build_status_ui()
	_start_dataset_load()

func _build_status_ui() -> void:
	var vbox := get_node_or_null("CenterContainer/VBoxContainer")
	if not vbox:
		return
	status_label = Label.new()
	status_label.text = "Memuat Kamus Slang..."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
	vbox.add_child(status_label)

	offline_badge = Label.new()
	offline_badge.text = "⚠ Offline Mode — pakai data cache"
	offline_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offline_badge.add_theme_font_size_override("font_size", 12)
	offline_badge.add_theme_color_override("font_color", Color(0.95, 0.7, 0.2))
	offline_badge.visible = false
	vbox.add_child(offline_badge)

func _start_dataset_load() -> void:
	DatasetLoader.load_dataset()
	_wait_for_dataset()

func _wait_for_dataset() -> void:
	var elapsed := 0.0
	while not DatasetLoader._loaded and elapsed < SPLASH_MAX_SEC:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1

	var ok := DatasetLoader._loaded and DatasetLoader.entries.size() > 0
	if ok:
		if status_label:
			status_label.text = "%d slang siap (%s)" % [DatasetLoader.entries.size(), DatasetLoader.source]
		if DatasetLoader.source == "online":
			GameData.set_dataset_meta(DatasetLoader.synced_at, DatasetLoader.dataset_hash)
	else:
		if status_label:
			status_label.text = "Tidak ada data — mode fallback"

	# Badge offline bila bukan online (SRS FR-B2)
	if offline_badge:
		offline_badge.visible = ok and DatasetLoader.source != "online"

	# Simpan status untuk layar lain (opsional)
	Engine.set_meta("dataset_source", DatasetLoader.source)

	await get_tree().create_timer(0.8).timeout
	_fade_out_home()

func _fade_out_home() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/home_screen.tscn"))
