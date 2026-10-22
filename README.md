# Apple Motion Graphics — Antigravity Skill

> **Generate broadcast-grade, Apple-inspired 1080p 60fps motion graphics and product launch films.**

This skill equips AI coding assistants (Google Antigravity, Claude Code, Cursor, Windsurf) and developers with an autonomous, high-performance motion graphics engine that generates cinema-grade software launch films.

---

## Highlights

- **Aesthetic Authenticity:** Replicates Apple's signature Obsidian Dark (`#050507`) and Pearlescent Studio Light (`#F5F5F7`) palettes, native San Francisco SF Pro typography, frosted glass materials, and dual-tier ambient occlusion shadows.
- **Extreme Performance (800+ fps):** Direct zero-dependency CoreGraphics + FFmpeg pipeline streaming uncompressed raw frames straight to H.264/VideoToolbox. No heavy headless browser or Puppeteer overhead.
- **Physical Causality & 3D Parallax:** Exploded 3D layer views, interactive button depress states, animated tracer lines with travelling energy pulses, and dynamic checklist ticks.
- **Parametric Sound Design:** Optional Python-powered acoustic synthesizer generating synchronized sub-bass swells, glass reveal bells, and tactile haptic micro-clicks.

---

## Installation & Distribution

### 1. In Antigravity (Project-Local)
Copy the `apple-motion-graphics` folder into your project's `.agents/skills/` directory:
```bash
mkdir -p .agents/skills
cp -r apple-motion-graphics .agents/skills/
```
Antigravity automatically discovers and activates the skill when you ask for Apple-style motion graphics, launch films, or product videos.

### 2. In Antigravity (Global Machine Configuration)
To make this skill available across all your repositories:
```bash
mkdir -p ~/.gemini/config/skills
cp -r apple-motion-graphics ~/.gemini/config/skills/
```

### 3. As a Portable CLI Tool
You can run the rendering pipeline directly from your terminal:
```bash
# Render a Dark Mode Launch Film
./scripts/build.sh --theme dark --output launch_film.mp4

# Render a Light Mode Feature Showcase
./scripts/build.sh --theme light --output showcase.mp4

# Inspect a single frame
./scripts/preview.sh --theme light --frame 240 preview.png
```

---

## Structure

```text
apple-motion-graphics/
├── SKILL.md                  # Main Antigravity skill definition & runbook
├── README.md                 # Distribution and quick-start guide
├── scripts/
│   ├── build.sh              # Master build and render script
│   ├── preview.sh            # Instant single-frame PNG preview generator
│   ├── render_engine.m       # Native CoreGraphics 60fps render engine
│   └── generate_audio.py     # Parametric Apple launch film sound synthesizer
├── references/
│   ├── DESIGN_SYSTEM.md      # Detailed color codes, typography, and shadow math
│   └── AUDIO_SPEC.md         # Frequencies, envelope timings, and riser curves
└── examples/
    ├── dark_reveal_sample.m  # 7-shot REA Introduction sequence (Dark)
    └── light_workflow_sample.m # 7-shot Results & Conclusion sequence (Light)
```

---

## Author & Brand
- **Brand:** GargProtocol
- **Subject:** REA — Reverse Engineer Anything
- **License:** MIT
