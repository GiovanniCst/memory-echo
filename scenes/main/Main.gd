extends Node2D

# Preload the PatternButton scene
const PatternButtonScene = preload("res://scenes/game/PatternButton.tscn")

# Node references
@onready var button_container = $GameBoard/ButtonContainer
@onready var hud = $UI/HUD
@onready var main_menu = $UI/MainMenu
@onready var score_label = null
@onready var round_label = null
@onready var status_label = null
# lives_display is a container, so we'll handle it differently

# Reference to the GameManager singleton
@onready var game_manager = get_node("/root/GameManager")
@onready var note_player = $NotePlayer

# Note mapping for audio playback
var note_names = ["C", "D", "E", "G", "A"]

func _ready():
	print("[%.2f] Main._ready() called" % (Time.get_ticks_msec() / 1000.0))
	# Instance PatternButton scenes and add them to the ButtonGrid
	instance_pattern_buttons()
	
	# Get references to UI elements in the instanced HUD scene
	if hud:
		score_label = hud.get_node("ScoreLabel")
		round_label = hud.get_node("RoundLabel")
		status_label = hud.get_node("StatusLabel")
	
	# Connect to GameManager signals
	if game_manager:
		game_manager.connect("score_updated", update_score_label)
		game_manager.connect("round_updated", update_round_label)
		game_manager.connect("lives_updated", update_lives_display)
		game_manager.connect("status_message_updated", update_status_label)
		game_manager.connect("play_button_sound", on_play_button_sound) # For pattern playback
		
		# Ensure lives are displayed immediately on game start
		update_lives_display(game_manager.lives)
	
	# Connect StartButton and PlayAgainButton signals
	if main_menu:
		var start_button = main_menu.get_node("StartButton")
		if start_button:
			start_button.connect("pressed", start_game)
		
		var play_again_button = main_menu.get_node("PlayAgainButton")
		if play_again_button:
			play_again_button.connect("pressed", restart_game)
	
	# Connect to game_over signal to show Play Again button
	if game_manager:
		game_manager.connect("game_over", on_game_over)

# Removed: Function to handle error sound playback
# func on_error_sound_played():
# 	print("[%.2f] Main.on_error_sound_played() called" % (Time.get_ticks_msec() / 1000.0))
# 	if note_player:
# 		note_player.play_error_sound()

func instance_pattern_buttons():
	print("[%.2f] instance_pattern_buttons() called" % (Time.get_ticks_msec() / 1000.0))
	# Create 5 PatternButton instances in a cross layout
	# Using the pentatonic scale notes from simon_says_audio.md
	var _notes = ["C", "D", "E", "G", "A"]  # Notes for reference, not directly used here
	var colors = [
		{"name": "Top", "color": Color(1, 0, 0)},      # Red for C (Top)
		{"name": "Left", "color": Color(0, 0, 1)},     # Blue for D (Left)
		{"name": "Right", "color": Color(0, 1, 0)},    # Green for E (Right)
		{"name": "Bottom", "color": Color(1, 1, 0)},   # Yellow for G (Bottom)
		{"name": "Center", "color": Color(1, 0, 1)}    # Magenta for A (Center)
	]
	
	# Clear the button container first
	for child in button_container.get_children():
		button_container.remove_child(child)
		child.queue_free()
	
	# Define positions for cross layout for 100x100 buttons within a 300x300 container
	var button_positions = [
		Vector2(100, 0),    # Top (top-left at 100,0)
		Vector2(0, 100),    # Left (top-left at 0,100)
		Vector2(200, 100),  # Right (top-left at 200,100)
		Vector2(100, 200),  # Bottom (top-left at 100,200)
		Vector2(100, 100)   # Center (top-left at 100,100)
	]
	
	# Create 5 buttons
	for i in range(5):
		var button_instance = PatternButtonScene.instantiate()
		button_instance.name = "%sButton" % colors[i]["name"]
		button_instance.button_id = i
		button_instance.button_color = colors[i]["color"]
		button_instance.position = button_positions[i]
		button_container.add_child(button_instance)
		print("[%.2f] Added button: %s at position %s" % [Time.get_ticks_msec() / 1000.0, button_instance.name, str(button_positions[i])])
		
		# Connect the button's input event to handle player input
		button_instance.connect("pressed", on_pattern_button_pressed)
		
		# Add button to GameManager's pattern_buttons array
		if game_manager:
			game_manager.pattern_buttons.append(button_instance)

# UI Update Functions
func update_score_label(new_score: int):
	if score_label:
		score_label.text = "Score: %d" % new_score

func update_round_label(new_round: int):
	if round_label:
		round_label.text = "Round: %d" % new_round

func update_lives_display(new_lives: int):
	print("[%.2f] Updating lives display to: %d" % [Time.get_ticks_msec() / 1000.0, new_lives])
	
	# Get the LivesDisplay container from HUD
	if hud:
		var lives_display = hud.get_node("LivesDisplay")
		if lives_display:
			# Clear existing life indicators
			for child in lives_display.get_children():
				child.queue_free()
			
			# Add life indicators (simple colored rectangles)
			for i in range(new_lives):
				var life_indicator = ColorRect.new()
				life_indicator.custom_minimum_size = Vector2(20, 20)
				life_indicator.color = Color.RED
				lives_display.add_child(life_indicator)
				print("[%.2f] Added life indicator %d" % [Time.get_ticks_msec() / 1000.0, i + 1])

