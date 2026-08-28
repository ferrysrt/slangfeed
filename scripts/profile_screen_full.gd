extends Control
## Profile Screen — shows player stats, badges, and edit profile.

var username_label: Label
var display_name_label: Label
var points_label: Label
var followers_label: Label
var slangs_label: Label
var accuracy_label: Label
var verified_icon: Label
var badges_container: VBoxContainer
var edit_overlay: Panel

func _ready() -> void:
	_build_ui()
	GameData.badge_earned.connect(_on_badge_earned)
	GameData.points_changed.connect(_on_points_changed)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 0)
	scroll.add_child(main_vbox)
	
	# === PROFILE HEADER ===
	var header := PanelContainer.new()
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.06, 0.06, 0.06)
	header_style.content_margin_left = 20
	header_style.content_margin_right = 20
	header_style.content_margin_top = 24
	header_style.content_margin_bottom = 24
	header.add_theme_stylebox_override("panel", header_style)
	main_vbox.add_child(header)
	
	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 8)
	header.add_child(header_vbox)
	
	# Avatar + username row
	var avatar_row := HBoxContainer.new()
	avatar_row.add_theme_constant_override("separation", 12)
	header_vbox.add_child(avatar_row)
	
	# Avatar circle
	var avatar_panel := PanelContainer.new()
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color(0.15, 0.15, 0.15)
	avatar_style.corner_radius_top_left = 35
	avatar_style.corner_radius_top_right = 35
	avatar_style.corner_radius_bottom_left = 35
	avatar_style.corner_radius_bottom_right = 35
	avatar_style.content_margin_left = 8
	avatar_style.content_margin_right = 8
	avatar_style.content_margin_top = 4
	avatar_style.content_margin_bottom = 4
	avatar_panel.add_theme_stylebox_override("panel", avatar_style)
	avatar_panel.custom_minimum_size = Vector2(70, 70)
	avatar_row.add_child(avatar_panel)
	
	var avatar_emoji := Label.new()
	avatar_emoji.text = "👤"
	avatar_emoji.add_theme_font_size_override("font_size", 36)
	avatar_emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_emoji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_panel.add_child(avatar_emoji)
	
	var name_column := VBoxContainer.new()
	name_column.add_theme_constant_override("separation", 2)
	name_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avatar_row.add_child(name_column)
	
	# Username + verified
	var username_row := HBoxContainer.new()
	username_row.add_theme_constant_override("separation", 6)
	name_column.add_child(username_row)
	
	username_label = Label.new()
	username_label.text = "@" + GameData.player_username
	username_label.add_theme_font_size_override("font_size", 18)
	username_label.add_theme_color_override("font_color", Color.WHITE)
	username_row.add_child(username_label)
	
	verified_icon = Label.new()
	verified_icon.text = "✅" if GameData.is_verified else ""
	verified_icon.add_theme_font_size_override("font_size", 16)
	username_row.add_child(verified_icon)
	
	display_name_label = Label.new()
	var dn: String = GameData.display_name if GameData.display_name != "" else GameData.player_username
	display_name_label.text = dn
	display_name_label.add_theme_font_size_override("font_size", 14)
	display_name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	name_column.add_child(display_name_label)
	
	# Edit profile button
	var edit_btn := Button.new()
	edit_btn.text = "Edit Profile"
	edit_btn.add_theme_font_size_override("font_size", 13)
	var edit_style := StyleBoxFlat.new()
	edit_style.bg_color = Color(0.15, 0.15, 0.15)
	edit_style.corner_radius_top_left = 8
	edit_style.corner_radius_top_right = 8
	edit_style.corner_radius_bottom_left = 8
	edit_style.corner_radius_bottom_right = 8
	edit_style.border_width_bottom = 1
	edit_style.border_width_top = 1
	edit_style.border_width_left = 1
	edit_style.border_width_right = 1
	edit_style.border_color = Color(0.3, 0.3, 0.3)
	edit_btn.add_theme_stylebox_override("normal", edit_style)
	edit_btn.custom_minimum_size.y = 34
	edit_btn.pressed.connect(_on_edit_pressed)
	header_vbox.add_child(edit_btn)
	
	# === STATS ROW ===
	var stats_panel := PanelContainer.new()
	var stats_style := StyleBoxFlat.new()
	stats_style.bg_color = Color(0.04, 0.04, 0.04)
	stats_style.border_width_top = 1
	stats_style.border_width_bottom = 1
	stats_style.border_color = Color(0.12, 0.12, 0.12)
	stats_style.content_margin_left = 16
	stats_style.content_margin_right = 16
	stats_style.content_margin_top = 16
	stats_style.content_margin_bottom = 16
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	main_vbox.add_child(stats_panel)
	
	var stats_hbox := HBoxContainer.new()
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_hbox.add_theme_constant_override("separation", 0)
	stats_panel.add_child(stats_hbox)
	
	# Points stat
	points_label = _create_stat_column("⭐ Points", str(GameData.points), stats_hbox)
	# Followers stat
	followers_label = _create_stat_column("👥 Followers", str(GameData.total_followers), stats_hbox)
	# Slangs stat
	slangs_label = _create_stat_column("📚 Slangs", str(GameData.learned_slangs.size()), stats_hbox)
	
	# === BADGES SECTION ===
	var badges_header := PanelContainer.new()
	var bh_style := StyleBoxFlat.new()
	bh_style.bg_color = Color(0.04, 0.04, 0.04)
	bh_style.content_margin_left = 16
	bh_style.content_margin_right = 16
	bh_style.content_margin_top = 16
	bh_style.content_margin_bottom = 8
	badges_header.add_theme_stylebox_override("panel", bh_style)
	main_vbox.add_child(badges_header)
	
	var bh_label := Label.new()
	bh_label.text = "🏆 Badges & Achievements"
	bh_label.add_theme_font_size_override("font_size", 16)
	bh_label.add_theme_color_override("font_color", Color.WHITE)
	badges_header.add_child(bh_label)
	
	badges_container = VBoxContainer.new()
	badges_container.add_theme_constant_override("separation", 4)
	
	var badges_margin := MarginContainer.new()
	badges_margin.add_theme_constant_override("margin_left", 16)
	badges_margin.add_theme_constant_override("margin_right", 16)
	badges_margin.add_theme_constant_override("margin_bottom", 16)
	badges_margin.add_child(badges_container)
	main_vbox.add_child(badges_margin)
	
	_populate_badges()
	
	# Bottom spacer
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 80
	main_vbox.add_child(spacer)
	
	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _create_stat_column(title: String, value: String, parent: HBoxContainer) -> Label:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)
	
	var val_label := Label.new()
	val_label.text = value
	val_label.add_theme_font_size_override("font_size", 20)
	val_label.add_theme_color_override("font_color", Color.WHITE)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(val_label)
	
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title_label)
	
	return val_label

