# 4 Character Fighting Game on Basys 3 FPGA

A 4 player fighting game implemented on two Basys 3 FPGA boards. Players control characters (Mage, Gunman, Swordman, Fistman) in a VGA-displayed arena, attacking each other with normal and ultimate projectiles. Real-time visuals, audio feedback, and gameplay interactions are handled via hardware modules and inter-board communication.
![176EFCD7-4457-4A75-88D4-EC2B83326265_1_105_c](https://github.com/user-attachments/assets/e492c1ed-8ffa-4db0-a041-84be8155c4d9)
![D127073D-22A5-4AF5-9443-972EEB6B1D31_1_105_c](https://github.com/user-attachments/assets/8649c9c0-547c-4ed4-9405-3cc9ccece397)
![279BE992-8F45-435F-A185-BE0A094AD7B8_1_105_c](https://github.com/user-attachments/assets/59f17532-4268-4b09-86ef-2f465a0a9b9b)
![08D987A2-CEE5-43A1-A77F-8765A7F797E8_1_105_c](https://github.com/user-attachments/assets/13006d42-945b-4193-9c84-8211bd7194b0)
![FB9DA369-4465-4390-8E4F-4C3EC7CB7618_1_105_c](https://github.com/user-attachments/assets/f88fb4e8-950e-48f8-a648-743891f5935f)


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
