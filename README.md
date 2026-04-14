# CHOIR
### Autonomous Agents Assignment 2026 — TU Dublin

> *"A dense geometric hivemind that computes in silence and studies everything it encounters."*

---

## Concept

CHOIR is a 3D autonomous lifeform built in Godot, designed for VR on the Meta Quest 3. It takes the form of a tightly packed swarm of octahedral crystal shards — approximately 60–80 individual pieces — orbiting and interlocking around a luminous central core. From a distance CHOIR reads as a single dense, constantly shifting geometric mass. Up close it reveals itself to be a hivemind: each shard an individual cell, all moving with collective intention.

CHOIR has no face, no limbs, and makes no recognisable sounds. It does not acknowledge the player socially. It is ancient, indifferent, and deeply intelligent — and it is always in the middle of something.

The central design conceit is that CHOIR's forms are not emotional states. They are **computational states**. The creature is always working through an internal geometric process, cycling through mathematically precise configurations — nested Platonic solids, inversions, recursive splits — as if running calculations the player cannot understand. The player is not a companion or a threat. The player is a variable CHOIR has decided to include in its process.

The goal is to make the player feel observed, not interacted with. That distinction is what makes CHOIR unsettling.

---

## The Core

At the center of every formation sits CHOIR's core — a smooth glowing sphere that is the visual and conceptual heart of the creature. The core is the engine. Everything else orbits it, extrudes from it, or protects it.

How visible the core is at any moment communicates CHOIR's state more clearly than any other visual cue:

- **Fully buried** — CHOIR is closed, internal, processing privately. The core can only be inferred from faint light bleeding between tightly packed shards.
- **Partially revealed** — CHOIR is engaged with its environment. Gaps in the formation allow glimpses of the core.
- **Fully exposed** — a rare and significant moment. CHOIR has opened itself completely, either to observe the player directly or because the player has disrupted its structure.
- **Flickering or damaged** — the player has interrupted the process. The core destabilises until the formation repairs itself.

The player's implicit goal — never stated, never prompted — is to catch a clear look at the core. This is what drives genuine engagement with the creature.

---

## Formations

All formations are built from the same 60–80 octahedral shards around the same central core. Transitions between formations are either imperceptibly slow — the player notices the creature has changed without seeing it change — or mechanically precise, like a lock clicking into place.

### Autonomous Formations
These cycle on CHOIR's own internal timer, independent of the player. They are the creature's natural process.

**Metatron — resting state**
The mass continuously morphs between the five Platonic solids: tetrahedron, cube, octahedron, dodecahedron, icosahedron. Each transition bleeds into the next in an endless cycle. The core is completely buried — only a faint glow bleeds through shard gaps. From a distance this reads as a dense shifting sphere. Up close it is clearly mathematical and deliberate. This is CHOIR thinking.

**Inversion**
The entire mass turns inside out. Shards on the outer shell pull inward while interior shards emerge outward — a slow topological flip, like a glove turning inside out in slow motion. At the midpoint of the inversion the core is fully and briefly exposed before the new outer layer seals around it again. The most vulnerable and dramatic of the autonomous states.

**Recursion**
The mass splits into three smaller identical copies of itself, each orbiting the exposed central core in a tight equilateral triangle formation. Each smaller copy continues cycling through its own Platonic forms. Then all three collapse back into one unified mass. Feels mathematical — like a function calling itself. The core is visible throughout, sitting exposed at the center while the copies orbit it.

### Reactive Formations
These are triggered by specific player interactions. CHOIR does not react emotionally — it registers input, incorporates it into its process, and responds with clinical precision.

**Aperture — player enters proximity**
A single geometrically perfect aperture — hexagonal or pentagonal — irises open on the side of the mass facing the player, revealing the core within like a pupil. The core pulses once as the aperture opens, a single deliberate dilation. CHOIR is now actively pointing a sensor at the player. The aperture slowly closes again after several seconds. Clinical, not curious.

**Extrusion — player holds hand out still**
A single elongated octahedral spike slowly extrudes from the surface of the mass, reaching toward the player's open palm. It is lit from within by the core — like the core is conducting energy down the probe. The spike stops just short of making contact, holds for a moment, then retracts. CHOIR is taking a reading.

**Fracture — player pushes through the mass**
The mass cracks along perfect geometric fault lines — clean planar splits, like a crystal cleaving, not random scatter. The core flickers and destabilises as it is exposed, the only state in which the core looks genuinely damaged rather than merely revealed. Shards rebuild along the same fault lines they split on, resealing shard by shard from the outside in. The core stabilises as the last shard locks into place. The player interrupted the process. CHOIR is correcting an error.

