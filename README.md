# You're the Food

Reverse snake: you are the food, and the snakes are hunting *you*. Dash through their bodies to survive as long as you can.

Made with Godot 4 and hand-painted sprites.

## Running it

Open the project in Godot 4.3 or newer (**Import** → pick `project.godot`, or drag the folder onto the project manager) and press F5.

## How to play

- **WASD / arrows** — roll around (momentum + friction)
- **Click / Space** — dash toward the cursor. Dash into a **body** to sever it; dash into a **head** to explode it (the next segment takes over as the new head). A successful dash hit protects you for a moment.
- **Touching any part of a snake hurts** — heads and bodies both deal damage. Dash to fight back.
- **Team kill**: lure snakes into each other's bodies for +100 score and a pellet feast.
- Snakes eat pellets to grow. You can grab pellets yourself for +5.
- **ESC / P** — pause (restart or bail to the menu from there).
- Edge arrows point at off-screen snakes.
- Every wave runs on a **30 second countdown** — clear it early or the next wave piles on top of whatever's left.

## Enemies & hazards

- **Armored snakes** (wave 2+): every other segment is plated and dashes clang off — aim for the soft segments. The head still explodes normally.
- **Splitters** (wave 2+, purple tint): don't lose their tail when cut — it wakes up as a second snake. Choose your cuts.
- **Critters**: snakes are full of them. Kill or cut a snake and some crawl out — they hatch for a second (trembling, harmless), then chase you. Dash into one for +15; let an awake one touch you and it costs a life (it dies doing it).
- **Rockslide** (wave 2+): boulders drop near you. A growing indicator telegraphs each impact — dodge it, or bait a snake underneath: a crushed head explodes, a crushed body gets severed, score included. Landed rocks sit around as solid obstacles for a few seconds before crumbling.

## Powerups

Severed snake bodies sometimes drop one:

| Pickup | Effect |
|---|---|
| Lightning | Turbo — dash recharges almost instantly (8s) |
| Shield | Absorbs one hit |
| Sword | Pierce — dashes cut clean through without bouncing (8s) |

Your best score is saved locally and shown on the menu.

## Project layout

| Path | What it is |
|---|---|
| `scenes/main.tscn` | The whole game: world containers, camera, menus, HUD |
| `scripts/main.gd` | Game states, waves, collisions |
| `scripts/player.gd` | Movement, dash, lives |
| `scripts/snake.gd` | Snake AI, body trail, cutting/splitting/exploding |
| `scripts/boulder.gd` | Rockslide hazard |
| `scripts/critter.gd` | The little enemies that crawl out of snakes |
| `scripts/hud.gd` | Score/wave/time labels, hearts, off-screen arrows |
| `assets/` | Painted sprites |
