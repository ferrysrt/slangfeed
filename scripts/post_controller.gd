extends PanelContainer
## Post Controller — manages a single post card's state and display.

signal reply_pressed(post_index: int)

enum PostState { UNANSWERED, ANSWERED_CORRECT, ANSWERED_WRONG }

var post_data: Dictionary = {}
var post_index: int = -1
var state: PostState = PostState.UNANSWERED

# Node references (set during setup)
var avatar_circle: Panel
var username_label: Label
var display_name_label: Label
var timestamp_label: Label
var content_label: RichTextLabel
var likes_label: Label
var comments_count_label: Label
var comments_container: VBoxContainer
var question_section: VBoxContainer
var question_label: RichTextLabel
var reply_button: Button
var feedback_section: VBoxContainer
var status_indicator: Panel
var like_btn_node: TextureButton
var answer_time_start: int = 0

func setup(data: Dictionary, index: int) -> void:
	post_data = data
	post_index = index
	_build_ui()

func _build_ui() -> void:
	# Main card styling
	add_theme_stylebox_override("panel", _create_card_style())
	custom_minimum_size = Vector2(440, 0)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	# === HEADER ===
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)
	
	# Avatar ring (Story outline)
	var avatar_ring := PanelContainer.new()
	var ring_style := StyleBoxFlat.new()
	ring_style.bg_color = Color(0, 0, 0, 0)
	ring_style.border_width_left = 2
	ring_style.border_width_top = 2
	ring_style.border_width_right = 2
	ring_style.border_width_bottom = 2
	ring_style.border_color = Color(0.84, 0.19, 0.65) # Insta pink
	ring_style.corner_radius_top_left = 22
	ring_style.corner_radius_top_right = 22
	ring_style.corner_radius_bottom_left = 22
	ring_style.corner_radius_bottom_right = 22
	avatar_ring.add_theme_stylebox_override("panel", ring_style)
	
	var ring_margin := MarginContainer.new()
	ring_margin.add_theme_constant_override("margin_left", 3)
	ring_margin.add_theme_constant_override("margin_right", 3)
	ring_margin.add_theme_constant_override("margin_top", 3)
	ring_margin.add_theme_constant_override("margin_bottom", 3)
	avatar_ring.add_child(ring_margin)
	
	# Avatar circle
	avatar_circle = Panel.new()
	avatar_circle.custom_minimum_size = Vector2(34, 34)
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = _get_avatar_color()
	avatar_style.corner_radius_top_left = 17
	avatar_style.corner_radius_top_right = 17
	avatar_style.corner_radius_bottom_left = 17
	avatar_style.corner_radius_bottom_right = 17
	avatar_circle.add_theme_stylebox_override("panel", avatar_style)
	ring_margin.add_child(avatar_circle)
	header.add_child(avatar_ring)
	
	# Avatar initial label
	var initial_label := Label.new()
	initial_label.text = _get_initial()
	initial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial_label.add_theme_font_size_override("font_size", 14)
	initial_label.add_theme_color_override("font_color", Color.WHITE)
	initial_label.anchors_preset = Control.PRESET_FULL_RECT
	avatar_circle.add_child(initial_label)
	
	# Username + displayname column
	var name_vbox := VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 2)
	name_vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	header.add_child(name_vbox)
	
	var author: Dictionary = post_data.get("author", {})
	var username_hbox := HBoxContainer.new()
	username_hbox.add_theme_constant_override("separation", 4)
	name_vbox.add_child(username_hbox)

	username_label = Label.new()
	username_label.text = author.get("username", "@unknown")
	username_label.add_theme_font_size_override("font_size", 14)
	username_label.add_theme_color_override("font_color", Color.WHITE)
	username_hbox.add_child(username_label)
	
	if author.get("verified", true): # Default mock to true
		var official_icon := TextureRect.new()
		official_icon.texture = preload("res://assets/art/Dark_Theme/Official_Icon_dark.png")
		official_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		official_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		official_icon.custom_minimum_size = Vector2(14, 14)
		official_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		username_hbox.add_child(official_icon)
		
	var dot_label := Label.new()
	dot_label.text = "•"
	dot_label.add_theme_font_size_override("font_size", 12)
	dot_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
	username_hbox.add_child(dot_label)

	timestamp_label = Label.new()
	timestamp_label.text = post_data.get("timestamp", "1h ago")
	timestamp_label.add_theme_font_size_override("font_size", 12)
	timestamp_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
	username_hbox.add_child(timestamp_label)
	
	display_name_label = Label.new()
	display_name_label.text = author.get("display_name", "Unknown")
	display_name_label.add_theme_font_size_override("font_size", 12)
	display_name_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
	name_vbox.add_child(display_name_label)
	
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	
	var more_btn := TextureButton.new()
	more_btn.texture_normal = preload("res://assets/art/Dark_Theme/More_Icon_dark.png")
	more_btn.ignore_texture_size = true
	more_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	more_btn.custom_minimum_size = Vector2(20, 20)
	more_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(more_btn)
	
	# === CONTENT ===
	content_label = RichTextLabel.new()
	content_label.bbcode_enabled = true
	content_label.text = post_data.get("content", "")
	content_label.fit_content = true
	content_label.scroll_active = false
	content_label.add_theme_font_size_override("normal_font_size", 15)
	content_label.add_theme_color_override("default_color", Color.WHITE)
	vbox.add_child(content_label)
	
	# === ENGAGEMENT BAR ===
	var engagement := HBoxContainer.new()
	engagement.add_theme_constant_override("separation", 20)
	vbox.add_child(engagement)
	
	var likes_hbox := HBoxContainer.new()
	likes_hbox.add_theme_constant_override("separation", 6)
	engagement.add_child(likes_hbox)
	
	like_btn_node = TextureButton.new()
	like_btn_node.texture_normal = preload("res://assets/art/Dark_Theme/like(inactive)_icon_dark.png")
	like_btn_node.ignore_texture_size = true
	like_btn_node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	like_btn_node.custom_minimum_size = Vector2(24, 24)
	like_btn_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	likes_hbox.add_child(like_btn_node)
	
	likes_label = Label.new()
	var likes_num: int = post_data.get("likes", 0)
	likes_label.text = _format_number(likes_num)
	likes_label.add_theme_font_size_override("font_size", 14)
	likes_label.add_theme_color_override("font_color", Color.WHITE)
	likes_hbox.add_child(likes_label)
	
	var comment_hbox := HBoxContainer.new()
	comment_hbox.add_theme_constant_override("separation", 6)
	engagement.add_child(comment_hbox)
	
	var comment_icon := TextureButton.new()
	comment_icon.texture_normal = preload("res://assets/art/Dark_Theme/Comment_icon_dark.png")
	comment_icon.ignore_texture_size = true
	comment_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	comment_icon.custom_minimum_size = Vector2(22, 22)
	comment_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	comment_hbox.add_child(comment_icon)
	
	comments_count_label = Label.new()
	var comments_num: int = post_data.get("comments_count", 0)
	comments_count_label.text = str(comments_num)
	comments_count_label.add_theme_font_size_override("font_size", 14)
	comments_count_label.add_theme_color_override("font_color", Color.WHITE)
	comment_hbox.add_child(comments_count_label)
	
	var send_icon := TextureButton.new()
	send_icon.texture_normal = preload("res://assets/art/Dark_Theme/Messanger_icon_dark.png")
	send_icon.ignore_texture_size = true
	send_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	send_icon.custom_minimum_size = Vector2(24, 24)
	send_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	engagement.add_child(send_icon)
	
	var eng_spacer := Control.new()
	eng_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	engagement.add_child(eng_spacer)
	
	var save_icon := TextureButton.new()
	save_icon.texture_normal = preload("res://assets/art/Dark_Theme/Save(inactive)_icon_dark.png")
	save_icon.ignore_texture_size = true
	save_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	save_icon.custom_minimum_size = Vector2(22, 22)
	save_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	engagement.add_child(save_icon)
	
	# === SEPARATOR ===
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", _create_separator_style())
	vbox.add_child(sep)
	
	# === COMMENTS ===
	comments_container = VBoxContainer.new()
	comments_container.add_theme_constant_override("separation", 6)
	vbox.add_child(comments_container)
	
	var filler: Array = post_data.get("filler_comments", [])
	for c in filler:
		_add_comment(c.get("user", "@user"), c.get("text", ""), comments_container)
	
	# === QUESTION COMMENT ===
	question_section = VBoxContainer.new()
	question_section.add_theme_constant_override("separation", 6)
	vbox.add_child(question_section)
	
	var sep2 := HSeparator.new()
	sep2.add_theme_stylebox_override("separator", _create_separator_style())
	question_section.add_child(sep2)
	
	var qc: Dictionary = post_data.get("question_comment", {})
	question_label = RichTextLabel.new()
	question_label.bbcode_enabled = true
	question_label.text = "[color=#0095f6]🤔 " + qc.get("user", "@curious") + ":[/color] " + qc.get("text", "")
	question_label.fit_content = true
	question_label.scroll_active = false
	question_label.add_theme_font_size_override("normal_font_size", 14)
	question_section.add_child(question_label)
	
	# Reply button (Instagram style add comment)
	reply_button = Button.new()
	if GameData.player_username:
		reply_button.text = "Add a comment as " + GameData.player_username + "..."
	else:
		reply_button.text = "Add a comment..."
	reply_button.custom_minimum_size = Vector2(0, 36)
	reply_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)  # Transparent
	btn_style.content_margin_left = 0
	btn_style.content_margin_right = 0
	reply_button.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	reply_button.add_theme_stylebox_override("hover", btn_hover)
	reply_button.add_theme_stylebox_override("focus", btn_style)
	reply_button.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
	reply_button.add_theme_font_size_override("font_size", 13)
	reply_button.pressed.connect(_on_reply_pressed)
	question_section.add_child(reply_button)
	
	# === FEEDBACK SECTION (hidden initially) ===
	feedback_section = VBoxContainer.new()
	feedback_section.visible = false
	feedback_section.add_theme_constant_override("separation", 6)
	vbox.add_child(feedback_section)
	
	# === STATUS INDICATOR (left border) ===
	status_indicator = Panel.new()
	status_indicator.custom_minimum_size = Vector2(4, 0)
	status_indicator.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status_indicator.visible = false

