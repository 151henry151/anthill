# AGENTS.md

## Cursor Cloud specific instructions

### Overview

Anthill is a **Godot 4.2+** **grain-scale voxel ant colony simulation** (*Lasius niger*–inspired). There is no backend, database, or external service. The only runtime dependency is the **Godot 4.2.2** engine binary.

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
| `docs/reference/` | Bibliography, specification, briefing (not loaded at runtime) |
| `scripts/install-godot4.sh` | Installs Godot 4.2.2 to `/usr/local/bin/godot4` |