func _populate_badges() -> void:
	for child in badges_container.get_children():
		child.queue_free()
	
	for badge_id in GameData.BADGE_DEFS:
		var info: Dictionary = GameData.BADGE_DEFS[badge_id]
		var earned: bool = badge_id in GameData.badges
		
		var item := PanelContainer.new()
		var item_style := StyleBoxFlat.new()
		item_style.bg_color = Color(0.1, 0.1, 0.1) if earned else Color(0.06, 0.06, 0.06)
		item_style.corner_radius_top_left = 10
		item_style.corner_radius_top_right = 10
		item_style.corner_radius_bottom_left = 10
		item_style.corner_radius_bottom_right = 10
		item_style.content_margin_left = 14
		item_style.content_margin_right = 14
		item_style.content_margin_top = 12
		item_style.content_margin_bottom = 12
		if earned:
			item_style.border_width_left = 3
			item_style.border_color = Color(0.29, 0.87, 0.5)
		item.add_theme_stylebox_override("panel", item_style)
		badges_container.add_child(item)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		item.add_child(hbox)
		
		var icon_label := Label.new()
		icon_label.text = info.get("icon", "🏆")
		icon_label.add_theme_font_size_override("font_size", 24)
		if not earned:
			icon_label.modulate.a = 0.3
		hbox.add_child(icon_label)
		
		var text_col := VBoxContainer.new()
		text_col.add_theme_constant_override("separation", 2)
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text_col)
		
		var name_lbl := Label.new()
		name_lbl.text = info.get("name", badge_id)
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color.WHITE if earned else Color(0.4, 0.4, 0.4))
		text_col.add_child(name_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = info.get("desc", "")
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5) if earned else Color(0.3, 0.3, 0.3))
		text_col.add_child(desc_lbl)
		
		if earned:
			var check := Label.new()
			check.text = "✓"
			check.add_theme_font_size_override("font_size", 18)
			check.add_theme_color_override("font_color", Color(0.29, 0.87, 0.5))
			hbox.add_child(check)
		else:
			var lock := Label.new()
			lock.text = "🔒"
			lock.add_theme_font_size_override("font_size", 16)
			lock.modulate.a = 0.4
			hbox.add_child(lock)