func _on_reply_pressed() -> void:
	if state != PostState.UNANSWERED:
		return
	answer_time_start = Time.get_ticks_msec()
	reply_pressed.emit(post_index)

func show_correct_feedback(player_username: String) -> void:
	state = PostState.ANSWERED_CORRECT
	reply_button.text = "✅ Answered"
	if like_btn_node:
		like_btn_node.texture_normal = preload("res://assets/art/Dark_Theme/Like(active)_icon_dark.png")
	reply_button.disabled = true
	var correct_style := StyleBoxFlat.new()
	correct_style.bg_color = Color(0.29, 0.87, 0.5, 0.3)
	correct_style.corner_radius_top_left = 8
	correct_style.corner_radius_top_right = 8
	correct_style.corner_radius_bottom_left = 8
	correct_style.corner_radius_bottom_right = 8
	reply_button.add_theme_stylebox_override("normal", correct_style)
	reply_button.add_theme_stylebox_override("disabled", correct_style)
	
	feedback_section.visible = true
	
	# Player's answer
	var player_comment := RichTextLabel.new()
	player_comment.bbcode_enabled = true
	player_comment.text = "[color=#4ade80]↪ @" + _esc(player_username) + ": answered correctly ✅[/color]"
	player_comment.fit_content = true
	player_comment.scroll_active = false
	player_comment.add_theme_font_size_override("normal_font_size", 13)
	feedback_section.add_child(player_comment)
	
	# Grateful response
	var cr: Dictionary = post_data.get("correct_response", {})
	_add_comment(cr.get("user", "@user"), cr.get("text", "thanks!"), feedback_section, Color(0.56, 0.56, 0.56))
	
	# Animate
	feedback_section.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(feedback_section, "modulate:a", 1.0, 0.3)
	
	# Update card border
	_set_border_color(Color(0.29, 0.87, 0.5, 0.5))

