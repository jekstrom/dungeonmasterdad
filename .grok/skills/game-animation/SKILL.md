---
name: setup-godot-2d-sprite-animation
description: >
  Configures, scripts, and optimizes 2D sprite animations and state machines in Godot 4.x.
  Triggers on requests for AnimatedSprite2D, Sprite2D AnimationPlayer setups, AnimationTree state machines, and GDScript playback controllers.
  Use when the user runs /setup-godot-2d-sprite-animation.
when-to-use: >
  Use when the user asks to implement 2D animations, slice sprite sheets into SpriteFrames, build AnimationTree blend spaces
  or state machines, or write GDScript controller code for 2D characters and objects in Godot.
argument-hint: [AnimatedSprite2D|AnimationPlayer] [state-machine|blend-space-2d] [GDScript]
metadata:
  short-description: Godot 4 2D Sprite Animation & State Machine Setup
  author: dungeon-master-dad
paths: ["**/*.gd", "**/*.tscn", "**/*.tres"]
---

# Godot 2D Sprite Animation Setup

Procedural instructions for implementing, wiring, and controlling 2D sprite animations and state machines in Godot 4.x.

Project conventions live in `AGENTS.md`. Do not copy them here.

## When this applies

- Setting up `AnimatedSprite2D` or `Sprite2D` + `AnimationPlayer` nodes in Godot 4.
- Slicing and importing horizontal/vertical sprite sheets into `SpriteFrames` resources.
- Constructing `AnimationTree` nodes using `AnimationNodeStateMachine` or `AnimationNodeBlendSpace2D` (for 4-way / 8-way directional movement).
- Writing GDScript controllers to handle velocity-based state transitions, directional blending, and hit-frame callbacks.

## Steps

1. **Select the Appropriate Animation Node Architecture**:
   - For simple, frame-based looping sprites (e.g., pickups, basic UI, simple enemies): use `AnimatedSprite2D` with a `SpriteFrames` resource.
   - For complex characters requiring call-method tracks, precise collision shape shifting, root motion, or multi-property keyframing: use `Sprite2D` + `AnimationPlayer`.
   - For multi-directional, input-driven state blending (e.g., 4-way/8-way ARPGs): attach an `AnimationTree` referencing the `AnimationPlayer`.

2. **Configure Texture Import & Slicing**:
   - Set texture filtering appropriately in Project Settings or per-texture (`Default Texture Filter: Nearest` for pixel art).
   - If using `Sprite2D`: configure `hframes` and `vframes` in the Inspector to match the sprite sheet dimensions, and animate the `frame` property in `AnimationPlayer`.
   - If using `AnimatedSprite2D`: create a new `SpriteFrames` resource, use the sprite sheet slicing tool, and set the animation FPS and loop flags.

3. **Construct the Animation Graph (If using AnimationTree)**:
   - Set `tree_root` to `AnimationNodeStateMachine`.
   - For directional states (`Idle`, `Walk`, `Run`), create `AnimationNodeBlendSpace2D` sub-nodes.
   - Map directional blend points to standard 2D Cartesian vectors:
     - Up/North: `(0, -1)`
     - Down/South: `(0, 1)`
     - Left/West: `(-1, 0)`
     - Right/East: `(1, 0)`
   - Set the BlendSpace mode to `Discrete` for pixel art / frame-by-frame sprites, or `Continuous` for smooth transitions.
   - Add state transitions with conditions (`advance_condition` or explicit travel commands).

4. **Implement the GDScript Controller**:
   - Connect animation parameters to movement logic inside `_physics_process(delta)`.
   - Update blend position parameters based on input or velocity:
     ```gdscript
     var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
     if input_vector != Vector2.ZERO:
         animation_tree.set("parameters/Idle/blend_position", input_vector)
         animation_tree.set("parameters/Walk/blend_position", input_vector)
         playback.travel("Walk")
     else:
         playback.travel("Idle")
     ```
   - Ensure `playback.travel("StateName")` is used for discrete state changes rather than manually stopping and starting tracks.

5. **Set Up Frame Events and Signal Synchronization**:
   - Insert `Call Method Track` entries in `AnimationPlayer` for frame-critical events (e.g., enabling attack hitboxes, triggering footstep audio, emitting projectile scenes).
   - For non-looping animations (e.g., `Attack`, `Hurt`, `Death`), yield or listen to the `animation_finished` signal or use an explicit state machine exit transition before returning control to the player.

## Done when

- The node tree is structured with correct node types (`Sprite2D` + `AnimationPlayer` or `AnimatedSprite2D`).
- All sprite sheet frames are sliced with exact `hframes`/`vframes` or `SpriteFrames` dimensions without bleeding or off-by-one pixel clipping.
- GDScript cleanly drives playback, directional blend spaces update based on movement vectors, and state transitions execute without locking the player state.
