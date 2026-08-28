extends Control
## Feed Manager — core game loop. Manages posts, answers, preloading, breaks.

enum FeedState { LOADING_INITIAL, SCROLLING, ANSWERING, SHOWING_FEEDBACK, LOADING_MORE, BREAK_POPUP }

const PRELOAD_TRIGGER_POST := 3  # Start preloading at post #3 of current batch
const BREAK_INTERVAL_SEC := 900  # 15 minutes

var current_state: FeedState = FeedState.LOADING_INITIAL
var current_batch_posts: Array = []
var all_post_cards: Array = []
var current_post_index: int = -1  # Index of post being answered
var total_posts_in_feed: int = 0
var batch_post_offset: int = 0  # Where current batch starts in all_post_cards

# Preloader state
var preload_state: String = "IDLE"  # IDLE, LOADING, READY
var preloaded_posts: Array = []
var preload_triggered: bool = false

# UI References
var scroll_container: ScrollContainer
var post_container: VBoxContainer
var answer_overlay: Panel
var answer_panel_vbox: VBoxContainer
var answer_question_label: RichTextLabel
var answer_buttons: Array[Button] = []
var reward_popup: PanelContainer
var reward_label: Label
var loading_container: VBoxContainer
var loading_label: Label
var break_overlay: Panel
var top_bar_followers: Label
var spinner_label: Label

# API
var api_client: Node  # api_client.gd
var break_timer: Timer
var spinner_timer: Timer

func _ready() -> void:
	_build_ui()
	_setup_api_client()
	_setup_break_timer()
	_setup_spinner_animation()
	
	# Request first batch
	current_state = FeedState.LOADING_INITIAL
	loading_container.visible = true
	api_client.request_batch(SessionManager.build_session_context())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SessionManager.end_session()

# ===== UI BUILDING =====

func _build_ui() -> void:
	# Root styling
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color.BLACK
	add_theme_stylebox_override("panel", bg)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	main_vbox.name = "MainVBox"
	add_child(main_vbox)
	
	# === TOP BAR ===
	var top_bar := PanelContainer.new()
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color.BLACK
	top_style.border_width_bottom = 1
	top_style.border_color = Color(0.15, 0.15, 0.15)
	top_style.content_margin_left = 16
	top_style.content_margin_right = 16
	top_style.content_margin_top = 8
	top_style.content_margin_bottom = 8
	top_bar.add_theme_stylebox_override("panel", top_style)
	top_bar.custom_minimum_size.y = 50
	main_vbox.add_child(top_bar)
	
	var top_hbox := HBoxContainer.new()
	top_bar.add_child(top_hbox)
	
	var logo_label := Label.new()
	logo_label.text = "📸 SlangFeed"
	logo_label.add_theme_font_size_override("font_size", 18)
	logo_label.add_theme_color_override("font_color", Color.WHITE)
	logo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(logo_label)
	
	# Vocab Book button
	var vocab_btn := Button.new()
	vocab_btn.text = "📖"
	vocab_btn.add_theme_font_size_override("font_size", 20)
	var vocab_btn_style := StyleBoxFlat.new()
	vocab_btn_style.bg_color = Color(0, 0, 0, 0)
	vocab_btn.add_theme_stylebox_override("normal", vocab_btn_style)
	vocab_btn.add_theme_stylebox_override("hover", vocab_btn_style)
	vocab_btn.add_theme_stylebox_override("pressed", vocab_btn_style)
	vocab_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	vocab_btn.custom_minimum_size = Vector2(40, 40)
	vocab_btn.pressed.connect(_on_vocab_book_pressed)
	vocab_btn.tooltip_text = "Vocab Book"
	top_hbox.add_child(vocab_btn)
	
	# Points display
	var points_label := Label.new()
	points_label.name = "PointsLabel"
	points_label.text = "⭐ " + str(GameData.points)
	points_label.add_theme_font_size_override("font_size", 14)
	points_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	top_hbox.add_child(points_label)
	
	top_bar_followers = Label.new()
	top_bar_followers.text = "👥 " + str(GameData.total_followers)
	top_bar_followers.add_theme_font_size_override("font_size", 14)
	top_bar_followers.add_theme_color_override("font_color", Color.WHITE)
	top_hbox.add_child(top_bar_followers)
	
	# === SCROLL AREA ===
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)
	main_vbox.add_child(scroll_container)
	
	post_container = VBoxContainer.new()
	post_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	post_container.add_theme_constant_override("separation", 0) # Edge to edge
	scroll_container.add_child(post_container)
	
	# Removed top spacer for true edge-to-edge
	
	# === LOADING CONTAINER ===
	loading_container = VBoxContainer.new()
	loading_container.set_anchors_preset(Control.PRESET_CENTER)
	loading_container.alignment = BoxContainer.ALIGNMENT_CENTER
	loading_container.visible = false
	add_child(loading_container)
	
	spinner_label = Label.new()
	spinner_label.text = "⟳"
	spinner_label.add_theme_font_size_override("font_size", 40)
	spinner_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
	spinner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_container.add_child(spinner_label)
	
	loading_label = Label.new()
	loading_label.text = "Loading posts..."
	loading_label.add_theme_font_size_override("font_size", 14)
	loading_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_container.add_child(loading_label)
	
	# === ANSWER OVERLAY ===
	_build_answer_overlay()
	
	# === REWARD POPUP ===
	_build_reward_popup()
	
	# === BREAK POPUP ===
	_build_break_popup()
	
	# Removed standalone bottom navbar instanciation since MainApp handles it