func show_wrong_feedback(player_username: String) -> void:
	state = PostState.ANSWERED_WRONG
	reply_button.text = "❌ Incorrect"
	reply_button.disabled = true
	var wrong_style := StyleBoxFlat.new()
	wrong_style.bg_color = Color(0.94, 0.27, 0.27, 0.3)
	wrong_style.corner_radius_top_left = 8
	wrong_style.corner_radius_top_right = 8
	wrong_style.corner_radius_bottom_left = 8
	wrong_style.corner_radius_bottom_right = 8
	reply_button.add_theme_stylebox_override("normal", wrong_style)
	reply_button.add_theme_stylebox_override("disabled", wrong_style)
	
	feedback_section.visible = true
	
	# Player's wrong answer
	var player_comment := RichTextLabel.new()
	player_comment.bbcode_enabled = true
	player_comment.text = "[color=#ef4444]↪ @" + _esc(player_username) + ": answered incorrectly ❌[/color]"
	player_comment.fit_content = true
	player_comment.scroll_active = false
	player_comment.add_theme_font_size_override("normal_font_size", 13)
	feedback_section.add_child(player_comment)
	
	# Corrector
	var wr: Dictionary = post_data.get("wrong_response", {})
	_add_comment(
		wr.get("corrector_user", "@expert"),
		wr.get("corrector_text", "actually..."),
		feedback_section,
		Color(0.94, 0.67, 0.27)
	)
	
	# Original user thanks
	var qc: Dictionary = post_data.get("question_comment", {})
	_add_comment(qc.get("user", "@user"), "ohh okay, thanks for clarifying! 👍", feedback_section)
	
	# Animate
	feedback_section.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(feedback_section, "modulate:a", 1.0, 0.3)
	
	# Update card border
	_set_border_color(Color(0.94, 0.27, 0.27, 0.5))

