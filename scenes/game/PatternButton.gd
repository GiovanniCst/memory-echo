extends Control
class_name PatternButton

# Signals
signal pressed(button_id: int)

@export var button_id: int
@export var button_color: Color
@export var highlight_duration: float = 0.6

# Child nodes
@onready var color_rect: ColorRect = $ColorRect
var tween: Tween

# Color states for Simon Says effect
var dimmed_color: Color
var bright_color: Color

# States
enum ButtonState { IDLE, HIGHLIGHTED, PRESSED, DISABLED }
var current_state: ButtonState = ButtonState.IDLE

func _ready():
	print("[%.2f] PatternButton _ready() called for button_id: %d" % [Time.get_ticks_msec() / 1000.0, button_id])
	# Calculate dimmed and bright colors for Simon Says effect
	dimmed_color = Color(button_color.r * 0.4, button_color.g * 0.4, button_color.b * 0.4, 1.0)
	bright_color = button_color
	
	# Initialize the button with dimmed color
	if color_rect:
		color_rect.color = dimmed_color
		print("[%.2f] Set button color to: %s (dimmed)" % [Time.get_ticks_msec() / 1000.0, str(dimmed_color)])

func _gui_input(event):
	print("[%.2f] _gui_input called on button %d with event: %s, current_state: %s" % [Time.get_ticks_msec() / 1000.0, button_id, str(event), ButtonState.keys()[current_state]])
	if current_state == ButtonState.DISABLED:
		return
	
	if event is InputEventMouseButton:
		print("[%.2f] Mouse button event detected on button %d" % [Time.get_ticks_msec() / 1000.0, button_id])
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("[%.2f] Button %d clicked!" % [Time.get_ticks_msec() / 1000.0, button_id])
			press()

func _input(event):
	if current_state == ButtonState.DISABLED:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var global_mouse_pos = get_global_mouse_position()
		var button_rect = get_global_rect()
		if button_rect.has_point(global_mouse_pos):
			print("[%.2f] Button %d clicked via _input!" % [Time.get_ticks_msec() / 1000.0, button_id])
			press()
			get_viewport().set_input_as_handled()  # Prevent other buttons from processing this click


# Required methods to implement
func highlight() -> void:
	print("[%.2f] PatternButton %d highlight() called, current_state: %s" % [Time.get_ticks_msec() / 1000.0, button_id, ButtonState.keys()[current_state]])
	
	# Store the previous state to restore after highlighting
	var previous_state = current_state
	current_state = ButtonState.HIGHLIGHTED
	
	# Visually highlight the button by making it brighter (even if disabled)
	if color_rect:
		color_rect.color = bright_color
		print("[%.2f] PatternButton %d set to bright color: %s" % [Time.get_ticks_msec() / 1000.0, button_id, str(bright_color)])
	
	# Reset after highlight duration
	await get_tree().create_timer(highlight_duration).timeout
	print("[%.2f] PatternButton %d highlight timeout, restoring previous state: %s" % [Time.get_ticks_msec() / 1000.0, button_id, ButtonState.keys()[previous_state]])
	
	# Restore previous state and visual appearance
	current_state = previous_state
	if color_rect:
		color_rect.color = dimmed_color
		print("[%.2f] PatternButton %d restored to dimmed color: %s" % [Time.get_ticks_msec() / 1000.0, button_id, str(dimmed_color)])

func press() -> void:
	if current_state == ButtonState.DISABLED:
		return
	
	current_state = ButtonState.PRESSED
	
	# Visually show press feedback by making it bright
	if color_rect:
		color_rect.color = bright_color
	
	# Emit pressed signal
	emit_signal("pressed", button_id)
	
	# Automatically return to dimmed color after a short duration
	await get_tree().create_timer(0.2).timeout
	reset()

func reset() -> void:
	print("[%.2f] PatternButton %d reset() called" % [Time.get_ticks_msec() / 1000.0, button_id])
	current_state = ButtonState.IDLE
	
	# Reset visual appearance to dimmed color
	if color_rect:
		color_rect.color = dimmed_color
		print("[%.2f] PatternButton %d set to dimmed color: %s" % [Time.get_ticks_msec() / 1000.0, button_id, str(dimmed_color)])

func set_enabled(enabled: bool) -> void:
	if enabled:
		if current_state == ButtonState.DISABLED:
			current_state = ButtonState.IDLE
			if color_rect:
				color_rect.color = dimmed_color # Ensure it's dimmed when re-enabled
	else:
		current_state = ButtonState.DISABLED
		if color_rect:
			color_rect.color = dimmed_color # Ensure it's dimmed when disabled
	
	# The `mouse_filter` property already handles clickability.
	# No visual change for enabled/disabled state here, other than dimming.