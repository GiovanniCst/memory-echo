extends Node

# Signals for UI updates
signal score_updated(new_score: int)
signal round_updated(new_round: int)
signal lives_updated(new_lives: int)
signal status_message_updated(new_message: String)
# Signals for game flow
signal pattern_generated()
signal pattern_played()
signal player_input_correct()
signal player_input_incorrect()
signal game_over()
signal play_button_sound(button_id: int)
# Removed: signal error_sound_played() - now handled directly

# Game state variables
var score: int = 0
var current_round: int = 1
var lives: int = 3
var status_message: String = "Press Enter (or spacebar) to start the game"

# Game flow variables
enum GameState { WAITING_FOR_START, SHOWING_PATTERN, WAITING_FOR_INPUT, GAME_OVER }
var current_state: GameState = GameState.WAITING_FOR_START

# Pattern variables
var pattern: Array = []
var player_input: Array = []
var current_pattern_index: int = 0

# Reference to pattern buttons
var pattern_buttons: Array = []
@onready var note_player = get_node("/root/Main").get_node("NotePlayer") # Reference to NotePlayer

var is_attracting: bool = false # New variable for attract mode

func _ready():
	# For demonstration, emit initial values
	emit_signal("score_updated", score)
	emit_signal("round_updated", current_round)
	emit_signal("lives_updated", lives)
	emit_signal("status_message_updated", status_message)
	
	start_attract_mode() # Start attract mode when the game loads

func update_score(points: int):
	score += points
	emit_signal("score_updated", score)

func next_round():
	current_round += 1
	emit_signal("round_updated", current_round)

func lose_life():
	lives -= 1
	emit_signal("lives_updated", lives)

func set_status_message(message: String):
	status_message = message
	emit_signal("status_message_updated", status_message)

# Core game logic methods
func start_game():
	print("[%s] GameManager.start_game() called" % str(Time.get_ticks_msec() / 1000.0).pad_decimals(2))
	is_attracting = false # Stop attract mode
	current_state = GameState.SHOWING_PATTERN
	generate_pattern()
	play_pattern()

func generate_pattern():
	pattern.clear()
	player_input.clear()
	current_pattern_index = 0
	
	# Generate a pattern of length equal to the current round
	for i in range(current_round):
		var button_id = randi() % pattern_buttons.size()
		# Ensure no consecutive repeats
		if pattern.size() > 0 and pattern[pattern.size() - 1] == button_id:
			# If the last button is the same, pick a different one
			button_id = (button_id + 1) % pattern_buttons.size()
		pattern.append(button_id)
	
	emit_signal("pattern_generated")

func play_pattern():
	if current_state != GameState.SHOWING_PATTERN:
		return
	
	emit_signal("status_message_updated", "Watch the pattern!")
	print("[%.2f] GameManager.play_pattern() - Showing pattern: %s" % [Time.get_ticks_msec() / 1000.0, str(pattern)])
	set_buttons_enabled(false) # Disable buttons during pattern playback
	
	# Play each button in the pattern with a delay
	for i in range(pattern.size()):
		var button_id = pattern[i]
		if button_id >= 0 and button_id < pattern_buttons.size():
			var button = pattern_buttons[button_id]
			if button:
				# Emit signal to play sound for this button
				emit_signal("play_button_sound", button_id)
				button.highlight()
				# Wait for the highlight duration plus inter-step delay
				print("[%.2f] GameManager.play_pattern() - Highlighting button %d" % [Time.get_ticks_msec() / 1000.0, button_id])
				await get_tree().create_timer(button.highlight_duration + 0.4).timeout
	
	# Add a short delay after pattern playback before player's turn
	await get_tree().create_timer(0.01).timeout # Reduced pause to 0.01 seconds for immediate flash
	
	current_state = GameState.WAITING_FOR_INPUT
	emit_signal("pattern_played")
	emit_signal("status_message_updated", "Your turn!")
	print("[%.2f] GameManager.play_pattern() - Player turn starts" % (Time.get_ticks_msec() / 1000.0))
	# Signal player's turn with a quick flash of all buttons
	await flash_all_buttons()
	
	set_buttons_enabled(true) # Enable buttons for player input

func handle_player_input(button_id: int):
	print("[%.2f] GameManager.handle_player_input() called with button_id: %d" % [Time.get_ticks_msec() / 1000.0, button_id])
	print("[%.2f] Current state: %s" % [Time.get_ticks_msec() / 1000.0, GameState.keys()[current_state]])
	print("[%.2f] Expected pattern: %s" % [Time.get_ticks_msec() / 1000.0, str(pattern)])
	print("[%.2f] Player input so far: %s" % [Time.get_ticks_msec() / 1000.0, str(player_input)])
	print("[%.2f] Current pattern index: %d" % [Time.get_ticks_msec() / 1000.0, current_pattern_index])
	
	if current_state != GameState.WAITING_FOR_INPUT:
		print("[%.2f] WARNING: Ignoring input - not in WAITING_FOR_INPUT state" % (Time.get_ticks_msec() / 1000.0))
		return
	
	player_input.append(button_id)
	print("[%.2f] Added button %d to player input" % [Time.get_ticks_msec() / 1000.0, button_id])
	
	# Check if the input is correct
	if button_id == pattern[current_pattern_index]:
		print("[%.2f] Correct! Button %d matches pattern[%d]" % [Time.get_ticks_msec() / 1000.0, button_id, current_pattern_index])
		emit_signal("player_input_correct")
		
		# Play the correct button sound
		if note_player and button_id >= 0 and button_id < get_node("/root/Main").note_names.size():
			note_player.play_note(get_node("/root/Main").note_names[button_id])
		
		current_pattern_index += 1
		
		# Check if the entire pattern has been entered correctly
		if current_pattern_index == pattern.size():
			print("[%.2f] Pattern completed! Moving to next round." % (Time.get_ticks_msec() / 1000.0))
			# Player has completed the pattern
			handle_pattern_completed()
		else:
			print("[%.2f] Waiting for next input. Progress: %d/%d" % [Time.get_ticks_msec() / 1000.0, current_pattern_index, pattern.size()])
	else:
		print("[%.2f] Wrong! Button %d doesn't match expected %d" % [Time.get_ticks_msec() / 1000.0, button_id, pattern[current_pattern_index]])
		# Player made a mistake
		emit_signal("player_input_incorrect")
		
		# Play the error sound instead of the button note
		if note_player:
			note_player.play_error_sound()
		
		handle_player_mistake()

