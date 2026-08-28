extends Control
## Notification Screen — Activity timeline / log.

var notif_container: VBoxContainer
var empty_label: Label

func _ready() -> void:
	_build_ui()
	GameData.notification_added.connect(_on_notification_added)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)
	
	# === TOP BAR ===
	var top_bar := PanelContainer.new()
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.04, 0.04, 0.04)
	top_style.border_width_bottom = 1
	top_style.border_color = Color(0.15, 0.15, 0.15)
	top_style.content_margin_left = 16
	top_style.content_margin_right = 16
	top_style.content_margin_top = 12
	top_style.content_margin_bottom = 12
	top_bar.add_theme_stylebox_override("panel", top_style)
	main_vbox.add_child(top_bar)
	
	var top_hbox := HBoxContainer.new()
	top_bar.add_child(top_hbox)
	
	var title := Label.new()
	title.text = "🔔 Activity"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(title)
	
	var clear_btn := Button.new()
	clear_btn.text = "Mark all read"
	clear_btn.add_theme_font_size_override("font_size", 12)
	var clear_style := StyleBoxFlat.new()
	clear_style.bg_color = Color(0.15, 0.15, 0.15)
	clear_style.corner_radius_top_left = 8
	clear_style.corner_radius_top_right = 8
	clear_style.corner_radius_bottom_left = 8
	clear_style.corner_radius_bottom_right = 8
	clear_btn.add_theme_stylebox_override("normal", clear_style)
	clear_btn.pressed.connect(func():
		GameData.mark_all_read()
		_refresh_list()
	)
	top_hbox.add_child(clear_btn)
	
	# === SCROLL AREA ===
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)
	
	notif_container = VBoxContainer.new()
	notif_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notif_container.add_theme_constant_override("separation", 2)
	scroll.add_child(notif_container)
	
	# Bottom spacer
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 80
	main_vbox.add_child(spacer)
	
	_refresh_list()
	
	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _refresh_list() -> void:
	for child in notif_container.get_children():
		child.queue_free()
	
	if GameData.notifications.is_empty():
		var empty := Label.new()
		empty.text = "No activities yet!\nStart playing to see your progress here 📋"
		empty.add_theme_font_size_override("font_size", 14)
		empty.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		notif_container.add_child(empty)
		return
	
	for notif in GameData.notifications:
		_add_notif_item(notif)

func _add_notif_item(notif: Dictionary) -> void:
	var item := PanelContainer.new()
	var style := StyleBoxFlat.new()
	var is_read: bool = notif.get("read", false)
	style.bg_color = Color(0.08, 0.08, 0.08) if is_read else Color(0.06, 0.08, 0.12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.border_width_bottom = 1
	style.border_color = Color(0.1, 0.1, 0.1)
	if not is_read:
		style.border_width_left = 3
		style.border_color = Color(0.0, 0.584, 0.965)
	item.add_theme_stylebox_override("panel", style)
	notif_container.add_child(item)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	item.add_child(hbox)
	
	# Icon based on type
	var type_str: String = notif.get("type", "")
	var icon_text := _get_type_icon(type_str)
	
	var icon := Label.new()
	icon.text = icon_text
	icon.add_theme_font_size_override("font_size", 22)
	icon.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon)
	
	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 2)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_col)
	
	var title_label := Label.new()
	title_label.text = notif.get("title", "")
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color.WHITE if not is_read else Color(0.7, 0.7, 0.7))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(title_label)
	
	var body_label := Label.new()
	body_label.text = notif.get("body", "")
	body_label.add_theme_font_size_override("font_size", 12)
	body_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(body_label)
	
	var time_label := Label.new()
	var ts: String = notif.get("timestamp", "")
	time_label.text = _format_timestamp(ts)
	time_label.add_theme_font_size_override("font_size", 11)
	time_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	text_col.add_child(time_label)
	
	if not is_read:
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 10)
		dot.add_theme_color_override("font_color", Color(0.0, 0.584, 0.965))
		hbox.add_child(dot)

func _get_type_icon(type: String) -> String:
	match type:
		"badge": return "🏆"
		"vocab": return "📚"
		"streak": return "🔥"
		"verified": return "✅"
		"chat": return "💬"
		"milestone": return "🎯"
		_: return "📋"

func _format_timestamp(ts: String) -> String:
	if ts == "":
		return ""
	# Just show the date and time portion
	if ts.length() > 16:
		return ts.substr(0, 16).replace("T", " ")
	return ts

func _on_notification_added(_notif: Dictionary) -> void:
	_refresh_list()
