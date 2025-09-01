# Specifiche implementazione audio e layout bottoni per Simon Says (Godot)

## Obiettivo
Integrare nel gioco **Simon Says** 5 bottoni, ciascuno associato a una nota della scala pentatonica maggiore di Do. Le note devono essere generate proceduralmente in Godot, senza file audio esterni, con un suono "gamey" e piacevole.

## Layout bottoni
- I bottoni dovranno essere **5** in totale.
- Disposizione: **4 quadrati ai lati** (su, giù, sinistra, destra) che circondano un **quinto quadrato centrale**.
- Ogni bottone è collegato a una delle 5 note della scala pentatonica.

## Note utilizzate
Scala pentatonica maggiore di Do (ottava centrale):
- Do (C) → 261.63 Hz
- Re (D) → 293.66 Hz
- Mi (E) → 329.63 Hz
- Sol (G) → 392.00 Hz
- La (A) → 440.00 Hz

## Codice GDScript
Creare uno script (es. `NotePlayer.gd`) e collegarlo a un nodo principale del gioco.

```gdscript
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
        return
    
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
```

## Integrazione nel gioco
1. Aggiungere un nodo (es. `NotePlayer`) alla scena principale.
2. Allegare lo script `NotePlayer.gd` al nodo.
3. Creare 5 bottoni con layout a croce (4 quadrati esterni + 1 quadrato centrale).
4. Collegare ciascun bottone del gioco a una nota:
   - Bottone 1 (alto) → `play_note("C")`
   - Bottone 2 (sinistra) → `play_note("D")`
   - Bottone 3 (destra) → `play_note("E")`
   - Bottone 4 (basso) → `play_note("G")`
   - Bottone 5 (centro) → `play_note("A")`

   Esempio:
   ```gdscript
   func _on_Button1_pressed():
       $NotePlayer.play_note("C")
   ```

5. Facoltativo: sincronizzare animazioni o effetti visivi dei bottoni con la chiamata a `play_note` per aumentare il feedback visivo-sonoro.

## Risultato atteso
- Sempre 5 bottoni disposti in croce (4 attorno a uno centrale).
- Ogni bottone suona una nota intonata della scala pentatonica.
- Il suono è "gamey" e arcade (misto sine+saw, vibrato, envelope ADSR).
- Le sequenze del Simon Says risultano musicali e piacevoli da ascoltare.