func _build_answer_overlay() -> void:
	answer_overlay = Panel.new()
	answer_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0, 0, 0, 0.7)
	answer_overlay.add_theme_stylebox_override("panel", overlay_style)
	answer_overlay.visible = false
	answer_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(answer_overlay)
	
	var answer_card := PanelContainer.new()
	answer_card.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	answer_card.anchor_top = 0.35
	answer_card.anchor_bottom = 0.95
	answer_card.anchor_left = 0.05
	answer_card.anchor_right = 0.95
	answer_card.offset_top = 0
	answer_card.offset_bottom = 0
	answer_card.offset_left = 0
	answer_card.offset_right = 0
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.15, 0.15, 0.15) # #262626
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	card_style.content_margin_left = 20
	card_style.content_margin_right = 20
	card_style.content_margin_top = 20
	card_style.content_margin_bottom = 20
	answer_card.add_theme_stylebox_override("panel", card_style)
	answer_overlay.add_child(answer_card)
	
	answer_panel_vbox = VBoxContainer.new()
	answer_panel_vbox.add_theme_constant_override("separation", 12)
	answer_card.add_child(answer_panel_vbox)
	
	var header_label := Label.new()
	header_label.text = "💬 Choose your reply"
	header_label.add_theme_font_size_override("font_size", 18)
	header_label.add_theme_color_override("font_color", Color.WHITE)
	answer_panel_vbox.add_child(header_label)
	
	answer_question_label = RichTextLabel.new()
	answer_question_label.bbcode_enabled = true
	answer_question_label.fit_content = true
	answer_question_label.scroll_active = false
	answer_question_label.add_theme_font_size_override("normal_font_size", 14)
	answer_question_label.add_theme_color_override("default_color", Color(0.75, 0.75, 0.75))
	answer_panel_vbox.add_child(answer_question_label)
	
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.25, 0.25, 0.25)
	sep_style.content_margin_top = 1
	sep_style.content_margin_bottom = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	answer_panel_vbox.add_child(sep)
	
	# 4 answer buttons
	var option_letters := ["A", "B", "C", "D"]
	for i in 4:
		var btn := Button.new()
		btn.text = option_letters[i] + ". Option"
		btn.custom_minimum_size = Vector2(0, 50)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color.WHITE)
		
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.2, 0.2, 0.2)
		btn_style.corner_radius_top_left = 12
		btn_style.corner_radius_top_right = 12
		btn_style.corner_radius_bottom_left = 12
		btn_style.corner_radius_bottom_right = 12
		btn_style.content_margin_left = 16
		btn_style.content_margin_right = 16
		btn.add_theme_stylebox_override("normal", btn_style)
		
		var btn_hover := btn_style.duplicate()
		btn_hover.bg_color = Color(0.25, 0.25, 0.25)
		btn.add_theme_stylebox_override("hover", btn_hover)
		
		var letter: String = option_letters[i]
		btn.pressed.connect(_on_answer_selected.bind(letter))
		answer_panel_vbox.add_child(btn)
		answer_buttons.append(btn)

