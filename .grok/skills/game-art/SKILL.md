---
name: generate-2d-sprite-sheet
description: >
  Generates, choreographs, and formats game-ready 2D sprite sheets in 3/4 perspective for 64px and 128px cell grids.
  Triggers on requests for 2D sprite sheets, 3/4 view character animations, isometric pixel art sheets, and texture atlas definitions.
  Use when the user runs /generate-2d-sprite-sheet.
when-to-use: >
  Use when the user asks to create, prompt, animate, or slice 2D character sprite sheets in 3/4 perspective, top-down oblique,
  or 2:1 isometric views targeting 64x64 or 128x128 pixel dimensions.
argument-hint: [character/action] [64px|128px] [isometric|top-down-3/4]
metadata:
  short-description: 3/4 View 64/128px Sprite Sheet Generator
  author: dungeon-master-dad
---

# 2D Sprite Sheet Artist (3/4 Perspective • 64px / 128px)

Procedural instructions for generating grid-aligned, engine-ready 2D sprite sheets and animation metadata in 3/4 perspective.

Project conventions live in `AGENTS.md`. Do not copy them here.

## When this applies

- Generating 2D sprite sheets for characters, monsters, or objects in 3/4 perspective (isometric, dimetric, top-down oblique)[cite: 1].
- Designing frame-by-frame animation breakdowns constrained to 64x64px or 128x128px bounding boxes[cite: 1].
- Creating diffusion model prompts (Midjourney, SDXL) formatted for uniform sprite strips or grids[cite: 1].
- Exporting texture atlas JSON metadata and UV/pivot coordinate mappings for 2D game engines[cite: 1].

## Steps

1. **Resolve Grid & Projection Parameters**:
   - Determine the cell resolution: **64x64px** (retro/mid-res pixel art) or **128x128px** (HD pixel art / clean vector)[cite: 1].
   - Apply the active silhouette constraint: 44–54px character height for 64px cells; 88–110px character height for 128px cells[cite: 1].
   - Fix the projection mode to one of:
     - *Top-Down 3/4*: 45° camera angle[cite: 1].
     - *2:1 Isometric*: 26.565° dimetric slope (2px horizontal per 1px vertical step)[cite: 1].
     - *Oblique Dimetric*: 30° shoulder angle with forward-facing plane[cite: 1].

2. **Establish Direction & Ground Plane**:
   - Map the target facing direction using the 8-way compass (`N`, `NE`, `E`, `SE`, `S`, `SW`, `W`, `NW`)[cite: 1].
   - If the subject is asymmetrical (e.g., weapon in main hand, shield in off-hand), require explicit directional rows and disallow horizontal mirroring[cite: 1].
   - Anchor the base footprint to an elliptical ground contact area (24–32px wide for 64px grids; 48–64px wide for 128px grids)[cite: 1].

3. **Choreograph the Frame Sequence**:
   - Assign standard frame counts and frame rates:
     - *Idle*: 4–6 frames (6–8 FPS, looping)[cite: 1].
     - *Walk*: 6–8 frames (10–12 FPS, looping, contact -> squash -> pass -> stretch)[cite: 1].
     - *Run*: 6–8 frames (12–16 FPS, looping, forward lean)[cite: 1].
     - *Melee Attack*: 5–6 frames (14–18 FPS, 2 anticipation -> 1 strike/smear -> 2–3 settle)[cite: 1].
     - *Take Hit / Death*: 3–4 frames (Hit) or 6–8 frames (Death, settle to ground ellipse)[cite: 1].
   - Track Z-depth sorting per frame: ensure foreground limbs/weapons layer over the torso and background limbs layer behind[cite: 1].

4. **Generate Diffusion Prompts (If Requested)**:
   - Construct positive prompts including: subject description, action state, `3/4 isometric perspective`, `angled top-down view`, exact frame count, uniform grid layout (`8x1 strip` or `4x2 grid`), fixed resolution tag (`64x64` or `128x128`), and solid high-contrast background[cite: 1].
   - Enforce negative prompts: exclude perspective vanishing lines, tilted grids, uneven cell spacing, drop shadows, 3D render depth, and frame clipping[cite: 1].

5. **Generate Engine Atlas Configuration**:
   - Format a JSON metadata object mapping each frame index, frame boundary (`x`, `y`, `w`, `h`), and total atlas dimensions[cite: 1].
   - Set the default 3/4 perspective pivot point to `{"x": 0.5, "y": 0.875}` to place the anchor directly at the center of the ground footprint[cite: 1].

## Done when

- The output defines exact pixel cell boundaries (64px or 128px) and maintains 3/4 perspective consistency across all poses[cite: 1].
- Every animation frame has an assigned sequence index, timing, and boundary-safe positioning[cite: 1].
- Atlas metadata or image prompts contain complete pivot and grid dimension specifications[cite: 1].
