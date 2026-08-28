extends PanelContainer
## Bottom Nav Bar Component — 4 tabs: Home, Message, Notification, Profile

signal tab_requested(tab_name: String)

var current_tab: String = "home"

var icons: Dictionary = {
	"home": {
		"active": preload("res://assets/art/Dark_Theme/home(active)_icon_dark.png"),
		"inactive": preload("res://assets/art/Dark_Theme/home(inactive)_icon_dark.png")
	},
	"notification": {
		"active": preload("res://assets/art/Dark_Theme/notification(active)_icon_dark.png"),
		"inactive": preload("res://assets/art/Dark_Theme/notification(inactive)_icon_dark.png")
	},
	"profile": {
		"active": preload("res://assets/art/Dark_Theme/Official_Icon_dark.png"),
		"inactive": preload("res://assets/art/Dark_Theme/Official_Icon_dark.png")
	}
}

var buttons: Dictionary = {}
var badge_labels: Dictionary = {}

func _ready() -> void:
	_build_ui()

func force_tab_update(tab: String) -> void:
	current_tab = tab
	for t in buttons.keys():
		var icon_rect: TextureRect = buttons[t]
		icon_rect.texture = icons[t]["active"] if current_tab == t else icons[t]["inactive"]
		icon_rect.modulate = Color.WHITE if current_tab == t else Color(0.6, 0.6, 0.6)
	_update_notif_badge()

func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.04)
	style.border_width_top = 1
	style.border_color = Color(0.15, 0.15, 0.15)
	add_theme_stylebox_override("panel", style)
	
	custom_minimum_size.y = 56
	
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 0)
	add_child(hbox)
	
	var tabs := ["home", "notification", "profile"]
	for tab in tabs:
		var btn := TextureButton.new()
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		var icon_size := 24
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Inner Margin to center the texture physically
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(margin)
		
		var icon_rect := TextureRect.new()
		icon_rect.texture = icons[tab]["active"] if current_tab == tab else icons[tab]["inactive"]
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_rect.modulate = Color.WHITE if current_tab == tab else Color(0.6, 0.6, 0.6)
		margin.add_child(icon_rect)
		
		# Hide the button's default texture to use TextureRect instead
		btn.texture_normal = null
		
		# Notification badge (for notif tab)
		if tab == "notification":
			var badge := Label.new()
			badge.name = "NotifBadge"
			badge.text = ""
			badge.add_theme_font_size_override("font_size", 9)
			badge.add_theme_color_override("font_color", Color.WHITE)
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.position = Vector2(30, 8)
			badge.custom_minimum_size = Vector2(16, 16)
			btn.add_child(badge)
			badge_labels["notification"] = badge
		
		btn.pressed.connect(_on_tab_pressed.bind(tab))
		hbox.add_child(btn)
		buttons[tab] = icon_rect
	
	_update_notif_badge()

func _update_notif_badge() -> void:
	var count := GameData.get_unread_count()
	if badge_labels.has("notification"):
		var badge: Label = badge_labels["notification"]
		if count > 0:
			badge.text = str(count) if count < 10 else "9+"
			badge.visible = true
		else:
			badge.visible = false

func _on_tab_pressed(tab: String) -> void:
	if current_tab == tab:
		return
	
	tab_requested.emit(tab)