func _build_reward_popup() -> void:
	reward_popup = PanelContainer.new()
	reward_popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
	reward_popup.offset_top = 60
	reward_popup.custom_minimum_size = Vector2(300, 60)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.29, 0.87, 0.5)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	reward_popup.add_theme_stylebox_override("panel", style)
	reward_popup.visible = false
	reward_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(reward_popup)
	
	reward_label = Label.new()
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 15)
	reward_label.add_theme_color_override("font_color", Color.WHITE)
	reward_popup.add_child(reward_label)

func _build_break_popup() -> void:
	break_overlay = Panel.new()
	break_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0, 0, 0, 0.8)
	break_overlay.add_theme_stylebox_override("panel", overlay_style)
	break_overlay.visible = false
	break_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(break_overlay)
	
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(350, 300)
	card.anchor_left = 0.05
	card.anchor_right = 0.95
	card.offset_left = 0
	card.offset_right = 0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", style)
	break_overlay.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)
	
	var title := Label.new()
	title.text = "⏰ Hey!"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var subtitle := Label.new()
	subtitle.text = "You've been scrolling for\n15 minutes. Take a break!"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(subtitle)
	
	var stats_label := Label.new()
	stats_label.name = "BreakStats"
	stats_label.add_theme_font_size_override("font_size", 13)
	stats_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)
	
	var keep_btn := Button.new()
	keep_btn.text = "Keep Scrolling"
	keep_btn.custom_minimum_size = Vector2(0, 44)
	var keep_style := StyleBoxFlat.new()
	keep_style.bg_color = Color(0.0, 0.584, 0.965)
	keep_style.corner_radius_top_left = 10
	keep_style.corner_radius_top_right = 10
	keep_style.corner_radius_bottom_left = 10
	keep_style.corner_radius_bottom_right = 10
	keep_btn.add_theme_stylebox_override("normal", keep_style)
	keep_btn.add_theme_color_override("font_color", Color.WHITE)
	keep_btn.add_theme_font_size_override("font_size", 15)
	keep_btn.pressed.connect(_on_keep_scrolling)
	vbox.add_child(keep_btn)
	
	var end_btn := Button.new()
	end_btn.text = "End Session"
	end_btn.custom_minimum_size = Vector2(0, 44)
	var end_style := StyleBoxFlat.new()
	end_style.bg_color = Color(0.2, 0.2, 0.2)
	end_style.corner_radius_top_left = 10
	end_style.corner_radius_top_right = 10
	end_style.corner_radius_bottom_left = 10
	end_style.corner_radius_bottom_right = 10
	end_btn.add_theme_stylebox_override("normal", end_style)
	end_btn.add_theme_color_override("font_color", Color.WHITE)
	end_btn.add_theme_font_size_override("font_size", 15)
	end_btn.pressed.connect(_on_end_session)
	vbox.add_child(end_btn)

# ===== API CLIENT =====

func _setup_api_client() -> void:
	api_client = Node.new()
	api_client.set_script(load("res://scripts/api_client.gd"))
	add_child(api_client)
	api_client.batch_received.connect(_on_batch_received)
	api_client.batch_failed.connect(_on_batch_failed)

# ===== BREAK TIMER =====

func _setup_break_timer() -> void:
	break_timer = Timer.new()
	break_timer.wait_time = BREAK_INTERVAL_SEC
	break_timer.one_shot = true
	break_timer.timeout.connect(_on_break_timer_timeout)
	add_child(break_timer)
	break_timer.start()

func _setup_spinner_animation() -> void:
	spinner_timer = Timer.new()
	spinner_timer.wait_time = 0.1
	spinner_timer.timeout.connect(_animate_spinner)
	add_child(spinner_timer)
	spinner_timer.start()

var _spinner_frames := ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
var _spinner_index := 0

func _animate_spinner() -> void:
	if loading_container.visible and spinner_label:
		_spinner_index = (_spinner_index + 1) % _spinner_frames.size()
		spinner_label.text = _spinner_frames[_spinner_index]

