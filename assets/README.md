# Assets

Art and sound for Slip. Nothing in here is wired up yet; this folder
exists so the game has a home for media as it grows.

Planned layout:

- `sounds/` — effects and ambience: the slip, the jumpscare sting, the
  key turning, footsteps in the dark.
- `cutscenes/` — ASCII-art frames for `Sandbox_app.Cutscene` (banana
  slip, jumpscare, victory).

Keep file names `snake_case` and reference them from code rather than
hard-coding art inline, so scenes can be swapped without a rebuild of
the drawing logic.
