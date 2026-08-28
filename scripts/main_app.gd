extends Control
## Global shell that manages tab-based navigation while preserving state.

var ScreenMap := {
	"home": preload("res://scenes/feed_screen.tscn"),
	"notification": preload("res://scenes/notification_screen.tscn"),
	"profile": preload("res://scenes/profile_screen.tscn")
}

var _cached_screens := {}
var screen_container: Control
var bottom_nav: Control
var current_tab: String = "home"

func _ready() -> void:
	# Root Background so we don't have transparency issues
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Build layout
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)
	
	screen_container = Control.new()
	screen_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen_container.clip_contents = true
	main_vbox.add_child(screen_container)
	
	# Instantiate and wire the bottom nav bar manually
	bottom_nav = preload("res://scripts/bottom_nav_bar.gd").new()
	bottom_nav.tab_requested.connect(_on_tab_requested)
	main_vbox.add_child(bottom_nav)
	
	# Load the initial tab state
	_load_tab(current_tab)

func _load_tab(tab: String) -> void:
	# Hide all existing screens
	for child in screen_container.get_children():
		child.hide()
	
	# Create if not exists in cache
	if not _cached_screens.has(tab):
		if not ScreenMap.has(tab):
			return # Unhandled tab
		
		var new_screen = ScreenMap[tab].instantiate()
		new_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
		screen_container.add_child(new_screen)
		_cached_screens[tab] = new_screen
	
	# Show the selected scene
	_cached_screens[tab].show()
	current_tab = tab
	
	# Mark notifications as read when opening notification tab
	if tab == "notification":
		GameData.mark_all_read()
	
	if bottom_nav.has_method("force_tab_update"):
		bottom_nav.force_tab_update(tab)

func _on_tab_requested(tab: String) -> void:
	if current_tab == tab:
		return
	_load_tab(tab)