# ===== BATCH HANDLING =====

func _on_batch_received(posts: Array, is_fallback: bool, _adaptation_note: String) -> void:
	SessionManager.batch_count += 1
	
	if is_fallback:
		SessionManager.fallback_count += posts.size()
	
	if current_state == FeedState.LOADING_INITIAL:
		loading_container.visible = false
		current_batch_posts = posts
		batch_post_offset = 0
		preload_triggered = false
		_add_posts_to_feed(posts)
		current_state = FeedState.SCROLLING
	elif preload_state == "LOADING":
		preloaded_posts = posts
		preload_state = "READY"
		# If we were waiting for this (LOADING_MORE state)
		if current_state == FeedState.LOADING_MORE:
			_append_preloaded_batch()

func _on_batch_failed(error: String) -> void:
	print("[FeedManager] Batch failed: ", error)
	loading_label.text = "Connection issue. Retrying..."
	# Retry after 3 seconds
	await get_tree().create_timer(3.0).timeout
	api_client.request_batch(SessionManager.build_session_context())

func _add_posts_to_feed(posts: Array) -> void:
	for i in posts.size():
		var card := PanelContainer.new()
		card.set_script(load("res://scripts/post_controller.gd"))
		post_container.add_child(card)
		card.setup(posts[i], total_posts_in_feed)
		card.reply_pressed.connect(_on_reply_pressed)
		all_post_cards.append(card)
		total_posts_in_feed += 1
	
	# Bottom spacer
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 80
	spacer.name = "BottomSpacer"
	post_container.add_child(spacer)

func _append_preloaded_batch() -> void:
	# Remove loading spinner at bottom if exists
	_remove_bottom_loading()
	
	current_batch_posts = preloaded_posts
	batch_post_offset = total_posts_in_feed
	preloaded_posts = []
	preload_state = "IDLE"
	preload_triggered = false
	_add_posts_to_feed(current_batch_posts)
	current_state = FeedState.SCROLLING
	loading_container.visible = false

# ===== SCROLL DETECTION =====

func _on_scroll_changed(_value: float) -> void:
	if current_state != FeedState.SCROLLING:
		return
	
	_check_preload_trigger()
	_check_end_of_batch()

func _check_preload_trigger() -> void:
	if preload_triggered or preload_state != "IDLE":
		return
	
	# Check if user has scrolled past post #3 of current batch
	var trigger_index := batch_post_offset + PRELOAD_TRIGGER_POST - 1
	if trigger_index >= all_post_cards.size():
		return
	
	var trigger_card: Control = all_post_cards[trigger_index]
	var scroll_bottom := scroll_container.scroll_vertical + scroll_container.size.y
	var card_top: float = trigger_card.global_position.y - scroll_container.global_position.y + scroll_container.scroll_vertical
	
	if scroll_bottom > card_top:
		preload_triggered = true
		preload_state = "LOADING"
		api_client.request_batch(SessionManager.build_session_context())

func _check_end_of_batch() -> void:
	if all_post_cards.is_empty():
		return
	
	var last_card: Control = all_post_cards[-1]
	var scroll_bottom := scroll_container.scroll_vertical + scroll_container.size.y
	var card_bottom: float = last_card.global_position.y - scroll_container.global_position.y + scroll_container.scroll_vertical + last_card.size.y
	
	if scroll_bottom >= card_bottom - 100:
		if preload_state == "READY":
			_append_preloaded_batch()
		elif preload_state == "LOADING":
			current_state = FeedState.LOADING_MORE
			_show_bottom_loading()
		elif preload_state == "IDLE":
			# Trigger preload now
			preload_triggered = true
			preload_state = "LOADING"
			current_state = FeedState.LOADING_MORE
			_show_bottom_loading()
			api_client.request_batch(SessionManager.build_session_context())

func _show_bottom_loading() -> void:
	var spinner := Label.new()
	spinner.name = "BottomLoadingSpinner"
	spinner.text = "Loading more posts..."
	spinner.add_theme_font_size_override("font_size", 14)
	spinner.add_theme_color_override("font_color", Color(0.56, 0.56, 0.56))
	spinner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner.custom_minimum_size.y = 60
	post_container.add_child(spinner)