func handle_pattern_completed():
	print("[%.2f] GameManager.handle_pattern_completed() called" % (Time.get_ticks_msec() / 1000.0))
	# Update score
	var points = 10 * current_round
	score += points
	emit_signal("score_updated", score)
	
	emit_signal("status_message_updated", "Round %d Complete!" % current_round)
	print("[%.2f] Round %d Complete!" % [Time.get_ticks_msec() / 1000.0, current_round])
	await get_tree().create_timer(1.0).timeout # 1 second pause
	
	# Move to next round
	next_round()
	
	# Generate and play new pattern
	current_state = GameState.SHOWING_PATTERN
	generate_pattern()
	play_pattern()

func handle_player_mistake():
	print("[%.2f] GameManager.handle_player_mistake() called" % (Time.get_ticks_msec() / 1000.0))
	lives -= 1
	emit_signal("lives_updated", lives)
	
	if lives <= 0:
		# Game over
		current_state = GameState.GAME_OVER
		emit_signal("game_over")
		emit_signal("status_message_updated", "Game Over!")
		print("[%.2f] Game Over!" % (Time.get_ticks_msec() / 1000.0))
		set_buttons_enabled(false) # Disable buttons on game over
		start_attract_mode() # Restart attract mode
	else:
		emit_signal("status_message_updated", "Wrong! Try again.")
		print("[%.2f] Wrong! Lives remaining: %d" % [Time.get_ticks_msec() / 1000.0, lives])
		# Allow visual feedback to complete before disabling buttons
		await get_tree().create_timer(0.3).timeout # Wait for button press visual feedback
		set_buttons_enabled(false) # Disable buttons during "Wrong!" message
		await get_tree().create_timer(0.7).timeout # Remaining pause time
		
		# Reset for current round
		player_input.clear()
		current_pattern_index = 0
		current_state = GameState.SHOWING_PATTERN
		emit_signal("status_message_updated", "Watch the pattern!") # Reset status message
		play_pattern()

func set_buttons_enabled(enabled: bool):
	for button in pattern_buttons:
		if button:
			button.set_enabled(enabled)
	print("[%.2f] Buttons enabled: %s" % [Time.get_ticks_msec() / 1000.0, str(enabled)])

func flash_all_buttons():
	print("[%.2f] GameManager.flash_all_buttons() called" % (Time.get_ticks_msec() / 1000.0))
	var flash_duration = 0.05 # Quicker flash duration
	var num_flashes = 3 # Flash three times
	
	for n in range(num_flashes):
		# Make all buttons bright
		for button in pattern_buttons:
			if button:
				button.color_rect.color = button.bright_color
		
		await get_tree().create_timer(flash_duration).timeout
		
		# Dim all buttons
		for button in pattern_buttons:
			if button:
				button.color_rect.color = button.dimmed_color
		
		if n < num_flashes - 1: # Don't delay after the last dim
			await get_tree().create_timer(flash_duration).timeout # Small delay between flashes
		
# These functions should be at the top level, not nested.
func start_attract_mode():
	print("[%.2f] GameManager.start_attract_mode() called" % (Time.get_ticks_msec() / 1000.0))
	current_state = GameState.WAITING_FOR_START
	emit_signal("status_message_updated", "Press Enter (or spacebar) to start the game")
	is_attracting = true
	_attract_mode_loop() # Start the coroutine

func _attract_mode_loop():
	print("[%.2f] GameManager._attract_mode_loop() started" % (Time.get_ticks_msec() / 1000.0))
	while is_attracting:
		if pattern_buttons.is_empty():
			await get_tree().create_timer(0.1).timeout # Wait for buttons to be instantiated
			continue
		
		var num_buttons_to_highlight = randi_range(1, 3) # Highlight 1 to 3 buttons
		var highlighted_buttons = []
		
		for _i in range(num_buttons_to_highlight):
			var random_button_id = randi() % pattern_buttons.size()
			var button = pattern_buttons[random_button_id]
			
			if button and not highlighted_buttons.has(button):
				button.highlight() # This handles the bright/dim cycle
				highlighted_buttons.append(button)
		
		var random_delay = randf_range(0.3, 0.8) # Random delay between patterns
		await get_tree().create_timer(random_delay).timeout
	print("[%.2f] GameManager._attract_mode_loop() stopped" % (Time.get_ticks_msec() / 1000.0))