func update_status_label(new_message: String):
	if status_label:
		status_label.text = new_message

# Keyboard input handling
func _input(event):
	if event is InputEventKey and event.is_pressed():
		# Handle game start/restart via keyboard
		if event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_SPACE:
			if main_menu:
				var start_button = main_menu.get_node("StartButton")
				var play_again_button = main_menu.get_node("PlayAgainButton")
				
				if start_button and start_button.visible:
					start_game()
					get_viewport().set_input_as_handled()
					return
				elif play_again_button and play_again_button.visible:
					restart_game()
					get_viewport().set_input_as_handled()
					return
		
		# Only process keyboard input for pattern buttons if the game is in a valid state for player input
		if game_manager and game_manager.current_state != game_manager.GameState.GAME_OVER:
			var button_id_to_press = -1
			match event.physical_keycode:
				KEY_W: # Top button
					button_id_to_press = 0
				KEY_A: # Left button
					button_id_to_press = 1
				KEY_D: # Right button
					button_id_to_press = 2
				KEY_X: # Bottom button
					button_id_to_press = 3
				KEY_S: # Central button
					button_id_to_press = 4
			
			if button_id_to_press != -1:
				_simulate_button_press(button_id_to_press)
				get_viewport().set_input_as_handled() # Prevent other nodes from processing this input

# Helper function to simulate a button press (for both mouse and keyboard)
func _simulate_button_press(button_id: int):
	print("[%.2f] _simulate_button_press() called with button_id: %d" % [Time.get_ticks_msec() / 1000.0, button_id])
	
	# Find the actual PatternButton instance
	var button_instance = null
	for button in game_manager.pattern_buttons:
		if button.button_id == button_id:
			button_instance = button
			break
	
	if button_instance:
		# Visually press the button
		button_instance.press() # This will also emit the "pressed" signal
	else:
		print("[%.2f] ERROR: Could not find PatternButton with id %d" % [Time.get_ticks_msec() / 1000.0, button_id])

# Player input handler (now primarily for mouse clicks, but can be called by keyboard)
func on_pattern_button_pressed(button_id: int):
	print("[%.2f] Main.on_pattern_button_pressed() called with button_id: %d" % [Time.get_ticks_msec() / 1000.0, button_id])
	
	# Removed: Play audio for the button press - now handled by GameManager conditionally
	# if note_player and button_id >= 0 and button_id < note_names.size():
	# 	note_player.play_note(note_names[button_id])
	
	if game_manager:
		print("[%.2f] Calling GameManager.handle_player_input(%d)" % [Time.get_ticks_msec() / 1000.0, button_id])
		game_manager.handle_player_input(button_id)
	else:
		print("[%.2f] ERROR: game_manager is null!" % (Time.get_ticks_msec() / 1000.0))

# Start the game
func start_game():
	if game_manager:
		game_manager.start_game()

# Function to handle button sound playback
func on_play_button_sound(button_id: int):
	print("[%.2f] Main.on_play_button_sound() called with button_id: %d" % [Time.get_ticks_msec() / 1000.0, button_id])
	
	# Play audio for the button highlight
	if note_player and button_id >= 0 and button_id < note_names.size():
		note_player.play_note(note_names[button_id])

# Handle game over event
func on_game_over():
	print("[%.2f] Main.on_game_over() called" % (Time.get_ticks_msec() / 1000.0))
	if main_menu:
		var start_button = main_menu.get_node("StartButton")
		var play_again_button = main_menu.get_node("PlayAgainButton")
		if start_button:
			start_button.visible = false
		if play_again_button:
			play_again_button.visible = true

# Restart the game
func restart_game():
	print("[%.2f] Main.restart_game() called" % (Time.get_ticks_msec() / 1000.0))
	if game_manager:
		# Reset game manager state
		game_manager.score = 0
		game_manager.current_round = 1
		game_manager.lives = 3
		game_manager.pattern.clear()
		game_manager.player_input.clear()
		game_manager.current_pattern_index = 0
		game_manager.current_state = game_manager.GameState.WAITING_FOR_START
		
		# Reset UI
		if main_menu:
			var start_button = main_menu.get_node("StartButton")
			var play_again_button = main_menu.get_node("PlayAgainButton")
			if start_button:
				start_button.visible = true
			if play_again_button:
				play_again_button.visible = false
		
		# Emit initial values to reset UI
		game_manager.emit_signal("score_updated", game_manager.score)
		game_manager.emit_signal("round_updated", game_manager.current_round)
		game_manager.emit_signal("lives_updated", game_manager.lives)
		game_manager.emit_signal("status_message_updated", "Press Enter (or spacebar) to start the game")
		
		# Start new game
		game_manager.start_game()
