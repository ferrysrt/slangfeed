extends Control
## Result Screen — session summary with stats and slang list.

func _ready() -> void:
	_build_ui()
	# Entrance animation
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.03, 0.03)
	
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(main_vbox)
	
	# Top spacer
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size.y = 20
	main_vbox.add_child(spacer_top)
	
	# === HEADER ===
	var header := Label.new()
	header.text = "📊 Session Complete!"
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color.WHITE)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(header)
	
	# === STATS CARD ===
	var stats_card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.12, 0.12)
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	card_style.content_margin_left = 20
	card_style.content_margin_right = 20
	card_style.content_margin_top = 16
	card_style.content_margin_bottom = 16
	stats_card.add_theme_stylebox_override("panel", card_style)
	
	var stats_margin := MarginContainer.new()
	stats_margin.add_theme_constant_override("margin_left", 20)
	stats_margin.add_theme_constant_override("margin_right", 20)
	stats_margin.add_child(stats_card)
	main_vbox.add_child(stats_margin)
	
	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_card.add_child(stats_vbox)
	
	var duration := SessionManager.get_session_duration_minutes()
	var total := SessionManager.session_history.size()
	var correct := SessionManager.get_total_correct()
	var wrong := SessionManager.get_total_wrong()
	var gained := SessionManager.get_followers_gained()
	
	_add_stat_row(stats_vbox, "⏱ Time", "%.0f minutes" % duration)
	_add_stat_row(stats_vbox, "📝 Posts", str(total))
	_add_stat_row(stats_vbox, "✅ Correct", str(correct))
	_add_stat_row(stats_vbox, "❌ Wrong", str(wrong))
	_add_stat_row(stats_vbox, "👥 Followers", "%+d (Total: %d)" % [gained, GameData.total_followers])
	
	# Accuracy bar
	if total > 0:
		var accuracy := float(correct) / float(total) * 100.0
		var acc_label := Label.new()
		acc_label.text = "📈 Accuracy: %.0f%%" % accuracy
		acc_label.add_theme_font_size_override("font_size", 16)
		acc_label.add_theme_color_override("font_color", Color(0.29, 0.87, 0.5) if accuracy >= 70 else Color(0.94, 0.67, 0.27) if accuracy >= 50 else Color(0.94, 0.27, 0.27))
		acc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_vbox.add_child(acc_label)
	
	# === SLANGS LEARNED SECTION ===
	var slangs_header := Label.new()
	slangs_header.text = "── Slangs Learned ──"
	slangs_header.add_theme_font_size_override("font_size", 16)
	slangs_header.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
	slangs_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(slangs_header)
	
	var slangs_container := VBoxContainer.new()
	slangs_container.add_theme_constant_override("separation", 4)
	var slangs_margin := MarginContainer.new()
	slangs_margin.add_theme_constant_override("margin_left", 24)
	slangs_margin.add_theme_constant_override("margin_right", 24)
	slangs_margin.add_child(slangs_container)
	main_vbox.add_child(slangs_margin)
	
	for entry in SessionManager.session_history:
		var slang: String = entry.get("slang_tested", "")
		var is_correct: bool = entry.get("is_correct", false)
		var explanation: String = entry.get("explanation", "")
		
		var slang_card := PanelContainer.new()
		var slang_style := StyleBoxFlat.new()
		slang_style.bg_color = Color(0.12, 0.12, 0.12)
		slang_style.corner_radius_top_left = 14
		slang_style.corner_radius_top_right = 14
		slang_style.corner_radius_bottom_left = 14
		slang_style.corner_radius_bottom_right = 14
		slang_style.content_margin_left = 12
		slang_style.content_margin_right = 12
		slang_style.content_margin_top = 10
		slang_style.content_margin_bottom = 10
		slang_style.border_width_left = 3
		slang_style.border_color = Color(0.29, 0.87, 0.5) if is_correct else Color(0.94, 0.27, 0.27)
		slang_card.add_theme_stylebox_override("panel", slang_style)
		slangs_container.add_child(slang_card)
		
		var slang_vbox := VBoxContainer.new()
		slang_vbox.add_theme_constant_override("separation", 2)
		slang_card.add_child(slang_vbox)
		
		var slang_label := Label.new()
		slang_label.text = ("✅ " if is_correct else "❌ ") + slang
		slang_label.add_theme_font_size_override("font_size", 15)
		slang_label.add_theme_color_override("font_color", Color.WHITE)
		slang_vbox.add_child(slang_label)
		
		var meaning_label := Label.new()
		meaning_label.text = explanation
		meaning_label.add_theme_font_size_override("font_size", 12)
		meaning_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
		meaning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slang_vbox.add_child(meaning_label)
	
	# === BUTTONS ===
	var btn_spacer := Control.new()
	btn_spacer.custom_minimum_size.y = 8
	main_vbox.add_child(btn_spacer)
	
	var btn_margin := MarginContainer.new()
	btn_margin.add_theme_constant_override("margin_left", 40)
	btn_margin.add_theme_constant_override("margin_right", 40)
	main_vbox.add_child(btn_margin)
	
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 10)
	btn_margin.add_child(btn_vbox)
	
	# Back to Home
	var home_btn := Button.new()
	home_btn.text = "Back to Home"
	home_btn.custom_minimum_size = Vector2(0, 48)
	var home_style := StyleBoxFlat.new()
	home_style.bg_color = Color(0.0, 0.584, 0.965)
	home_style.corner_radius_top_left = 14
	home_style.corner_radius_top_right = 14
	home_style.corner_radius_bottom_left = 14
	home_style.corner_radius_bottom_right = 14
	home_btn.add_theme_stylebox_override("normal", home_style)
	home_btn.add_theme_color_override("font_color", Color.WHITE)
	home_btn.add_theme_font_size_override("font_size", 16)
	home_btn.pressed.connect(_go_home)
	btn_vbox.add_child(home_btn)
	
	# Keep Scrolling
	var continue_btn := Button.new()
	continue_btn.text = "Keep Scrolling"
	continue_btn.custom_minimum_size = Vector2(0, 48)
	var continue_style := StyleBoxFlat.new()
	continue_style.bg_color = Color(0.15, 0.15, 0.15)
	continue_style.corner_radius_top_left = 14
	continue_style.corner_radius_top_right = 14
	continue_style.corner_radius_bottom_left = 14
	continue_style.corner_radius_bottom_right = 14
	continue_btn.add_theme_stylebox_override("normal", continue_style)
	continue_btn.add_theme_color_override("font_color", Color.WHITE)
	continue_btn.add_theme_font_size_override("font_size", 16)
	continue_btn.pressed.connect(_keep_scrolling)
	btn_vbox.add_child(continue_btn)
	
	# Bottom spacer
	var spacer_bottom := Control.new()
	spacer_bottom.custom_minimum_size.y = 40
	main_vbox.add_child(spacer_bottom)

func _add_stat_row(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 15)
	value.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(value)

func _go_home() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/home_screen.tscn"))

func _keep_scrolling() -> void:
	# Start a new session but keep scrolling
	SessionManager.start_session()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/feed_screen.tscn"))
