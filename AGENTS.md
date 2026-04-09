# AGENTS.md

## Cursor Cloud specific instructions

### Overview

Anthill is a **Godot 4.2+** **grain-scale voxel ant colony simulation** (*Lasius niger*–inspired). There is no backend, database, or external service. The only runtime dependency is the **Godot 4.2.2** engine binary.

### Shorthand: `cpi`

When the user says **`cpi`**, they mean **commit**, **push**, then **install**:

1. Git commit and push (tracked changes).
2. **`sudo ./scripts/install-anthill.sh`** from the repository root — copies **`game/anthill`** to **`/usr/local/share/anthill/game/anthill`** and installs the **`anthill`** launcher to **`/usr/local/bin/anthill`** (requires Godot 4 on `PATH` as **`godot4`** or **`godot`**). See the root **`README.md`** “System install” section.

### Running the simulation

```bash
Xvfb :99 -screen 0 1280x720x24 &
export DISPLAY=:99
godot4 --path game/anthill
```

- Xvfb is required because Godot's GL Compatibility renderer needs a display server, even in a headless VM.
- ALSA audio warnings ("cannot find card '0'", "All audio drivers failed") are expected and harmless when no sound hardware is present.
- The `ant.gd` parse error on import is a known non-blocking issue (the script is reserved for future use and not loaded at runtime by the main scene).

### Importing the project (headless)

To import resources without opening the simulation window:

```bash
godot4 --path game/anthill --import
```

### Lint / test / build

- **No linter or test framework** is configured. GDScript is validated by `godot4 --path game/anthill --import` (parse errors are reported on stderr).
- **No build step** is needed — Godot runs the project directly from source.

### Key paths

| Path | Purpose |
|---|---|
| `game/anthill/project.godot` | Godot project file (entry point) |
| `game/anthill/scenes/main.tscn` | Main colony scene |
| `game/anthill/scripts/` | GDScript simulation logic |
| `docs/reference/` | Bibliography, specification, briefing, **`architecture_of_emergence.txt`** (not loaded at runtime) |
| `scripts/install-godot4.sh` | Installs Godot 4.2.2 to `/usr/local/bin/godot4` |
| `scripts/install-anthill.sh` | System install: project under `/usr/local/share/anthill/`, launcher **`anthill`** in `/usr/local/bin/` (run with **`sudo`**) |

### Reference document vs code (`architecture_of_emergence.txt`)

**`docs/reference/architecture_of_emergence.txt`** summarizes positive feedback (mass recruitment, stigmergy), negative feedback (footprint hydrocarbons), and *Lasius niger* vs *Monomorium pharaonis* contrasts. When changing foraging or chemical fields, treat it as **intent**, not a checklist of implemented features.

**Implemented in spirit:** recruitment **trail** pheromone with stigmergic deposit and diffusion/evaporation; **CHC footprint** field with passive deposit, negative chemotaxis, and tropotaxis that combines trail attraction with footprint/crowding in the denominator; **food-proximity–scaled** per-step return deposits (workers only—no automatic pheromone at the patch); **feeder crowding**; **alarm** field (Dufour-type framing, not literal undecane chemistry).

**Not implemented:** second-species (*M. pharaonis*) rules; **volatile short-half-life** repellent as a separate mechanism; **physical interaction** at bifurcations (ants pushing nestmates); **visual landmarks**; a built-in **pheromone-only vs dual-signal** A/B experiment in the executable.

The **root `README.md`** section **“Architecture of Emergence (reference mapping)”** has the full table; keep it in sync when adding or removing major feedback mechanisms.
