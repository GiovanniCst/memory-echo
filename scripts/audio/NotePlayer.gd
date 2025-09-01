extends Node

# Pentatonica maggiore di Do
const NOTES = {
    "C": 261.63,   # Do
    "D": 293.66,   # Re
    "E": 329.63,   # Mi
    "G": 392.00,   # Sol
    "A": 440.00    # La
}

# Parametri suono
const NOTE_DURATION = 0.5   # durata max nota (s)
const ATTACK = 0.03         # attacco (s)
const DECAY = 0.1           # decadimento (s)
const SUSTAIN = 0.7         # livello sustain (0–1)
const RELEASE = 0.25        # rilascio (s)
const VIBRATO_FREQ = 6.0    # Hz
const VIBRATO_DEPTH = 0.01  # deviazione di frequenza (in %)

var generator
var playback

func _ready():
    generator = AudioStreamGenerator.new()
    generator.mix_rate = 44100
    generator.buffer_length = 0.5
    
    var player = AudioStreamPlayer.new()
    player.stream = generator
    add_child(player)
    player.play()
    
    playback = player.get_stream_playback()

func play_note(note_name: String):
    if not NOTES.has(note_name):
        print("[%.2f] NotePlayer: Invalid note name: %s" % [Time.get_ticks_msec() / 1000.0, note_name])
        return
    
    print("[%.2f] NotePlayer: Playing note %s" % [Time.get_ticks_msec() / 1000.0, note_name])
    var base_freq = NOTES[note_name]
    var frames = int(NOTE_DURATION * generator.mix_rate)
    var phase = 0.0

    for i in range(frames):
        var t = float(i) / generator.mix_rate

        # Vibrato
        var freq_mod = 1.0 + VIBRATO_DEPTH * sin(TAU * VIBRATO_FREQ * t)
        var phase_step = TAU * base_freq * freq_mod / generator.mix_rate

        # Mix Sawtooth + Sine
        var sine_wave = sin(phase)
        var saw_wave = (fmod(phase / TAU, 1.0) * 2.0 - 1.0)
        var sample = 0.6 * sine_wave + 0.4 * saw_wave

        # Envelope ADSR
        var amp = 1.0
        if t < ATTACK:
            amp = t / ATTACK
        elif t < ATTACK + DECAY:
            var decay_t = (t - ATTACK) / DECAY
            amp = lerp(1.0, SUSTAIN, decay_t)
        elif t < NOTE_DURATION - RELEASE:
            amp = SUSTAIN
        else:
            var release_t = (t - (NOTE_DURATION - RELEASE)) / RELEASE
            amp = lerp(SUSTAIN, 0.0, release_t)

        sample *= amp * 0.3
        playback.push_frame(Vector2(sample, sample))

        phase += phase_step

func play_error_sound():
    print("[%.2f] NotePlayer: Playing error sound" % (Time.get_ticks_msec() / 1000.0))
    var error_freq = 150.0
    var error_duration = 0.6
    var frames = int(error_duration * generator.mix_rate)
    var phase = 0.0
    var phase_step = TAU * error_freq / generator.mix_rate

    for i in range(frames):
        var t = float(i) / generator.mix_rate

        # Sawtooth wave (più fastidiosa del sine → suono da errore)
        var saw_wave = (fmod(phase / TAU, 1.0) * 2.0 - 1.0)
        var sample = saw_wave

        # Envelope semplice: attacco breve + rilascio morbido
        var amp = 1.0
        if t < 0.02: # attack molto corto
            amp = t / 0.02
        elif t > error_duration - 0.1: # release più lungo
            amp = (error_duration - t) / 0.1

        sample *= amp * 0.4  # volume bilanciato
        playback.push_frame(Vector2(sample, sample))

        phase += phase_step