**Shockwave — player throws an object at CHOIR**
A geometric ripple propagates outward from the point of impact through the dense mass. Each concentric layer of shards shifts outward then snaps back in sequence, like a pressure wave moving through a solid. The pulse visibly originates from the core, making clear that the core is the engine driving the response. The formation briefly becomes a perfect sphere at maximum ripple then contracts back. External input registered, absorbed, continuing.

---

## Technical Architecture

### Core Systems

**ShardManager** — spawns and owns all shard instances. Manages the target position list for the current formation and feeds each shard its lerp target every frame.

**FormationLibrary** — a static class containing the mathematical definitions for every formation. Each formation is a function that returns an array of world-space target positions and orientations given a shard count and a center point. Keeping formation logic here and out of ShardManager keeps the system clean and extensible.

**Shard (individual node)** — each shard is its own scene with a MeshInstance3D (octahedron), a small Area3D for hand proximity detection, and a script that handles lerping to its current target position, spinning on its own axis, and emitting its shader parameters.

**FSMController** — a finite state machine managing CHOIR's high-level state: Computing, Observing, Recalibrating, Logging. Each state maps to a formation or formation cycle and owns the transition logic. State changes are driven by either the internal timer or player interaction events passed up from the interaction detection layer.

**CoreController** — owns the core sphere node. Receives state signals from FSMController and drives core glow intensity, pulse timing, colour, and the crack shader parameter used during Fracture.

**PlayerSensor** — an Area3D on the player's hands and body that broadcasts proximity and velocity events to FSMController. Hand velocity tracked frame-to-frame to detect aggressive movement. Separate collision layer for thrown objects.

### Formation Transitions
Transitions lerp each shard from its current world position to its new target position over a configurable duration. A spring-damper approach (overshoot and settle) rather than a linear lerp gives transitions a mechanical-yet-organic quality. Transition speed is a per-formation parameter — Metatron's Platonic cycling is imperceptibly slow, Shockwave snaps almost instantly.

### VR Implementation
Built for Meta Quest 3 via Godot's OpenXR integration, reusing the XR setup from prior coursework. Hand tracking used for proximity and velocity sensing. The scene is a dark void environment — no floor, no skybox — so CHOIR is the only object of focus. Shard emission shaders provide all lighting, making the creature self-illuminating and visually striking without requiring scene lights.

### Shaders
Each shard uses a simple emission shader with two parameters: base colour and emission intensity. Both are driven by FSMController via ShardManager so the entire mass can shift colour and brightness simultaneously. The core uses a radial gradient emission shader with a crack parameter that introduces fault-line distortion during Fracture.

---

## Sound Design

All sound is output only — no microphone input. Audio is sourced from Freesound.org (CC0 licensed), lightly processed in Audacity, and triggered by FSM state transitions.

| Trigger | Sound |
|---|---|
| Idle / Computing | Low continuous drone, pitch shifts subtly as Platonic forms cycle |
| Formation transition | Brief crystalline harmonic click — glass settling |
| Aperture opening | Slow resonant singing bowl tone |
| Extrusion | A single sustained high tone, fading as probe retracts |
| Fracture | Sharp geometric crack, high ringing fade during rebuild |
| Shockwave | Deep bass pulse, single hit |
| Core exposed | A barely audible harmonic chord, felt more than heard |

Sound reinforces the "ancient computing intelligence" identity — tonal and harmonic rather than biological, precise rather than expressive.

---

## Marking Scheme Targets

**Groovyness — aiming for first**
VR deployment on Quest 3. Self-illuminating emission shaders across all shards and core. Particle system for shard trails during Fracture and Shockwave. Post-processing: subtle bloom on core and shard emission. Full sound design across all state transitions. Dark void environment maximises visual impact of the creature.

**Complexity — aiming for first**
Custom FSM architecture across dedicated classes. FormationLibrary containing 7+ mathematically defined formation functions. Per-shard autonomous behaviour layered on top of formation targets. Spring-damper transition system. Area3D-based player interaction detection. Shader parameter driven visual state. Estimated 15–20 hours of implementation work across novel self-directed systems.

**Project Management — aiming for first**
30–40 commits across feature branches: `feature/shard-system`, `feature/formations`, `feature/fsm`, `feature/player-interaction`, `feature/sound`, `feature/vr-build`. All commits meaningfully commented. Full README completion. Video recorded from Quest 3 build demonstrating all formations and interactions. Reflective section completed post-submission.

---

## References & Influences

- Sacred geometry — Metatron's Cube, nested Platonic solids
- Boids and swarm behaviour literature (Reynolds, 1987)
- Godot OpenXR documentation
- Freesound.org — CC0 audio sources
- Prior coursework: VR Godot project (Quest 3 XR setup, OpenXR integration)

---

## Name & Identity

**CHOIR** — chosen because a choir is many voices acting as one. Each shard is a voice. The mass is the song. The player never hears the words.

---

*Solo project — Maxim Gerashchenko — TU Dublin, 2026*