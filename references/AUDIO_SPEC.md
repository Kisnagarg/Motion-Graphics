# Apple Motion Graphics — Sound Design Specification

This document details the acoustic principles and frequencies used to synthesize subtle, high-end Apple product launch audio.

---

## 1. Acoustic Philosophy
Apple launch film audio is **restrained, spacious, and tactile**. It avoids aggressive EDM drops or heavy cinematic impacts in favor of:
- Deep, warm sub-bass foundations (`45 Hz – 110 Hz`).
- Soft white/pink noise sweeps mimicking gentle studio air.
- Pure harmonic sine bells (chimes) for reveals and element settling.
- High-frequency micro-transients (`1800 Hz – 3600 Hz`, duration `< 25 ms`) for tactile UI interaction.

---

## 2. Harmonic Frequencies & Envelopes

### Sub-Bass Swells
- **Sub Drone:** Continuous $55\text{ Hz}$ sine wave with $0.4\text{ Hz}$ binaural stereo detuning ($54.8\text{ Hz}$ Left, $55.2\text{ Hz}$ Right).
- **Sub Riser:** Frequency sweep $60\text{ Hz} \to 120\text{ Hz}$ over $2.5\text{ s}$ with exponential curve:
  $$f(t) = f_{\text{start}} + (f_{\text{end}} - f_{\text{start}}) \cdot (t / D)^{1.5}$$

### Reveal Bells (Chimes)
- **Primary Fundamental:** $440.0\text{ Hz}$ ($A_4$) or $528.0\text{ Hz}$ ("Clarity" harmonic).
- **Overtones:** $2\text{nd}$ harmonic ($880\text{ Hz}$) at $-6\text{ dB}$, $3\text{rd}$ harmonic ($1320\text{ Hz}$) at $-12\text{ dB}$.
- **Envelope:** Immediate attack ($5\text{ ms}$), long natural decay ($2.5\text{ s} - 3.5\text{ s}$).

### Micro-Clicks & Haptic Taps
For interactive states (button depress, checkbox toggle):
- **Frequency:** $2200\text{ Hz} – 3200\text{ Hz}$.
- **Duration:** $20\text{ ms} – 25\text{ ms}$.
- **Decay Formula:**
  $$v(t) = \sin(2\pi \cdot f \cdot t) \cdot e^{-220 \cdot t}$$

### Step-Sequence Chimes
When multiple cards dock into place in sequence, use an ascending pentatonic chord:
- **Card 1:** $E_4$ ($329.63\text{ Hz}$)
- **Card 2:** $G^\#_4$ ($415.30\text{ Hz}$)
- **Card 3:** $B_4$ ($493.88\text{ Hz}$)
- **Card 4:** $E_5$ ($659.25\text{ Hz}$)
