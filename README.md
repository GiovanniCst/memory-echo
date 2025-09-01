# Memory Echo

A pattern memory/rhythm game inspired by the classic Simon electronic game, developed with Godot Engine 4.4.

## Table of Contents

- [Memory Echo](#memory-echo)
  - [Table of Contents](#table-of-contents)
  - [Game Overview](#game-overview)
  - [Features](#features)
  - [Technical Details](#technical-details)
  - [Controls](#controls)
  - [How to Run](#how-to-run)
  - [Audio Implementation](#audio-implementation)
  - [File Structure](#file-structure)
  - [Development Timeline](#development-timeline)
  - [License](#license)

## Game Overview

Memory Echo challenges players to observe and replicate sequences of colored lights and corresponding sounds. The game starts with short patterns that gradually increase in length and complexity, testing the player's memory and rhythm.

## Features

### Core Gameplay
- **Pattern System**: Sequences increase in length each round (up to 20 steps). Random pattern generation ensures no consecutive repeating elements.
- **Visual Feedback**: 5 colored buttons (Red, Blue, Green, Yellow, Purple, Orange) with visual highlights and scaling animations on press.
- **Audio System**: Unique, procedurally generated tones for each button, based on the C major pentatonic scale, with a "gamey" sound profile (sine+saw mix, vibrato, ADSR envelope).
- **Input Validation**: Real-time feedback on correct/incorrect inputs, with game over on the first mistake.

### Progression & Scoring
- **Score Calculation**: Points awarded per correct step, with multipliers for sequence length and bonus points for perfect rounds.
- **Difficulty Progression**: Speed of pattern playback increases with rounds (Normal, Fast, Very Fast).
- **Lives System**: 3 lives, game over when all are lost.

### Optional Advanced Features (Planned)
- **AI-Powered Adaptive Difficulty**: Adjusts timing based on player performance.
- **Pattern Analysis**: AI suggests optimal memorization strategies.
- **Procedural Audio**: AI-generated unique tones for each session.
- **Smart Hints**: Context-aware assistance for struggling players.

## Technical Details

- **Engine**: Godot Engine 4.4+
- **Rendering**: GL Compatibility renderer
- **Autoload**: `GameManager.gd` for global game state management.

## Controls

The game uses keyboard inputs for the five buttons:

- **Top Button**: `W`
- **Bottom Button**: `X`
- **Central Button**: `S`
- **Right Button**: `D`
- **Left Button**: `A`
- **Start Game**: `Spacebar` or `Enter`

## How to Run

1.  **Download Godot Engine**: Ensure you have Godot Engine 4.4 or later installed. You can download it from the [official Godot website](https://godotengine.org/download/).
2.  **Clone the Repository**:
    ```bash
    git clone https://github.com/GiovanniCst/memory-echo.git
    cd memory-echo
    ```
3.  **Open in Godot**: Open the Godot Engine, click "Import", and select the `project.godot` file from the cloned repository.
4.  **Run the Project**: Once the project is open in the editor, press `F5` or the "Play" button to run the game.

## Audio Implementation

The game features a unique procedural audio system for button sounds, utilizing the C major pentatonic scale:

-   **Notes**: C (261.63 Hz), D (293.66 Hz), E (329.63 Hz), G (392.00 Hz), A (440.00 Hz).
-   **Sound Generation**: Uses `AudioStreamGenerator` to create a mix of sawtooth and sine waves with vibrato and an ADSR envelope for a distinct "gamey" sound.
-   **Button Mapping**:
    -   Top Button: `C`
    -   Left Button: `D`
    -   Right Button: `E`
    -   Bottom Button: `G`
    -   Center Button: `A`

## File Structure

```
res://
├── scenes/
│   ├── main/           # Main game scene and script
│   ├── game/           # Game board and pattern button components
│   └── ui/             # User interface scenes (Main Menu, HUD)
├── scripts/
│   ├── managers/       # Game management, audio management
│   └── audio/          # NotePlayer script for procedural audio
├── static/             # Static assets like images
├── .editorconfig
├── .gitattributes
├── .gitignore
├── game_doc.txt        # Detailed game design document
├── icon.svg            # Project icon
├── project.godot       # Godot project configuration
└── simon_says_audio.md # Audio implementation specifications
```

## License

This project is open-source and available under the [MIT License](LICENSE).