func _remove_bottom_loading() -> void:
	var spinner := post_container.get_node_or_null("BottomLoadingSpinner")
	if spinner:
		spinner.queue_free()
	# Also remove bottom spacers
	for child in post_container.get_children():
		if child.name == "BottomSpacer":
			child.queue_free()

# ===== ANSWER FLOW =====

func _on_reply_pressed(post_index: int) -> void:
	if current_state != FeedState.SCROLLING:
		return
	
	current_state = FeedState.ANSWERING
	current_post_index = post_index
	
	var card = all_post_cards[post_index]
	var post_data: Dictionary = card.post_data
	
	# Fill answer panel
	var qc: Dictionary = post_data.get("question_comment", {})
	answer_question_label.text = "[color=#0095f6]" + qc.get("user", "@user") + ":[/color] " + qc.get("text", "")
	
	var options: Array = post_data.get("options", [])
	for i in min(4, options.size()):
		answer_buttons[i].text = str(options[i])
		answer_buttons[i].disabled = false
		# Reset style
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.2, 0.2, 0.2)
		btn_style.corner_radius_top_left = 12
		btn_style.corner_radius_top_right = 12
		btn_style.corner_radius_bottom_left = 12
		btn_style.corner_radius_bottom_right = 12
		btn_style.content_margin_left = 16
		btn_style.content_margin_right = 16
		answer_buttons[i].add_theme_stylebox_override("normal", btn_style)
	
	# Show overlay with animation
	answer_overlay.visible = true
	answer_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(answer_overlay, "modulate:a", 1.0, 0.2)

func _on_answer_selected(letter: String) -> void:
	if current_state != FeedState.ANSWERING:
		return
	
	current_state = FeedState.SHOWING_FEEDBACK
	
	var card = all_post_cards[current_post_index]
	var post_data: Dictionary = card.post_data
	var correct_answer: String = post_data.get("correct_answer", "A")
	var is_correct: bool = (letter == correct_answer)
	var slang: String = post_data.get("slang_tested", "")
	var explanation: String = post_data.get("explanation", "")
	
	# Highlight the selected button
	var letter_index := ["A", "B", "C", "D"].find(letter)
	if letter_index >= 0 and letter_index < answer_buttons.size():
		var btn := answer_buttons[letter_index]
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 16
		style.content_margin_right = 16
		if is_correct:
			style.bg_color = Color(0.29, 0.87, 0.5, 0.5)
		else:
			style.bg_color = Color(0.94, 0.27, 0.27, 0.5)
		btn.add_theme_stylebox_override("normal", style)
	
	# If wrong, also highlight the correct one
	if not is_correct:
		var correct_index := ["A", "B", "C", "D"].find(correct_answer)
		if correct_index >= 0 and correct_index < answer_buttons.size():
			var correct_btn := answer_buttons[correct_index]
			var correct_style := StyleBoxFlat.new()
			correct_style.bg_color = Color(0.29, 0.87, 0.5, 0.3)
			correct_style.corner_radius_top_left = 10
			correct_style.corner_radius_top_right = 10
			correct_style.corner_radius_bottom_left = 10
			correct_style.corner_radius_bottom_right = 10
			correct_style.content_margin_left = 16
			correct_style.content_margin_right = 16
			correct_btn.add_theme_stylebox_override("normal", correct_style)
	
	# Disable all buttons
	for btn in answer_buttons:
		btn.disabled = true
	
	# Log the answer
	var response_time: int = card.get_response_time_ms()
	SessionManager.log_answer({
		"slang_tested": slang,
		"question": post_data.get("question_comment", {}).get("text", ""),
		"player_answer": letter,
		"correct_answer": correct_answer,
		"is_correct": is_correct,
		"response_time_ms": response_time,
		"explanation": explanation,
		"is_fallback": false
	})
	
	# Update points & followers
	if is_correct:
		GameData.add_points_correct()
		GameData.add_learned_slang(slang, explanation)
	else:
		GameData.add_points_wrong()
	
	top_bar_followers.text = "👥 " + str(GameData.total_followers)
	var points_lbl := get_node_or_null("%PointsLabel")
	if not points_lbl:
		# Find it in tree
		for child in get_tree().get_nodes_in_group(""):
			pass
	_update_points_display()
	
	# Wait a moment then close overlay and show feedback on card
	await get_tree().create_timer(0.8).timeout
	
	# Close answer overlay
	var tween := create_tween()
	tween.tween_property(answer_overlay, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): answer_overlay.visible = false)
	
	await tween.finished
	
	# Show feedback on card
	if is_correct:
		card.show_correct_feedback(GameData.player_username)
		_show_reward(true, slang)
	else:
		card.show_wrong_feedback(GameData.player_username)
		_show_reward(false, slang)
	
	# Wait then return to scrolling
	await get_tree().create_timer(1.0).timeout
	current_state = FeedState.SCROLLING

