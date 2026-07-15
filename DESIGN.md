# Slip — design notes

## A. What kind of maze game is this?

**Slip** is a top-down, Pacman-style maze traversal horror game played
in the terminal. The player wakes at the bottom-left corner of a
randomly generated maze and must find a key hidden somewhere in the
dark. Two things make it a horror game:

- **The POV.** The view is from above, but relative to the player: the
  map rotates with every turn so the direction the player faces is
  always "up", and only a small circle of torchlight around the player
  is visible. Everything outside the circle is darkness.
- **The dread.** A monster hunts the player through the maze; getting
  caught means a jumpscare and a lost run. Bananas litter the floor —
  step on one and the player slips, blacks out, and wakes in the same
  spot with the walls rearranged around them (same maze size, key in
  the same place, one banana fewer).

The game is *always winnable*: every generated maze — including every
regenerated one — is guaranteed to contain a wall-free, banana-free
path from the player to the key.

## Major software components

| Component | Module(s) | Responsibility |
|---|---|---|
| Maze generation | `engine/src/maze.ml` | Carve a random maze (randomized DFS on a node lattice, then braided with extra loops), place the key far from the start, place bananas off one shortest path so a banana-free route always exists. `regenerate` rebuilds walls around the player after a slip: same size, same key, `n - 1` bananas, never a wall on the player or key. |
| Game state | `engine/src/game.ml` | The state machine: start screen → playing → won / lost → back to the start screen. One player action = one tick; the monster steps every tick. Handles movement, turning, wall bumps, banana slips, key pickup, monster collision, quitting. |
| Monsters | `engine/src/monster_intf.ml`, `monster.ml` | `Monster_intf.S` is the customizable interface — a new monster type is just `create` / `position` / `step`. Shipped behaviors: `Chaser` (BFS pursuit at half speed) and `Wanderer` (random drift). Packed as a first-class module so different monster types can coexist. |
| Player POV | `engine/src/viewport.ml` | Rotates the world so the facing direction is up and masks it to a circle of light around the player. Pure function from game state to a tile grid. |
| Rendering | `app/src/render.ml` | One screenful of ANSI text per game phase: start screen, torchlit view + banana counter, win screen, jumpscare lose screen. |
| Input / main loop | `app/src/game_loop.ml`, `app/bin/main.ml` | Raw-mode terminal keyboard loop: one keypress → one `Game.Action` → repaint. |
| Cutscenes | `app/src/cutscene.ml` | Timed full-screen frame sequences for dramatic moments (banana slip, jumpscare, victory). Plumbing only for now — no art drawn yet. |
| Assets | `assets/` | Home for future sounds and ASCII-art frames. |

The split keeps everything under `engine/` pure and deterministic
(seedable `Random.State`, no I/O), which is what makes the expect-test
suite possible; all terminal I/O lives in `app/`.

## B. What can be cut for time or interest?

- Cutscene art for banana slips and jumpscares (the module and hook
  points exist; the frames don't).
- More interactions (torches that reveal parts of the maze, pickups).
- Game modes: several monsters at once, different monster rosters,
  difficulty settings.
- Sound (the `assets/` folder is reserved for it).

## C. What is out of scope?

- Multiplayer.

## D. Where is the technical difficulty?

1. **Maze generation with a winnability guarantee.** Random mazes are
   easy; random mazes that always leave a banana-free path to the key —
   and keep that promise again after every regeneration, from wherever
   the player happens to be standing, without walling in the player or
   the key — need care. The approach: carve a perfect maze on the
   odd-coordinate lattice (all nodes connected by construction), braid
   in loops, force the player and key cells open (each is provably
   adjacent to lattice floor), then place bananas only off one shortest
   player→key path. Every property is checked by 100-seed expect tests.
2. **Managing the player POV.** The rotation (view space → world space
   for each facing) and the circular light mask are easy to get subtly
   wrong — a transposed axis makes "left" turn the world the wrong way.
   Keeping `Viewport` a pure function over an asymmetric test maze makes
   the expect tests catch exactly that.
3. **Fairness of the chase.** The monster steps once per player action
   (turning is not free), so a naive BFS chaser is inescapable. The
   `Chaser` shambles — it rests every other tick — which keeps it
   scary but survivable, and the monster interface makes it cheap to
   experiment with other behaviors.
