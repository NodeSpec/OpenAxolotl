class_name WaterSplash
extends RefCounted

## The water reacting to something crossing it (REQ-034, REQ-039).
##
## Crossing the surface is the most physical thing that happens in this game,
## and for a long time it happened in total silence: the grammar switched, the
## animation switched, and the water it went through did not move. A shader
## can make a surface look like water from a distance; nothing but a reaction
## makes it feel like water when you go into it.
##
## TWO PARTS, BECAUSE A SPLASH IS TWO THINGS. A crown of droplets thrown
## upward, which is the body displacing water; and a flat ring spreading
## outward on the surface, which is the wave leaving. Either alone reads as an
## effect, and the pair reads as a splash — the ring is what sells it, because
## it is the part that stays behind after the axolotl has gone under.
##
## SIZED BY HOW HARD YOU HIT IT. A dive from the shelf and a step off a shore
## into shallows are not the same event, so the crown scales with the vertical
## speed at the crossing. Wading gets a small disturbance; a plunge gets a
## sheet. Both cap out, because a body arriving at terminal velocity should
## look dramatic rather than absurd.
##
## Built in code rather than shipped as a scene for the same reason the
## capability-loss burst is: the whole effect is twenty numbers, and twenty
## numbers in a script can explain themselves and be diffed. It also means a
## world gets splashes by placing a WaterVolume and doing nothing else.
##
## CPUParticles3D rather than GPU, deliberately: these are short one-shots of
## a few dozen particles fired at unpredictable moments, which is the case
## where the GPU version's buffer allocation costs more than the simulation it
## saves. The ambient bubble columns in the worlds are the opposite case and
## correctly use GPU particles.

## Droplet counts. The plunge number is not much larger than the wade — past
## about thirty the crown reads as fog rather than as water.
const WADE_DROPS := 10
const PLUNGE_DROPS := 26

## The vertical speed at which the crown reaches full size, in metres per
## second. Above this it stops growing.
const FULL_SPEED := 14.0

const DROP_LIFETIME := 0.55
const RING_LIFETIME := 0.75

## How wide the surface ring opens, in metres, at a wade and at full speed.
const RING_MIN_RADIUS := 0.7
const RING_MAX_RADIUS := 2.6

## Water colours. Droplets take the shared surface's own shallow tint so a
## splash and the water it came out of are the same colour; the ring is nearer
## foam, because that is what a breaking ring is.
const DROP_TINT := Color(0.62, 0.86, 0.9, 0.9)
const RING_TINT := Color(0.85, 0.96, 0.96, 0.75)

## Gravity on the droplets. Heavier than the world's, on purpose: real spray
## at this scale falls back fast, and a slow fall reads as sparks.
const DROP_GRAVITY := Vector3(0.0, -26.0, 0.0)


## Fires a splash at [param at], parented under [param host]'s own tree.
##
## Returns the nodes it made so a caller — or a test — can look at them; the
## effect frees itself either way. A host outside the tree gets nothing rather
## than an orphan, which is the case every headless unit test hits.
static func erupt(host: Node, at: Vector3, speed: float,
		plunging: bool) -> Array[Node]:
	var made: Array[Node] = []
	if host == null or not host.is_inside_tree():
		return made

	var force := force_of(speed)
	var parent := host.get_tree().current_scene
	if parent == null or not parent.is_inside_tree():
		parent = host

	var crown := crown_for(force, plunging)
	parent.add_child(crown)
	crown.global_position = at
	crown.emitting = true
	made.append(crown)

	var ring := ring_for(force)
	parent.add_child(ring)
	ring.global_position = at
	ring.emitting = true
	made.append(ring)

	_reap(host, crown, DROP_LIFETIME)
	_reap(host, ring, RING_LIFETIME)
	return made


## How hard the water was hit, 0..1. Public because it is half of what the
## two builders below mean, and a caller reading `crown_for(0.8, true)` should
## be able to find out where 0.8 comes from.
static func force_of(speed: float) -> float:
	return clampf(speed / FULL_SPEED, 0.0, 1.0)


## The upward crown of droplets.
##
## PUBLIC AND PURE, like HeroAnimator.choose_clip and for the same reason: the
## whole of what a splash IS lives in these numbers, and erupt() cannot be
## called at all outside a running tree — a node added to the root during
## SceneTree._initialize, which is where every unit test in this project
## builds its scenes, is not yet inside it. Testing the effect only through
## erupt() would mean testing it nowhere.
static func crown_for(force: float, plunging: bool) -> CPUParticles3D:
	var drops := CPUParticles3D.new()
	drops.name = "SplashCrown"
	drops.one_shot = true
	drops.explosiveness = 1.0
	drops.amount = PLUNGE_DROPS if plunging else WADE_DROPS
	drops.lifetime = DROP_LIFETIME
	# A cone rather than a sphere: water thrown by something entering goes UP
	# and outward, and a full sphere sends half of it into the riverbed where
	# it is both invisible and wrong.
	drops.direction = Vector3.UP
	drops.spread = 42.0
	drops.initial_velocity_min = 2.0 + 3.0 * force
	drops.initial_velocity_max = 4.0 + 7.0 * force
	drops.gravity = DROP_GRAVITY
	drops.scale_amount_min = 0.05
	drops.scale_amount_max = 0.11 + 0.09 * force
	drops.color = DROP_TINT
	# Emitted off a small disc, so the crown has a mouth rather than coming
	# out of a single point.
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	drops.emission_sphere_radius = 0.25 + 0.35 * force
	drops.mesh = _droplet()
	return drops


## The flat ring leaving across the surface.
static func ring_for(force: float) -> CPUParticles3D:
	var ring := CPUParticles3D.new()
	ring.name = "SplashRing"
	ring.one_shot = true
	ring.explosiveness = 1.0
	ring.amount = 18
	ring.lifetime = RING_LIFETIME
	# Outward and FLAT. Zero gravity and a horizontal spread is what keeps the
	# ring on the surface instead of arcing off it.
	ring.direction = Vector3.RIGHT
	ring.spread = 180.0
	ring.flatness = 1.0
	var radius := RING_MIN_RADIUS + (RING_MAX_RADIUS - RING_MIN_RADIUS) * force
	ring.initial_velocity_min = radius / RING_LIFETIME * 0.6
	ring.initial_velocity_max = radius / RING_LIFETIME
	ring.gravity = Vector3.ZERO
	ring.damping_min = 1.2
	ring.damping_max = 2.4
	ring.scale_amount_min = 0.10
	ring.scale_amount_max = 0.22
	# Shrinking as it spreads is the whole read: a ring that keeps its size
	# looks like debris drifting, and one that fades to nothing looks like a
	# wave running out.
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 1.0))
	taper.add_point(Vector2(1.0, 0.0))
	ring.scale_amount_curve = taper
	ring.color = RING_TINT
	ring.mesh = _droplet()
	return ring


## One droplet. A small quad-ish sphere: at these sizes the silhouette is a
## dot, and paying for a real sphere per droplet buys nothing.
static func _droplet() -> Mesh:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 3
	return mesh


## Frees an effect once it has finished, through the host's tree.
##
## The timer is taken from the HOST rather than the particle node because the
## particle is what is being freed: a timer owned by a node that is about to
## go away is a race, and it is the kind that only shows up when a level
## unloads mid-splash.
static func _reap(host: Node, effect: Node, lifetime: float) -> void:
	var tree := host.get_tree()
	if tree == null:
		effect.queue_free()
		return
	tree.create_timer(lifetime + 0.25).timeout.connect(
		func() -> void:
			if is_instance_valid(effect):
				effect.queue_free())