# ===== EDIT PROFILE =====

func _on_edit_pressed() -> void:
	_build_edit_overlay()

func _build_edit_overlay() -> void:
	edit_overlay = Panel.new()
	edit_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0, 0, 0, 0.85)
	edit_overlay.add_theme_stylebox_override("panel", overlay_style)
	edit_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(edit_overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	edit_overlay.add_child(center)
	
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.1, 0.1)
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	card_style.content_margin_left = 24
	card_style.content_margin_right = 24
	card_style.content_margin_top = 24
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(350, 0)
	center.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)
	
	var title := Label.new()
	title.text = "✏️ Edit Profile"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Display name input
	var dn_label := Label.new()
	dn_label.text = "Display Name"
	dn_label.add_theme_font_size_override("font_size", 13)
	dn_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(dn_label)
	
	var dn_input := LineEdit.new()
	dn_input.name = "DisplayNameInput"
	dn_input.text = GameData.display_name if GameData.display_name != "" else GameData.player_username
	dn_input.add_theme_font_size_override("font_size", 14)
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0.15, 0.15, 0.15)
	input_style.corner_radius_top_left = 10
	input_style.corner_radius_top_right = 10
	input_style.corner_radius_bottom_left = 10
	input_style.corner_radius_bottom_right = 10
	input_style.content_margin_left = 12
	input_style.content_margin_right = 12
	dn_input.add_theme_stylebox_override("normal", input_style)
	dn_input.custom_minimum_size.y = 40
	vbox.add_child(dn_input)
	
	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)
	
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 14)
	var cancel_style := StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.2, 0.2, 0.2)
	cancel_style.corner_radius_top_left = 10
	cancel_style.corner_radius_top_right = 10
	cancel_style.corner_radius_bottom_left = 10
	cancel_style.corner_radius_bottom_right = 10
	cancel_btn.add_theme_stylebox_override("normal", cancel_style)
	cancel_btn.custom_minimum_size.y = 40
	cancel_btn.pressed.connect(func(): edit_overlay.queue_free())
	btn_row.add_child(cancel_btn)
	
	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_font_size_override("font_size", 14)
	var save_style := StyleBoxFlat.new()
	save_style.bg_color = Color(0.0, 0.584, 0.965)
	save_style.corner_radius_top_left = 10
	save_style.corner_radius_top_right = 10
	save_style.corner_radius_bottom_left = 10
	save_style.corner_radius_bottom_right = 10
	save_btn.add_theme_stylebox_override("normal", save_style)
	save_btn.custom_minimum_size.y = 40
	save_btn.pressed.connect(func():
		var new_name: String = dn_input.text.strip_edges()
		if new_name.length() >= 2:
			GameData.display_name = new_name
			GameData.save_data()
			display_name_label.text = new_name
		edit_overlay.queue_free()
	)
	btn_row.add_child(save_btn)
	
	# Animate
	edit_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(edit_overlay, "modulate:a", 1.0, 0.2)

# ===== SIGNAL HANDLERS =====

func _on_badge_earned(_badge_name: String) -> void:
	_populate_badges()

func _on_points_changed(_new_points: int) -> void:
	points_label.text = str(GameData.points)
	followers_label.text = str(GameData.total_followers)
	slangs_label.text = str(GameData.learned_slangs.size())
	verified_icon.text = "✅" if GameData.is_verified else ""