func get_response_time_ms() -> int:
	if answer_time_start == 0:
		return 0
	return Time.get_ticks_msec() - answer_time_start

# ===== HELPER METHODS =====

## Audit fix #5: escape karakter BBCode agar teks dari LLM/web tak bisa
## menyuntik format/spoofing ke RichTextLabel.
func _esc(s: String) -> String:
	return str(s).replace("[", "\\[").replace("]", "\\]")

func _add_comment(username: String, text: String, parent: VBoxContainer, color: Color = Color(0.56, 0.56, 0.56)) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = "[b][color=#e0e0e0]" + username + "[/color][/b] " + text
	label.fit_content = true
	label.scroll_active = false
	label.add_theme_font_size_override("normal_font_size", 13)
	label.add_theme_color_override("default_color", color)
	parent.add_child(label)

func _create_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0)  # Pure black for edge-to-edge
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.border_width_bottom = 1
	style.border_color = Color(0.1, 0.1, 0.1) # Subtle separator border at bottom
	return style

func _create_separator_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2)
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style

func _set_border_color(color: Color) -> void:
	var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	style.border_color = color
	style.border_width_left = 4
	add_theme_stylebox_override("panel", style)

func _get_avatar_color() -> Color:
	var colors := [
		Color(0.91, 0.30, 0.24),  # Red
		Color(0.17, 0.64, 0.80),  # Blue
		Color(0.55, 0.24, 0.78),  # Purple
		Color(0.15, 0.68, 0.38),  # Green
		Color(0.93, 0.65, 0.15),  # Orange
		Color(0.84, 0.19, 0.65),  # Pink
		Color(0.18, 0.50, 0.85),  # Royal Blue
		Color(0.10, 0.74, 0.61),  # Teal
		Color(0.75, 0.22, 0.17),  # Dark Red
		Color(0.56, 0.27, 0.68),  # Purple
	]
	var author: Dictionary = post_data.get("author", {})
	var username: String = author.get("username", "@user")
	var idx := username.hash() % colors.size()
	if idx < 0:
		idx += colors.size()
	return colors[idx]

func _get_initial() -> String:
	var author: Dictionary = post_data.get("author", {})
	var name: String = author.get("display_name", "U")
	return name.substr(0, 1).to_upper()

func _format_number(n: int) -> String:
	if n >= 1000:
		return str(snapped(n / 1000.0, 0.1)) + "K"
	return str(n)
