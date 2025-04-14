# 4 Character Fighting Game on Basys 3 FPGA

A 4 player fighting game implemented on two Basys 3 FPGA boards. Players control characters (Mage, Gunman, Swordman, Fistman) in a VGA-displayed arena, attacking each other with normal and ultimate projectiles. Real-time visuals, audio feedback, and gameplay interactions are handled via hardware modules and inter-board communication.

---

## 🕹 Gameplay Overview

- **2 Players per Basys 3**: 
  - Player 1: `WASD` to move, `Spacebar` to attack, `E` for ultimate
  - Player 2: Arrow keys to move, `Numpad 0` to attack, `Numpad .` for ultimate
- **Each character has different**: 
  - Health, projectile range, movement speed, projectile speed
- **Attacks**: 
  - Normal attack: 1 damage
  - Ultimate attack: 2 damage (can only be used when charge meter is full)
- **Collisions**: 
  - Characters can’t pass through each other
  - Projectiles destroyed on impact or when out of range

---

## 🎮 User Interface

- **Character Display**: OLED (1 per player)
- **Health Display**: 7-Segment Display
- **Ultimate Charge Meter**: 
  - P1: LEDs LD15 to LD8
  - P2: LEDs LD7 to LD0
- **Audio**: Pmod AMP2 used to play character-specific projectile sounds
- **Reset**: BTNC resets the game

---

## 🖥 VGA Arena Display

- **Rendered at 640x480**
- Displays arena, character sprites, projectiles, and Game Over screen
- Uses **2x2 Bayer dithering** to simulate higher color depth from 320x240 6-bit images

---

## 🧠 Game Logic

- **Movement & Collision**:
  - Character movement bounded by arena edges
  - Direction tracked for accurate projectile firing
  - Anti-collision logic prevents overlapping characters

- **Projectiles**:
  - Moves in direction character was facing on fire
  - Destroyed on:
    - Collision with character
    - Leaving screen
    - Exceeding character-specific range

- **Ultimate Meter**:
  - Charges faster with lower health
  - Blinks when fully charged
  - Can only fire one ultimate at a time

- **Health System**:
  - Starts with character-specific values
  - Reduced on projectile hit
  - When health = 0:
    - Character becomes a tombstone
    - Cannot move or attack

---

## 🔄 Game States

- **Normal**: All players active
- **Dead**: Character replaced by tombstone
- **Game Over**: Displayed when only one character remains
- **Reset**: BTNC brings game back to initial state

---

## 🔗 Master-Peripheral Setup

- **SW15**: Set as Master (ON) or Peripheral (OFF)
- **Master Board**:
  - Renders VGA arena
  - Syncs character states, handles game logic
- **Peripheral Board**:
  - Sends player input (10-bit wire)
  - Receives player health (8-bit wire)
  - Updates OLED, LEDs, 7-seg displays

---

## 🖼 Sprite & Image Management

- **20+ Custom Sprites**: 20x20 px for characters, projectiles, UI
- **Python Script**: Converts PNGs to 18-bit RGB .mem files for BRAM usage
- **BRAM-based Sprite Rendering**:
  - Fetches pixel data for display on VGA
  - Includes tombstone, projectiles, and Game Over background

---

## 🔧 Hardware Interfaces Used

- VGA Display (Arena visuals)
- USB Keyboard (PS2 protocol)
- Pmod AMP2 (Audio)
- OLED Screen (Character display)
- 7-Segment (Health)
- On-board LEDs (Ultimate charge)
- Inter-board GPIO for sync

---

## 📌 Notes

- Movement direction always updated to latest key press
- Sound effects unique per character for immersive feedback

---

## 🚀 Reset & Replay

- Game automatically ends when 3 characters die
- Press BTNC to reset game to initial state
