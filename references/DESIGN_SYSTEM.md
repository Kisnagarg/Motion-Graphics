# Apple Motion Graphics — Design System Specification

This document provides the mathematical specifications, color constants, typography scales, and material shaders used to construct Apple-inspired product launch graphics.

---

## 1. Palette & Color Constants

### Dark Studio Palette (Obsidian)
```objc
// Base Canvas
#define COLOR_DARK_BASE        [NSColor colorWithCalibratedRed:0.02 green:0.02 blue:0.03 alpha:1.00]
#define COLOR_DARK_VIGNETTE    [NSColor colorWithCalibratedRed:0.01 green:0.01 blue:0.02 alpha:1.00]
#define COLOR_DARK_SPOTLIGHT   [NSColor colorWithCalibratedRed:0.09 green:0.10 blue:0.15 alpha:1.00]

// Surfaces & Glass
#define COLOR_DARK_GLASS_FILL  [NSColor colorWithCalibratedRed:0.08 green:0.09 blue:0.12 alpha:0.90]
#define COLOR_DARK_GLASS_STROKE [NSColor colorWithWhite:1.00 alpha:0.18]
#define COLOR_DARK_PANEL_ALT   [NSColor colorWithCalibratedRed:0.05 green:0.06 blue:0.08 alpha:0.92]

// Typography
#define COLOR_DARK_TEXT_PRIMARY   [NSColor colorWithCalibratedWhite:0.98 alpha:1.00] // #F5F5F7
#define COLOR_DARK_TEXT_SECONDARY [NSColor colorWithCalibratedWhite:0.75 alpha:0.85] // #A1A1A6
#define COLOR_DARK_TEXT_TERTIARY  [NSColor colorWithCalibratedWhite:0.55 alpha:0.70] // #6E6E73

// Accents
#define COLOR_APPLE_BLUE          [NSColor colorWithCalibratedRed:0.16 green:0.59 blue:1.00 alpha:1.00] // #2997FF
#define COLOR_APPLE_BLUE_GLOW     [NSColor colorWithCalibratedRed:0.25 green:0.65 blue:1.00 alpha:0.40]
#define COLOR_APPLE_GREEN_SUCCESS [NSColor colorWithCalibratedRed:0.18 green:0.80 blue:0.40 alpha:0.95]
```

### Light Studio Palette (Pearlescent)
```objc
// Base Canvas
#define COLOR_LIGHT_BASE          [NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.97 alpha:1.00] // #F5F5F7
#define COLOR_LIGHT_VIGNETTE      [NSColor colorWithCalibratedRed:0.91 green:0.91 blue:0.93 alpha:1.00]
#define COLOR_LIGHT_SPOTLIGHT     [NSColor colorWithCalibratedRed:1.00 green:1.00 blue:1.00 alpha:1.00]

// Surfaces & Glass
#define COLOR_LIGHT_GLASS_FILL    [NSColor colorWithWhite:1.00 alpha:0.95]
#define COLOR_LIGHT_GLASS_STROKE  [NSColor colorWithCalibratedRed:0.84 green:0.84 blue:0.87 alpha:0.85]
#define COLOR_LIGHT_PANEL_ALT     [NSColor colorWithCalibratedRed:0.94 green:0.95 blue:0.97 alpha:1.00]

// Typography
#define COLOR_LIGHT_TEXT_PRIMARY   [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:1.00] // #1D1D1F
#define COLOR_LIGHT_TEXT_SECONDARY [NSColor colorWithCalibratedRed:0.45 green:0.45 blue:0.48 alpha:0.90] // #6E6E73
#define COLOR_LIGHT_TEXT_TERTIARY  [NSColor colorWithCalibratedRed:0.60 green:0.60 blue:0.64 alpha:0.75] // #86868B

// Accents
#define COLOR_LIGHT_BLUE_ACCENT    [NSColor colorWithCalibratedRed:0.00 green:0.44 blue:0.89 alpha:1.00] // #0071E3
#define COLOR_LIGHT_BLUE_BG        [NSColor colorWithCalibratedRed:0.00 green:0.44 blue:0.89 alpha:0.10]
#define COLOR_LIGHT_GREEN_SUCCESS  [NSColor colorWithCalibratedRed:0.18 green:0.80 blue:0.40 alpha:0.95]
```

---

## 2. Multi-Tier Shadow Shading

Apple interfaces achieve realistic elevation through a combination of **Ambient Occlusion** (broad, soft shadow) and **Contact Shadow** (tight, directional shadow).

### Formula
$$\text{Shadow}_{\text{Total}} = \text{Shadow}_{\text{Ambient}}(\text{blur}=55, \sigma_{\text{opacity}}=0.12) + \text{Shadow}_{\text{Contact}}(\text{blur}=18, \sigma_{\text{opacity}}=0.08, \Delta y=-25)$$

In CoreGraphics:
```objc
// Primary ambient elevation shadow
CGContextSetShadowWithColor(ctx, CGSizeMake(0, -25), 50.0,
    [[NSColor colorWithCalibratedRed:0.10 green:0.12 blue:0.20 alpha:0.09] CGColor]);
```

---

## 3. Kinetic Typography & Kerning Rules

Always format typography using `NSAttributedString` with explicit tracking (`NSKernAttributeName`).

| Style | Font Size | Weight | Tracking (`NSKern`) | Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Hero Title** | `175pt` | `NSFontWeightHeavy` | `@(18.0)` | Core acronyms ("REA") |
| **Hero Subtitle** | `26pt` | `NSFontWeightLight` | `@(8.0)` | Expanded brand titles |
| **Section Title** | `38pt` | `NSFontWeightBold` | `@(1.2)` | Primary shot headlines |
| **Body Paragraph** | `15pt` | `NSFontWeightRegular` | `@(0.4)` | Narrative explanations |
| **Badge / Pill Tag** | `11pt - 14pt` | `NSFontWeightSemibold` | `@(3.0 - 5.0)` | Status indicators, workflow steps |
| **Brand Watermark** | `13pt` | `NSFontWeightMedium` | `@(5.0)` | Top-corner company identifier |

---

## 4. 3D Perspective Projection

To simulate 3D camera orbits without heavy 3D rendering packages, apply a 2D affine perspective matrix:

```objc
double rotY = -0.08 + 0.16 * easeInOutQuad(progress); // Yaw
double rotX = 0.04 - 0.06 * easeInOutQuad(progress);  // Pitch

CGAffineTransform transform3D = CGAffineTransformMake(
    cos(rotY),
    sin(rotX) * 0.45,
    -sin(rotY) * 0.35,
    cos(rotX),
    0,
    0
);
CGContextConcatCTM(ctx, transform3D);
```

When layers separate along the Z-axis, translate each layer along the normal vector:
$$\Delta x = \Delta z \cdot \sin(\theta_y) \cdot 0.6$$
$$\Delta y = \Delta z \cdot \sin(\theta_x) \cdot 0.6$$
This creates physically consistent parallax depth between floating interface tiers.
