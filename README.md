# Anthill

**Grain-scale voxel game** built in **Godot 4.2+**. One voxel represents one **sand grain** in fiction (~3 mm); the world is **procedurally generated** (heightmap-style sand/stone), **sand falls** like Minecraft sand, and you control an **ant** that can **pick up** a single grain and **put it down** elsewhere.

## Run

Open the Godot project under **`game/anthill`** (see **`game/anthill/README.md`**) and press **F5**, or:

```bash
godot --path game/anthill
```

### System install (`anthill` command)

Requires **Godot 4** on your PATH as `godot4` or `godot` (e.g. distro package or [official build](https://godotengine.org/download/linux/)).

From the repo root:

```bash
sudo ./scripts/install-anthill.sh
```

This copies the project to **`/usr/local/share/anthill/game/anthill`** and installs **`/usr/local/bin/anthill`**, which runs `godot4`/`godot --path …` (also checks **`/usr/bin`** and **`/usr/local/bin`**). If the binary has another name or location, set **`GODOT_BIN`** for one session, e.g. `GODOT_BIN=/path/to/Godot_v4.x_linux.x86_64 anthill`. Override install prefix: `sudo PREFIX=/opt/anthill ./scripts/install-anthill.sh`.

**If `anthill` opens the old Luanti-style main menu:** your shell probably prefers **`~/.local/bin`** over **`/usr/local/bin`**. An earlier **Luanti fork** may have installed **`~/.local/bin/anthill`**. Rename that binary (e.g. to `anthill-luanti-engine`) so `anthill` runs this project’s launcher, or call **`/usr/local/bin/anthill`** explicitly.

## Layout

| Path | Role |
|------|------|
| **`game/anthill/`** | Godot 4 project (voxels, sand physics, ant) |
| **`docs/cursor-agent-shell.md`** | Notes if the Cursor agent shell misbehaves |

### Cursor: agent terminal

If the Cursor agent’s **Shell** tool shows **no output** or **does not create files** here, see **`docs/cursor-agent-shell.md`**.