func _show_reward(is_correct: bool, slang: String) -> void:
	if is_correct:
		reward_label.text = "✨ +%d Points!\n\"%s\" learned ✓" % [GameData.POINTS_CORRECT, slang]
		var style: StyleBoxFlat = reward_popup.get_theme_stylebox("panel").duplicate()
		style.border_color = Color(0.29, 0.87, 0.5)
		reward_popup.add_theme_stylebox_override("panel", style)
	else:
		reward_label.text = "📉 %d Points\nCorrect: \"%s\"" % [GameData.POINTS_WRONG, slang]
		var style: StyleBoxFlat = reward_popup.get_theme_stylebox("panel").duplicate()
		style.border_color = Color(0.94, 0.27, 0.27)
		reward_popup.add_theme_stylebox_override("panel", style)
	
	reward_popup.visible = true
	reward_popup.modulate.a = 0.0
	reward_popup.position.y = 40
	
	var tween := create_tween()
	tween.tween_property(reward_popup, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(reward_popup, "position:y", 60, 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(2.0)
	tween.tween_property(reward_popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): reward_popup.visible = false)

func _update_points_display() -> void:
	# Find points label in the top bar
	var main_vbox_node := get_node_or_null("MainVBox")
	if main_vbox_node:
		for child in main_vbox_node.get_children():
			if child is PanelContainer:
				var hbox := child.get_child(0)
				if hbox is HBoxContainer:
					for lbl in hbox.get_children():
						if lbl is Label and lbl.name == "PointsLabel":
							lbl.text = "⭐ " + str(GameData.points)
							return

# ===== VOCAB BOOK =====

var vocab_overlay: Panel

func _on_vocab_book_pressed() -> void:
	if vocab_overlay and vocab_overlay.visible:
		_close_vocab_book()
		return
	_build_vocab_book()

func _build_vocab_book() -> void:
	if vocab_overlay:
		vocab_overlay.queue_free()
	
	vocab_overlay = Panel.new()
	vocab_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0, 0, 0, 0.85)
	vocab_overlay.add_theme_stylebox_override("panel", overlay_style)
	vocab_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(vocab_overlay)
	
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	vocab_overlay.add_child(margin)
	
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.1, 0.1)
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	card_style.content_margin_left = 16
	card_style.content_margin_right = 16
	card_style.content_margin_top = 16
	card_style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", card_style)
	margin.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)
	
	# Header
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title := Label.new()
	title.text = "📖 Vocab Book"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var count_label := Label.new()
	count_label.text = "%d slangs learned" % GameData.learned_slangs.size()
	count_label.add_theme_font_size_override("font_size", 13)
	count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	header_hbox.add_child(count_label)
	
	# Search bar
	var search := LineEdit.new()
	search.name = "VocabSearch"
	search.placeholder_text = "🔍 Search slangs..."
	search.add_theme_font_size_override("font_size", 14)
	var search_style := StyleBoxFlat.new()
	search_style.bg_color = Color(0.15, 0.15, 0.15)
	search_style.corner_radius_top_left = 10
	search_style.corner_radius_top_right = 10
	search_style.corner_radius_bottom_left = 10
	search_style.corner_radius_bottom_right = 10
	search_style.content_margin_left = 12
	search_style.content_margin_right = 12
	search.add_theme_stylebox_override("normal", search_style)
	search.custom_minimum_size.y = 36
	vbox.add_child(search)
	
	# Scroll for slang list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var list_vbox := VBoxContainer.new()
	list_vbox.name = "SlangList"
	list_vbox.add_theme_constant_override("separation", 2)
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_vbox)
	
	_populate_vocab_list(list_vbox, "")
	
	search.text_changed.connect(func(new_text: String) -> void:
		_populate_vocab_list(list_vbox, new_text)
	)
	
	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 14)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.2, 0.2, 0.2)
	close_style.corner_radius_top_left = 10
	close_style.corner_radius_top_right = 10
	close_style.corner_radius_bottom_left = 10
	close_style.corner_radius_bottom_right = 10
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.custom_minimum_size.y = 40
	close_btn.pressed.connect(_close_vocab_book)
	vbox.add_child(close_btn)
	
	# Animate in
	vocab_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(vocab_overlay, "modulate:a", 1.0, 0.2)

