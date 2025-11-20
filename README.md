# 🎧 Data Sonification System – Processing + Pure Data

## 📌 Project Description

This project implements an **interactive data sonification system** that combines visualization in Processing with sound synthesis in Pure Data.  
Using a public **IMDb dataset**, the system generates:

- **Dynamic falling shapes** that represent IMDb entries  
- **Corresponding musical tones** based on dataset values  
- **User interaction** through keyboard-controlled lanes  
- **Audio feedback** for correct hits, mistakes, and level progress  

The goal is to merge **visual** and **auditory** dimensions into an immersive experience where real dataset information shapes both the graphics and the sound.

A demonstration video is available here:  
👉 **https://drive.google.com/drive/folders/18h_N8yjGZJwkYfObAzbfqknR6fuHx7ym?usp=sharing**

---

## 📊 Dataset Used (IMDb Data CSV)

The project uses a public dataset downloaded from Kaggle:  
**IMDb Data CSV**, containing metadata about thousands of films and TV productions.

Relevant fields and their usage:

| Field | Usage in the project |
|-------|-----------------------|
| `titleType` | Determines **shape type** (circle, triangle, star, square, etc.) |
| `genres` | Determines **background color** and **shape color** |
| `startYear` | Converted into **musical frequency** |
| `runtimeMinutes` | Maps to **falling speed** or lane index |
| `isAdult` | Determines **color intensity** of shapes |

Each dataset entry becomes a unique **audiovisual event**.

---

## 🎨 Visualization in Processing

Processing handles:

### 1. **Shape generation based on titleType**
Examples:

- `movie` → circle  
- `short` → triangle  
- `tvSeries` → square  
- `tvEpisode` → star  
- others → diamond / custom polygons  

### 2. **Color generation using genres**

- Action → red  
- Comedy → yellow  
- Drama → purple  
- Horror → black/red  
- Romance → pink  
- Sci-Fi → cyan  
- Documentary → green  
- Animation → orange  
- Others → gray  

Colors apply to both the **shapes** and **background levels**.
lane = runtimeMinutes % 6
This distributes shapes across 6 lanes.

### 4. **Musical frequency generation**
frequency = map(startYear, 1900, 2025, 200Hz, 1200Hz)


### 5. **User interaction**
Keys **1–6** correspond to the 6 lanes.  
- Hitting a shape → **correct sound**  
- Pressing without a shape → **error sound**  
- Every 10 correct hits → **level up**  

---

## 🎵 Sound Generation in Pure Data

Processing sends OSC messages to Pure Data:

### OSC Routes
- `/notaCorrecta` → frequency for successful hit  
- `/notaIncorrecta` → error tone (derived from the pressed lane)  
- `/nextLevel` → celebratory level-up sound  

---

## 🔄 Visual–Auditory Interaction

The system ensures real-time interaction between data, visuals, and sound:

- Falling shapes come from IMDb dataset entries  
- Keyboard input validates timing  
- Sounds reflect performance:
  - correct hit  
  - incorrect hit  
  - level-up  
- Background colors evolve with levels  
- The **year** of the title defines tone pitch  
- The **genre** defines color  
- The **format (titleType)** defines geometric shape  

This turns raw metadata into an interactive audiovisual experience.

---

## 🛠️ Project Requirements

### Software:
- **Processing 4.4+**
- **Pure Data Vanilla (0.56.1)**

