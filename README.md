# Anthill

**Grain-scale voxel game** built in **Godot 4.2+**. One voxel represents one **sand grain** in fiction (~3 mm); the world is **procedurally generated** (heightmap-style sand/stone), **sand falls** like Minecraft sand, and you control an **ant** that can **pick up** a single grain and **put it down** elsewhere.

## Run

Open the Godot project under **`game/anthill`** (see **`game/anthill/README.md`**) and press **F5**, or:

```bash
godot --path game/anthill
```

## Layout

| Path | Role |
|------|------|
| **`game/anthill/`** | Godot 4 project (voxels, sand physics, ant) |
| **`docs/cursor-agent-shell.md`** | Notes if the Cursor agent shell misbehaves |

### Cursor: agent terminal

If the Cursor agent’s **Shell** tool shows **no output** or **does not create files** here, see **`docs/cursor-agent-shell.md`**.
