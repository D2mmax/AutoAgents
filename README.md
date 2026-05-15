# Autonomous Agents Assignment 2026 — TU Dublin

**Maxim Gerashchenko**

---

## Concept

Two autonomous alien creatures inhabit a dark VR space environment, built in Godot 4 and deployed on the Meta Quest 3. Each creature is a bioluminescent spine — a glowing head trailed by a tapering chain of segments — that drifts, hunts, bonds and reacts entirely on its own.

The creatures have no scripted behaviours. Everything they do emerges from three internal drives: **hunger**, **curiosity** and **loneliness**. These needs build and deplete over time, driving state transitions that produce behaviour that feels genuinely alive — investigating the player, competing for food near glowing planets, seeking each other out and forming a DNA helix when loneliness peaks.

The player is stationary. You can only look around and move your hands. The creatures react to your presence and your hands — they'll come to investigate you, orbit you, show off in front of you, and bolt if you reach toward them.

---

## Name & Identity

The creatures have no names. They are alien and unknowable — bioluminescent organisms that evolved in the void between stars. Their behaviour suggests intelligence but not language. They are curious about you the way an animal is curious: cautious, watchful, and ultimately indifferent to your understanding of them.

Each creature has a distinct colour palette across all states so they are always visually distinguishable.

---

## Needs System

Three internal drives govern all behaviour:

**Hunger** — rises automatically over time. At 0.3 the creature hunts visible food. At 0.8 it actively searches even when food is out of range.

**Curiosity** — rises slowly always, faster when the player is nearby. Drives the creature toward the player. Drains while orbiting and displaying — satisfied curiosity.

**Loneliness** — builds when the two creatures are more than 8 units apart, faster the further apart they are. Only drains during bonding. When it passes 0.7 the creature abandons its current wandering and seeks its companion. Once together, they enter bonding state until loneliness reaches zero.

---

## FSM — 10 States

The creature brain is a finite state machine with 10 states, each with its own movement behaviour and emission colour:

| State | Colour (C1 / C2) | Description |
|---|---|---|
| DRIFTING | Purple / Teal | Lazy Perlin noise wander through space |
| CURIOUS | Cyan / Purple | Slowly approaches player to investigate |
| ORBITING | Magenta / Mint | Circles player in a figure-8 path |
| DISPLAYING | Rainbow / Aqua | Tornado spiral 5m in front of player, head pulsing |
| HUNTING | Orange / Yellow | Seeks nearest food orb, steers around planets |
| FEEDING | Green pulse | Reaches food, grows a segment, resets hunger |
| SEARCHING | Amber / Yellow-green | Fast erratic wander when hungry but no food visible |
| FLEEING | Red / Hot pink | Bolts away when hand touches creature head |
| AGITATED | Flickering red | Fast chaotic movement after fleeing |
| BONDING | Cyan / Magenta | DNA double helix formation with companion creature |

---

## Steering Behaviours

- **Perlin wander** — noise-driven drifting with smooth direction changes
- **Seek** — direct pursuit of a target position
- **Arrive** — seek with speed reduction near target (used during hunting approach)
- **Flee** — velocity away from a threat position
- **Offset pursue** — orbiting around the player at a fixed radius
- **Planet repulsion** — force-based deflection away from planet surfaces, active in all states
- **Separation** — Boids-style push force preventing creatures from passing through each other
- **Loneliness seek** — purposeful movement toward companion when loneliness threshold is exceeded

---

## Environment

A dark void environment with three glowing planets — small (purple), medium (blue), large (red). Planets have sphere colliders for repulsion force calculation. Food orbs spawn near planet surfaces and respawn every 12 seconds, maintaining at least 6 orbs distributed across all three planets.

Bounds are enforced with a soft steering force that curves the creature away from the edge rather than flipping its velocity.

---

## VR Implementation

Built for Meta Quest 3 via Godot's OpenXR integration and the Godot XR Tools plugin. Low-poly hand models track the player's controllers. A HUD label is attached to the XRCamera3D showing each creature's current state, hunger and loneliness — one in the top-left and one in the top-right of the player's view.

---

## Technical Architecture

- `creature.gd` — all creature logic: FSM, needs system, steering behaviours, segment animation, HUD
- `main.gd` — scene setup, planet colliders, food spawning and respawning

Key systems:
- Procedural spine animation — segments follow the head using a chain constraint updated every frame
- Per-creature material duplication on startup so colour changes are independent
- Creature group (`"creatures"`) used for inter-creature awareness — separation, loneliness, bonding detection
- Bonding cooldown (8 seconds) prevents rapid re-entry after bonding ends

---

## What I Learned

This project taught me how much emergent behaviour you can get from simple rules. The loneliness/bonding cycle was the most interesting to develop — it wasn't planned from the start but grew naturally from wanting the creatures to feel like they had a relationship with each other rather than just reacting to the player. Watching two creatures independently wandering, then one slowly turning and heading toward the other as loneliness builds, feels genuinely alive in VR in a way that's hard to fake with scripted behaviour.

The hardest technical challenge was planet avoidance during hunting. Several approaches failed (raycasts, waypoints, gravity wells) before settling on a force-based repulsion combined with a proper seek+repulsion vector blend that normalises together rather than applying sequentially.

VR added a dimension that flat-screen development can't replicate — the creatures orbiting and displaying in actual 3D space around you changes the experience completely.

---

## References & Influences

- Reynolds, C. (1987). *Flocks, Herds and Schools: A Distributed Behavioral Model*. SIGGRAPH.
- Reynolds, C. (1999). *Steering Behaviors For Autonomous Characters*. Game Developers Conference.
- Bryan Duggan — Infinite Forms, SpineAnimator system, Autonomous Agents module lectures
- Godot XR Tools documentation
- Godot OpenXR documentation
-

---

## Project Structure

```
AutoAgents/
├── creature.gd          # All creature logic
├── creature.tscn        # Creature scene with head mesh
├── main.gd              # Scene management, food spawning
├── main.tscn            # Main scene with planets, XR rig, two creatures
├── addons/
│   └── godot-xr-tools/  # XR Tools plugin
└── NightSkyHDRI009_2K_HDR.exr  # Space skybox
```

---

## Video

https://youtu.be/m7MYs2jyKxM

---

*Solo project — Maxim Gerashchenko — TU Dublin, 2026*
