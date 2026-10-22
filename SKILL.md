---
name: apple-motion-graphics
description: >-
  Generate broadcast-grade, Apple-inspired 1080p 60fps motion graphics and product launch films.
  Use this skill whenever the user wants to create sophisticated, minimalist product launch videos,
  software feature teasers, 3D exploded interface breakdowns, or cinematic UI showcases with
  Apple's signature dark or light studio aesthetics, pristine San Francisco typography, realistic
  glassmorphism, and synchronized sound design.
---

# Apple-Style Motion Graphics & Product Launch Films

Create cinema-grade, mathematically precise motion graphics inspired by Apple's iconic product launch keynotes and product films. This skill provides an end-to-end procedural system—from visual direction and typography rules to a zero-dependency, high-throughput native rendering engine (800+ fps) that outputs broadcast-quality 1080p 60fps MP4 videos.

---

## 1. Visual Aesthetics & Design System

Apple's product film aesthetic is defined by **restraint, precision, physical believability, and generous negative space**. Avoid generic AI visuals: no cyberpunk neon, no excessive particle swarms, no random falling code, no HUD sci-fi overlays, and no cluttered layouts.

### Theme Modes

| Dimension | Obsidian Dark Mode (`--theme dark`) | Studio Light Mode (`--theme light`) |
| :--- | :--- | :--- |
| **Background Base** | Deep Obsidian Black (`#040407` to `#08080C`) | Warm Pearlescent Studio Gray (`#F5F5F7` to `#EDEDF0`) |
| **Studio Spotlight** | Radial glow: center-top `#121218`, radius `0.85W` | Radial spotlight: center-top `#FFFFFF` to `#E8E8ED` |
| **Primary Typography** | Crisp Soft White (`#F5F5F7` / `#FFFFFF`) | Pitch Charcoal (`#1D1D1F` / `#000000`) |
| **Secondary Typography** | Muted Platinum (`#A1A1A6` / `#86868B`) | Refined Slate (`#6E6E73` / `#86868B`) |
| **Accent Color** | Electric Apple Blue (`#2997FF` / `#0A84FF`) | Deep System Blue (`#0071E3` / `#0077ED`) |
| **Glass Surfaces** | Translucent obsidian fill `rgba(255,255,255,0.05)` | Frosted milk glass fill `rgba(255,255,255,0.92)` |
| **Card Borders** | Specular gradient `rgba(255,255,255,0.25)` to `0.04` | Crisp stroke `rgba(0,0,0,0.08)` to `rgba(0,0,0,0.14)` |
| **Drop Shadows** | Deep directional: `box-shadow: 0 -30px 60px rgba(0,0,0,0.7)` | Ambient studio: `box-shadow: 0 -25px 50px rgba(25,35,55,0.10)` |

### Typography Guidelines
- **Font Family:** Apple San Francisco (`.AppleSystemUIFont` / SF Pro Display & Text).
- **Hero Reveal Titles:** `140pt - 180pt`, Weight: `Bold` or `Heavy`, Kerning: `14.0 - 18.0pt`.
- **Primary Section Headings:** `36pt - 44pt`, Weight: `Bold`, Kerning: `1.0 - 2.0pt`.
- **Subtitles & Explanations:** `18pt - 24pt`, Weight: `Light` or `Regular`, Kerning: `0.8 - 1.2pt`.
- **Category & Step Badges:** `11pt - 14pt`, Weight: `Semibold`, All-Caps, Tracked-out Kerning: `3.0 - 5.0pt`.
- **Negative Space:** Always maintain at least 40% negative breathing room on screen. Every line of text must directly reflect the voiceover narration.

---

## 2. Animation Physics & Camera Choreography

All motion must feel physically grounded, with smooth momentum and natural deceleration.

### Core Easing Curves
- **Standard Apple Deceleration (Ease-Out Cubic):**
  $$f(t) = 1.0 - (1.0 - t)^3$$
- **High-Momentum Settle (Ease-Out Quint):**
  $$f(t) = 1.0 - (1.0 - t)^5$$
- **Cinematic Camera Drift (Ease-In-Out Quad):**
  $$f(t) = \begin{cases} 2t^2 & t < 0.5 \\ 1 - \frac{(-2t + 2)^2}{2} & t \ge 0.5 \end{cases}$$

### Spatial & 3D Layer Techniques
1. **Camera Pushes:** Continuous slow push-in (`scale: 0.95 → 1.04`) or pullback (`scale: 1.04 → 0.98`) to prevent visual stagnation.
2. **3D Orbit:** Gentle yaw rotation (`-8° → +6°`) combined with slight pitch (`+3° → -2°`) using 3D perspective transforms.
3. **Exploded Layer Separation:** Windows separate along the Z-axis into 3–4 distinct floating planes:
   - **Base Canvas:** Window frame and coordinate fabric.
   - **Navigation Tier:** Window header, breadcrumbs, search pills.
   - **Content Modules:** Text blocks, data cards, grid containers.
   - **Interactive Layer:** Active buttons, toggles, and state triggers hovering at the forefront.
