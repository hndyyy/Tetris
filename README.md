# Tetris FPGA Implementation

A complete Tetris game implementation on Basys3 FPGA board using Verilog HDL. This project features VGA output, PS/2 keyboard input, and seven-segment display for score tracking.

## Project Overview

This project implements a fully functional Tetris game on the Basys3 FPGA development board. The game includes all standard Tetris features including piece rotation, line clearing, scoring, and game-over detection.

## Features

- **VGA Display**: 640x480 VGA output with custom game grid rendering
- **PS/2 Keyboard Input**: Full keyboard control support
  - Arrow Keys: Move pieces (Left, Right, Down)
  - Up Arrow: Rotate pieces
  - P Key: Pause/Resume game
  - R Key: Reset game
- **Seven-Segment Display**: Real-time score display
- **Game Mechanics**:
  - Seven different Tetromino pieces (O, I, S, Z, L, J, T)
  - Piece rotation with collision detection
  - Automatic piece descent
  - Line clearing and scoring
  - Game over detection

## Hardware Requirements

- **FPGA Board**: Basys3 (Artix-7)
- **Display**: VGA-compatible monitor
- **Input**: PS/2 keyboard
- **Development Tools**: Xilinx Vivado Design Suite

## Project Structure

```
project_tetris.srcs/
├── sources_1/new/
│   ├── Tetris_top.v       # Top-level module
│   ├── tetris_main.v      # Core game logic
│   ├── tetris_vga2.v      # VGA controller
│   ├── tetris_seg.v       # Seven-segment display controller
│   ├── key_input.v        # PS/2 keyboard interface
│   └── debouncer.v        # Input debouncing
└── constrs_1/new/
    └── Basys3_Master.xdc  # Pin constraints
```

## Module Descriptions

### Tetris_top.v
Top-level module that integrates all components:
- Instantiates keyboard input handler
- Maps keyboard signals to game controls
- Connects game logic to VGA display
- Manages seven-segment display output

### tetris_main.v (533 lines)
Core game engine implementing:
- Tetromino piece generation and management
- Grid state management (settled and active pieces)
- Collision detection
- Line clearing algorithm
- Score calculation
- Game state machine (start, playing, game over, paused)
- Automatic piece descent timing

### tetris_vga2.v (186 lines)
VGA controller featuring:
- 640x480 @ 60Hz video signal generation
- Game grid rendering (10x20 grid)
- Dual-buffer support for active and settled pieces
- Color-coded display (cyan for active, purple for settled)
- Border and margin rendering

### key_input.v (217 lines)
PS/2 keyboard interface:
- PS/2 protocol implementation
- Scancode decoding
- Key press/release detection
- Debounced input handling
- Support for arrow keys, P, and R keys

### tetris_seg.v
Seven-segment display driver:
- BCD to 7-segment conversion
- Score display across 4 digits
- Multiplexed display control

### debouncer.v
Generic debouncing module for stable input signals

## Pin Assignments

### Clock and PS/2
- Clock: W5 (100MHz)
- PS/2 Clock: C17
- PS/2 Data: B17

### VGA Output
- HSync: P19
- VSync: R19
- Red[2:0]: G19, H19, J19
- Green[2:0]: J17, H17, G17
- Blue[1:0]: N18, L18

### Seven-Segment Display
- Segments[7:0]: W7, W6, U8, V8, U5, V5, U7, V7
- Anodes[3:0]: U2, U4, V4, W4

## Game Controls

- **Left Arrow**: Move piece left
- **Right Arrow**: Move piece right
- **Down Arrow**: Soft drop (faster descent)
- **Up Arrow**: Rotate piece clockwise
- **P Key**: Pause/Resume game
- **R Key**: Reset game

## Technical Specifications

- **Clock Frequency**: 100 MHz
- **VGA Resolution**: 640x480 @ 60Hz
- **Game Grid**: 10 columns × 20 rows
- **Piece Types**: 7 Tetrominoes with 1-4 rotation states each
- **Score Display**: 4-digit seven-segment display
- **Automatic Descent**: Configurable tick threshold (TICK_THRESHOLD = 0x02FFFFFF)

## Tetromino Pieces

The game implements all seven standard Tetromino pieces:
1. **O-piece**: 2×2 square (1 rotation state)
2. **I-piece**: 4×1 line (2 rotation states)
3. **S-piece**: S-shaped (2 rotation states)
4. **Z-piece**: Z-shaped (2 rotation states)
5. **L-piece**: L-shaped (4 rotation states)
6. **J-piece**: J-shaped (4 rotation states)
7. **T-piece**: T-shaped (4 rotation states)

## Build Instructions

1. Open Vivado Design Suite
2. Open project file: `project_tetris.xpr`
3. Run Synthesis (Synth Design)
4. Run Implementation (Run Implementation)
5. Generate Bitstream
6. Program Device via Hardware Manager

## Implementation Results

- **Target Device**: xc7a35tcpg236-1 (Basys3)
- **Logic Utilization**: Available in synthesis reports
- **Timing**: Meets timing constraints for 100MHz operation
- **Bitstream**: Generated in `project_tetris.runs/impl_1/Tetris_top.bit`

## Game States

1. **Start Screen**: Initial state before game begins
2. **Playing**: Active gameplay
3. **Paused**: Game paused (press P to resume)
4. **Game Over**: When pieces reach the top of the grid

## Scoring System

- Points awarded for clearing lines
- Score displayed in real-time on seven-segment display
- Score resets on game restart

## Future Enhancements

Potential improvements:
- Level progression with increasing speed
- Next piece preview
- High score tracking
- Sound effects via audio output
- Enhanced graphics and animations

## Development Notes

- Built and tested on Basys3 Rev B board
- Uses Vivado's behavioral simulation for verification
- Implements proper clock domain crossing for PS/2 input
- VGA timing meets VESA 640x480 @ 60Hz standard

## Authors

DLD Final Project - Tetris Implementation

## License

Educational project for Digital Logic Design course.

## Acknowledgments

- Xilinx Vivado Design Suite
- Basys3 Reference Manual
- VGA timing specifications from VESA standards
