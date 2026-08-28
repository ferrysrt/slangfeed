extends Control
## Message Screen — SlangGuru Interactive Chat (stub offline).
## Fitur chat LLM (#/chat endpoint) TIDAK termasuk scope skripsi (Opsi B —
## scope evaluasi: fungsional + usability + persepsi). Tab ini dipertahankan
## agar navigasi 3-tab tidak berubah, namun SlangGuru menjawab offline
## dari dataset lokal (tanpa panggilan API).

var chat_scroll: ScrollContainer
var chat_container: VBoxContainer
var input_field: LineEdit
var send_button: Button

func _ready() -> void:
	_build_ui()
	_add_guru_bubble(
		"Hey! 👋 I'm SlangGuru, your internet slang expert!\n" +
		"Ask me about any slang from your Vocab Book or the dictionary.\n" +
		"Try asking: 'What does ghosting mean?' 🤔"
	)

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
	top_style.content_margin_top = 10
	top_style.content_margin_bottom = 10
	top_bar.add_theme_stylebox_override("panel", top_style)
	main_vbox.add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	top_bar.add_child(top_hbox)

	var avatar := Label.new()
	avatar.text = "🤖"
	avatar.add_theme_font_size_override("font_size", 28)
	top_hbox.add_child(avatar)

	var name_vbox := VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 0)
	top_hbox.add_child(name_vbox)

	var name_label := Label.new()
	name_label.text = "SlangGuru"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_vbox.add_child(name_label)

	var status_label := Label.new()
	status_label.text = "Online • Offline dictionary mode"
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.29, 0.87, 0.5))
	name_vbox.add_child(status_label)

	# === CHAT AREA ===
	chat_scroll = ScrollContainer.new()
	chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(chat_scroll)

	chat_container = VBoxContainer.new()
	chat_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_container.add_theme_constant_override("separation", 8)
	chat_scroll.add_child(chat_container)

	# === INPUT BAR ===
	var input_bar := PanelContainer.new()
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0.04, 0.04, 0.04)
	input_style.border_width_top = 1
	input_style.border_color = Color(0.15, 0.15, 0.15)
	input_style.content_margin_left = 12
	input_style.content_margin_right = 12
	input_style.content_margin_top = 8
	input_style.content_margin_bottom = 8
	input_bar.add_theme_stylebox_override("panel", input_style)
	main_vbox.add_child(input_bar)

	var input_hbox := HBoxContainer.new()
	input_hbox.add_theme_constant_override("separation", 8)
	input_bar.add_child(input_hbox)

	input_field = LineEdit.new()
	input_field.placeholder_text = "Ask about a slang..."
	input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_field.add_theme_font_size_override("font_size", 14)
	var field_style := StyleBoxFlat.new()
	field_style.bg_color = Color(0.12, 0.12, 0.12)
	field_style.corner_radius_top_left = 20
	field_style.corner_radius_top_right = 20
	field_style.corner_radius_bottom_left = 20
	field_style.corner_radius_bottom_right = 20
	field_style.content_margin_left = 14
	field_style.content_margin_right = 14
	field_style.content_margin_top = 8
	field_style.content_margin_bottom = 8
	input_field.add_theme_stylebox_override("normal", field_style)
	input_field.text_submitted.connect(func(_t): _send_message())
	input_hbox.add_child(input_field)

	send_button = Button.new()
	send_button.text = "Send"
	send_button.custom_minimum_size = Vector2(70, 40)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.0, 0.584, 0.965)
	btn_style.corner_radius_top_left = 20
	btn_style.corner_radius_top_right = 20
	btn_style.corner_radius_bottom_left = 20
	btn_style.corner_radius_bottom_right = 20
	send_button.add_theme_stylebox_override("normal", btn_style)
	send_button.pressed.connect(_send_message)
	input_hbox.add_child(send_button)

# ===== CHAT LOGIC (OFFLINE — dari dataset lokal) =====

func _send_message() -> void:
	var text := input_field.text.strip_edges()
	if text == "":
		return
	input_field.text = ""
	_add_user_bubble(text)

	var answer := _lookup_slang(text)
	await get_tree().create_timer(0.4).timeout
	_add_guru_bubble(answer)

## Cari slang di dataset + vocab book dari pesan bebas pengguna.
func _lookup_slang(message: String) -> String:
	var msg := message.to_lower()
	var candidates: Array = []
	# Gabung dataset + vocab book (vocab book punya arti personal yang sudah dipelajari)
	for e in DatasetLoader.entries:
		candidates.append({"slang": e.get("slang", ""), "meaning": e.get("definition", "")})
	for s in GameData.learned_slangs:
		candidates.append({"slang": s.get("slang", ""), "meaning": s.get("meaning", "")})

	var best: Dictionary = {}
	for c in candidates:
		var term := str(c.get("slang", "")).to_lower()
		if term != "" and msg.find(term) != -1:
			if term.length() > str(best.get("slang", "")).length():
				best = c  # match terpanjang menang
	if best.is_empty():
		return "Hmm, I don't have that one in my dictionary yet 📚\nTry one of the slangs you've learned, or check your Vocab Book!"
	return "\"%s\" means: %s" % [best.get("slang", ""), best.get("meaning", "")]

# ===== BUBBLES =====

func _add_guru_bubble(text: String) -> void:
	var bubble := _make_bubble(text, Color(0.12, 0.12, 0.12), HORIZONTAL_ALIGNMENT_LEFT, false)
	chat_container.add_child(bubble)
	_scroll_to_bottom()

func _add_user_bubble(text: String) -> void:
	var bubble := _make_bubble(text, Color(0.0, 0.4, 0.7), HORIZONTAL_ALIGNMENT_RIGHT, true)
	chat_container.add_child(bubble)
	_scroll_to_bottom()

func _make_bubble(text: String, bg_color: Color, align: int, is_user: bool) -> PanelContainer:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(h)
	if is_user:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(spacer)

	var bubble := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	bubble.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 240
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	bubble.add_child(label)
	h.add_child(bubble)
	return margin

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	chat_scroll.scroll_vertical = int(chat_scroll.get_v_scroll_bar().max_value)
