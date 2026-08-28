extends Control
## Home Screen — username input, follower count, start button.

@onready var username_input: LineEdit = %UsernameInput
@onready var follower_label: Label = %FollowerLabel
@onready var slang_count_label: Label = %SlangCountLabel
@onready var start_button: Button = %StartButton
@onready var error_label: Label = %ErrorLabel

func _ready() -> void:
	# Populate from saved data
	if GameData.player_username != "":
		username_input.text = GameData.player_username
	follower_label.text = str(GameData.total_followers)
	slang_count_label.text = "%d slangs learned" % GameData.learned_slangs.size()
	error_label.visible = false
	
	# === Instagram styling ===
	var bg_node := get_node_or_null("Background") as ColorRect
	if bg_node:
		bg_node.color = Color(0.03, 0.03, 0.03) # aesthetic deep black/grey
		
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0.12, 0.12, 0.12)
	input_style.corner_radius_top_left = 12
	input_style.corner_radius_top_right = 12
	input_style.corner_radius_bottom_left = 12
	input_style.corner_radius_bottom_right = 12
	input_style.border_width_bottom = 2
	input_style.border_color = Color(0.3, 0.3, 0.3)
	username_input.add_theme_stylebox_override("normal", input_style)
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.0, 0.584, 0.965) # Insta Blue
	btn_style.corner_radius_top_left = 12
	btn_style.corner_radius_top_right = 12
	btn_style.corner_radius_bottom_left = 12
	btn_style.corner_radius_bottom_right = 12
	start_button.add_theme_stylebox_override("normal", btn_style)
	
	# Hover style
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.0, 0.5, 0.85)
	start_button.add_theme_stylebox_override("hover", btn_hover)
	
	start_button.pressed.connect(_on_start_pressed)
	username_input.text_changed.connect(_on_username_changed)
	
	# Entrance animation
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _on_username_changed(_text: String) -> void:
	error_label.visible = false

func _on_start_pressed() -> void:
	var username := username_input.text.strip_edges()
	
	if username.length() < 3:
		error_label.text = "Username must be at least 3 characters"
		error_label.visible = true
		# Shake animation
		var shake_tween := create_tween()
		shake_tween.tween_property(username_input, "position:x", username_input.position.x + 10, 0.05)
		shake_tween.tween_property(username_input, "position:x", username_input.position.x - 10, 0.05)
		shake_tween.tween_property(username_input, "position:x", username_input.position.x, 0.05)
		return
	
	# Save and start
	GameData.player_username = username
	GameData.save_data()
	SessionManager.start_session()
	
	# Fade out and go to feed
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	fade_tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_app.tscn"))