func _populate_vocab_list(list_vbox: VBoxContainer, filter: String) -> void:
	for child in list_vbox.get_children():
		child.queue_free()
	
	var slangs := GameData.learned_slangs.duplicate()
	slangs.reverse()  # Newest first
	
	if slangs.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No slangs learned yet!\nAnswer questions correctly to build your vocab 📚"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_vbox.add_child(empty_label)
		return
	
	var filter_lower := filter.to_lower().strip_edges()
	var count := 0
	for s in slangs:
		var slang_text: String = s.get("slang", "")
		var meaning_text: String = s.get("meaning", "")
		if filter_lower != "" and slang_text.to_lower().find(filter_lower) == -1:
			continue
		
		var item := PanelContainer.new()
		var item_style := StyleBoxFlat.new()
		item_style.bg_color = Color(0.13, 0.13, 0.13) if count % 2 == 0 else Color(0.11, 0.11, 0.11)
		item_style.corner_radius_top_left = 8
		item_style.corner_radius_top_right = 8
		item_style.corner_radius_bottom_left = 8
		item_style.corner_radius_bottom_right = 8
		item_style.content_margin_left = 12
		item_style.content_margin_right = 12
		item_style.content_margin_top = 10
		item_style.content_margin_bottom = 10
		item.add_theme_stylebox_override("panel", item_style)
		list_vbox.add_child(item)
		
		var item_vbox := VBoxContainer.new()
		item_vbox.add_theme_constant_override("separation", 4)
		item.add_child(item_vbox)
		
		var slang_label := Label.new()
		slang_label.text = "💬 " + slang_text
		slang_label.add_theme_font_size_override("font_size", 15)
		slang_label.add_theme_color_override("font_color", Color(0.0, 0.584, 0.965))
		item_vbox.add_child(slang_label)
		
		var meaning_label := Label.new()
		meaning_label.text = meaning_text
		meaning_label.add_theme_font_size_override("font_size", 13)
		meaning_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		meaning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_vbox.add_child(meaning_label)
		
		count += 1

func _close_vocab_book() -> void:
	if vocab_overlay:
		var tween := create_tween()
		tween.tween_property(vocab_overlay, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): 
			if vocab_overlay:
				vocab_overlay.queue_free()
				vocab_overlay = null
		)

# ===== BREAK =====

func _on_break_timer_timeout() -> void:
	current_state = FeedState.BREAK_POPUP
	
	# Update break stats
	var stats_label := break_overlay.get_node_or_null("PanelContainer/VBoxContainer/BreakStats")
	if not stats_label:
		# Find it differently
		for child in break_overlay.get_children():
			if child is PanelContainer:
				for vchild in child.get_children():
					if vchild is VBoxContainer:
						for label in vchild.get_children():
							if label.name == "BreakStats":
								stats_label = label
								break
	
	if stats_label:
		stats_label.text = "✅ %d correct  ❌ %d wrong\n👥 %+d followers" % [
			SessionManager.get_total_correct(),
			SessionManager.get_total_wrong(),
			SessionManager.get_followers_gained()
		]
	
	break_overlay.visible = true
	break_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(break_overlay, "modulate:a", 1.0, 0.3)

func _on_keep_scrolling() -> void:
	break_overlay.visible = false
	current_state = FeedState.SCROLLING
	break_timer.start()

func _on_end_session() -> void:
	SessionManager.end_session()
	get_tree().change_scene_to_file("res://scenes/result_screen.tscn")