4. **Interactive Causality:** Display cause-and-effect with physical realism:
   - Button depresses inward (`translateZ: -6px`) with a soft blue rim illumination.
   - Luminous tracer lines animate smoothly from the action trigger toward the receiving component.
   - A traveling energy pulse moves along the path to initiate the resulting state change (e.g., panel sliding open or checkbox ticking).

---

## 3. High-Performance Rendering Architecture

This skill leverages a **zero-dependency native CoreGraphics rendering pipeline** coupled with FFmpeg hardware encoding.

```
┌───────────────────────────┐      Raw Uncompressed       ┌───────────────────────────┐
│     Native Renderer       │      BGRA 1920x1080         │       FFmpeg 8.0          │
│ (CoreGraphics + AppKit)   │ ──────────────────────────> │   (H.264 / ProRes)        │
│    Throughput: 800+ fps   │         stdout Pipe         │  60 fps Universal MP4     │
└───────────────────────────┘                             └───────────────────────────┘
                                                                        ▲
                                                                        │ Mux
                                                          ┌───────────────────────────┐
                                                          │  Parametric Audio Synth   │
                                                          │   (48kHz Stereo PCM)      │
                                                          └───────────────────────────┘
```

### Why This Outperforms Headless Web Browsers
- **Zero Startup Overhead:** Compiles and starts rendering in <1.5 seconds.
- **800+ Frames Per Second:** Native CoreGraphics renders complex vector layers, gradients, and typography directly in RAM.
- **Direct Pipe to FFmpeg:** Avoids writing thousands of intermediate PNG files to disk, eliminating I/O bottlenecks.
- **Pristine Typography:** Native subpixel antialiasing and kerning using macOS `.AppleSystemUIFont`.

---

## 4. Step-by-Step Production Runbook

### Step 1: Shot List & Narration Alignment
Divide the script into distinct 4–8 second shots. Calculate exact frame boundaries at 60 fps:
- Shot duration (seconds) $\times 60 = \text{Frame Count}$.
- Example: 6.0s = 360 frames, 8.0s = 480 frames.

### Step 2: Configure Visual Theme & Elements
Choose between **Dark Mode** (for technical reveals, tool launches, core engines) and **Light Mode** (for productivity tools, workflows, conclusions, and tutorials).

### Step 3: Preview Keyframes
Use the instant preview tool to inspect individual frames without waiting for the full video render:
```bash
./scripts/preview.sh --frame 180 preview_shot1.png
./scripts/preview.sh --frame 540 preview_shot2.png
```

### Step 4: Synthesize Synchronized Audio (Optional)
If audio accents are required, execute the parametric synthesizer to generate soundscapes tailored to the shot timestamps:
```bash
python3 ./scripts/generate_audio.py --output /tmp/soundtrack.wav
```

### Step 5: Execute One-Command Production Build
Run the automated build script to compile the native renderer, stream frames into FFmpeg, and produce the final master MP4:
```bash
./scripts/build.sh --theme dark --output my_product_film.mp4
```

---

## 5. Directory Structure of This Skill

```text
skills/apple-motion-graphics/
├── SKILL.md                  # This master specification
├── README.md                 # Distribution and quick-start guide
├── scripts/
│   ├── build.sh              # Master production build and render runner
│   ├── preview.sh            # Single-frame instant visual inspector
│   ├── render_engine.m       # Native CoreGraphics 60fps rendering engine
│   └── generate_audio.py     # Parametric Apple launch film sound synthesizer
├── references/
│   ├── DESIGN_SYSTEM.md      # Detailed color codes, shadow math, and typography
│   └── AUDIO_SPEC.md         # Frequencies, envelope timings, and riser curves
└── examples/
    ├── dark_reveal_sample.m  # Reference code for dark theme product reveal
    └── light_workflow_sample.m # Reference code for light theme UI workflow
```

---

## 6. Quality & Verification Checklist

Before final sign-off, verify the rendered video against these standards:
- [ ] **1080p Resolution:** Frame size is strictly 1920 × 1080.
- [ ] **60.0 fps Consistency:** Motion is smooth with zero stutter or dropped frames.
- [ ] **Spelling Accuracy:** Every title, subtitle, and badge has been verified for correct spelling.
- [ ] **Physical Easing:** Every element uses cubic or quintic ease-out curves; no linear mechanical stops.
- [ ] **Generous Negative Space:** The composition feels uncluttered and cinematic.
- [ ] **Zero Tacky AI Effects:** No cyberpunk neon, no green matrix code, and no glowing brain graphics.
- [ ] **Faststart MP4:** The video file has the `moov` atom at the front (`+faststart`) for instant streaming playback.
