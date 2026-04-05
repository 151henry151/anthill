extends Object
class_name SpoilDeposit
## Random offsets for surface spoil / mound placement around a nest center (voxel grid).

## Uniform area on a disk: **r = sqrt(u) × max_radius**, **θ** uniform. Re-roll if **r < inner_clear**
## (keeps the entrance clear; matches a circular “no deposit” zone better than an axis-aligned square).
static func random_offset_disk(rng: RandomNumberGenerator, max_radius: int, inner_clear: float) -> Vector2i:
	for _i in range(64):
		var theta: float = rng.randf() * TAU
		var u: float = rng.randf()
		var dist: float = sqrt(u) * float(max_radius)
		if dist < inner_clear:
			continue
		var dx: int = int(round(cos(theta) * dist))
		var dz: int = int(round(sin(theta) * dist))
		return Vector2i(dx, dz)
	return Vector2i(max_radius, 0)
