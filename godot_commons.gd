## Basically GodotCommons + extras for GDscript
class_name Utils

const DEFAULT_LSNAP_EDGE := 0.025


#region Maths

## (Blend[Lerp]snap)
## Returns a float that is [[w]]% between [[a]] and [[b]].
## It will snap to either extreme edge (0.0 - 1.0) when [[d]] distance is reached
## Meant to be used with lerps used in animation blending to prevent
## needless event callbacks.
static func blsnap(a: float,
				  b: float,
				  w: float,
				  d: float = DEFAULT_LSNAP_EDGE) -> float:

	var lv: float = lerp(a, b, w)

	# Distance to extreme edges
	var da: float = abs(0.0 - lv)
	var db: float = abs(1.0 - lv)

	# Snap
	if da < d || db < d:
		return 0.0 if (min(da, db) == da) else 1.0

	return lv


## Alternate smoothing function.
## (Decay should be a value ranging between 1 (slow) to 25 (fast))
## [From https://www.youtube.com/watch?v=LSNQuFEDOyQ]
static func fhexpdecay(a: float,
					b: float,
					decay: float,
					delta: float) -> float:

	return b + (a - b) * exp(-decay * delta)


## ([Vector2]BlendLerpSnap)
## Applies a lerp with edge snapping on a Vector2
## Returns a float that is [[w]]% between [[a]] and [[b]].
## It will snap to either extreme edge (0.0 - 1.0) when [[d]] distance is reached
## (Snapping is done independently on both axes.)
## Meant to be used with lerps used in animation blending to prevent
## needless event callbacks.
static func v2blsnap(a: Vector2,
					b: Vector2,
					w: float,
					d: float = DEFAULT_LSNAP_EDGE) -> Vector2:

	return Vector2(
		blsnap(a.x, b.x, w, d),
		blsnap(a.y, b.y, w, d)
	)


## Alternate smoothing function for Vector2
## (Calls [Utils::fhexpdecay] on each member.)
static func v2fhexpdecay(a: Vector2,
					b: Vector2,
					decay: float,
					delta: float) -> Vector2:

	return Vector2(
		fhexpdecay(a.x, b.x, decay, delta),
		fhexpdecay(a.y, b.y, decay, delta)
	)


## Alternate smoothing function for Vector3
## (Calls [Utils::fhexpdecay] on each member.)
static func v3fhexpdecay(a: Vector3,
					b: Vector3,
					decay: float,
					delta: float) -> Vector3:

	return Vector3(
		fhexpdecay(a.x, b.x, decay, delta),
		fhexpdecay(a.y, b.y, decay, delta),
		fhexpdecay(a.z, b.z, decay, delta)
	)


## Alternate smoothing function for Vector3
## (Calls [Utils::fhexpdecay] on its X and Z members, uses [a]'s Y in the output.)
static func xzfhexpdecay(a: Vector3,
					b: Vector3,
					decay: float,
					delta: float) -> Vector3:

	return Vector3(
		fhexpdecay(a.x, b.x, decay, delta),
		a.y,
		fhexpdecay(a.z, b.z, decay, delta)
	)


## Returns the amount of time passed (in seconds) since [start]
static func secs_since(start: int) -> float:
	return 0.001 * float(Time.get_ticks_msec() - start)


## Similar to [[secs_since]] but with a customisable [[now]] time
static func secs_since_reuse(now: int, start: int) -> float:
	return 0.001 * float(now - start)

## Returns the best angle between [from] and [to]
## (Intended to be used by tweeners)
## https://github.com/godotengine/godot/blob/92e51fca7247c932f95a1662aefc28aca96e8de6/core/math/math_funcs.h#L430
static func shortest_angle(from: float, to: float) -> float:
	return from + angle_difference(from, to)


# Adapted from https://forum.unity.com/threads/left-right-test-function.31420/
static func sideness_test(forward: Vector3, look_dir: Vector3, up := Vector3.UP) -> float:
	return forward.cross(look_dir).dot(up) > 0.0

#endregion

#region Random

## Simple chance roll. ([chance] should be a value between 0 - 100.)
static func roll(chance: int) -> bool:
	return (randi() % 100) < chance

#endregion

#region 3D

## Turns a Vector2 into Vector3, mapping its XY to X, [optional], Y
static func xy2xz(v: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(v.x, y, v.y)


## ([Transform3D]setfwd) Sets the 'forward' axis of a specified transform.
## Set [[current_scale]] to allow scale preservation
static func t3dsetfwd(transform: Transform3D,
					forward: Vector3,
					weight: float = 0.1,
					up: Vector3 = Vector3.UP,
					current_scale: Vector3 = Vector3.ZERO) -> Transform3D:

	var new_trans := transform
	new_trans.basis.z = forward
	new_trans.basis.y = up
	new_trans.basis.x = up.cross(forward)
	new_trans.basis = new_trans.basis.orthonormalized()

	if !current_scale.is_zero_approx():
		new_trans = new_trans.scaled_local(current_scale)

	return transform.interpolate_with(new_trans, weight)


## Returns a new [[Vector3]] with the X and Z values of [[b]] and the Y of [[a]]
static func xz(a: Vector3, b: Vector3) -> Vector3:
	return Vector3(b.x, a.y, b.z)


## Linearly interpolates the XZ members of two Vector3s
static func xzlerp(a: Vector3, b: Vector3, fac: float) -> Vector3:
	return Vector3(
		lerp(a.x, b.x, fac),
		a.y,
		lerp(a.z, b.z, fac)
	)


## Returns a Vector3 that has its XZ values scaled by a value
static func xzscale(v: Vector3, scale: float) -> Vector3:
	return Vector3(v.x * scale, v.y, v.z * scale)


## Returns a flat normalised Vector3 along the XZ axes
static func xzflatten(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z).normalized()

#endregion

#region Animation

## ([Tween]init) Initialises a tween for use [Stops currently-running interpolations if the 'tween' reference is valid and active.]
static func twinit(owner: Node, tween: Tween) -> Tween:
	if is_instance_valid(tween) && tween.is_running():
		tween.kill()

	tween = owner.create_tween()
	return tween


## ([Tween]kill) Stops an active tweener
static func twkill(tween: Tween) -> void:
	if !is_instance_valid(tween) || !tween.is_running():
		return

	tween.kill()


## ([AnimationTree]blend) Blends an animation tree property with a specified value and weight
static func atblend(tree: AnimationTree,
					path: StringName,
					value: Variant,
					weight: float) -> void:

	var previous_value = tree.get(path)
	tree.set(path, lerp(previous_value, value, weight))


## Returns a pointer to a named AnimationNode in the specified tree's root.(Returns null if the root is null or if the node is nonexistent.)
static func atgetnode(tree: AnimationTree,
					node_name: StringName) -> AnimationNode:

	if !is_instance_valid(tree.tree_root):
		return null

	var root := tree.tree_root

	if !root.has_node(node_name):
		return null

	return root.get_node(node_name)


## (Note: for better syncing, prefer using [[RootMotionAccumulator]])
## Returns the root motion 'velocity' of the specified [tree] relative to the [target]'s current rotation.
static func atgetrootmotion(target: Node3D,
							tree: AnimationTree,
							delta: float,
							apply_rotation: bool = true) -> Vector3:

	var rotation := target.quaternion * tree.get_root_motion_rotation()

	if apply_rotation:
		target.quaternion = rotation

	return ((tree.get_root_motion_rotation_accumulator().inverse() * rotation)
		* tree.get_root_motion_position() / delta)


## ([AnimationTree]OneShotFireGeneric)
## Plays a generic animation through the specified Animation->OneShot node setup
static func atosfireg(tree: AnimationTree,
					anim_node: AnimationNodeAnimation,
					one_shot_path: StringName,
					animation_name: StringName) -> void:

	anim_node.animation = animation_name
	tree.set(one_shot_path, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## ([AnimationTree]OneShotFire) Triggers the specified OneShot node
static func atosfire(tree: AnimationTree, path: StringName) -> void:
	tree.set(path, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## ([AnimationTree]OneShotFade) Fades out the specified OneShot node
static func atosfade(tree: AnimationTree, path: StringName) -> void:
	tree.set(path, AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)


## ([AnimationTree]OneShotStop) Stops the specified OneShot node
static func atosstop(tree: AnimationTree, path: StringName) -> void:
	tree.set(path, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)


## ([AnimationTree]Pause) Toggles an animation tree's paused state
static func atpause(atree: AnimationTree,
					paused: bool = true,
					fallback_process_mode := Node.PROCESS_MODE_INHERIT) -> void:

	if paused:
		atree.set_meta(&"__original_process_state", atree.process_mode)
		atree.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		atree.process_mode = atree.get_meta(&"__original_process_state", fallback_process_mode)
		atree.remove_meta(&"__original_process_state")

	# Note: this section may not be needed,
	# but just to be sure to fully deactivate it
	# in case the tree object is doing some extra processing

	atree.set_process(paused)
	atree.set_physics_process(paused)
	atree.set_process_internal(paused)
	atree.set_physics_process_internal(paused)



#endregion

#region Nodes

## [Node]ClearChildren
## Removes all child nodes from [[node]]
static func nchall(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()


## [Node]ClearChildren2D
## Removes all Node2D-based child nodes from [[node]]
static func nch2d(node: Node) -> void:
	for child: Node in node.get_children():
		if child is not Node2D:
			continue

		child.queue_free()


## [Node]ClearChildrenUI
## Removes all Control-based child nodes from [[node]]
static func nchui(node: Node) -> void:
	for child: Node in node.get_children():
		if child is not Control:
			continue

		child.queue_free()


## [Node]ClearChildren3D
## Removes all Node3D-based child nodes from [[node]]
static func nch3d(node: Node) -> void:
	for child: Node in node.get_children():
		if child is not Node3D:
			continue

		child.queue_free()

#endregion

#region Resources

## ** [Resource] sync property to name **
## Synchronises a specified Resource property to its name

## Some prerequisites:
## + This function can only take effect on resources marked as [@tool].
## + [source_name] must point to a property containing a String or StringName value
## + Call this function on the resource's [_validate_property] method, and pass its [property] param to this
static func rsyncprop2name(resource: Resource,
						source_name: StringName,
						property: Dictionary) -> void:

	if !Engine.is_editor_hint() || property[&"name"] != source_name:
		return

	var value: String = resource.get(source_name)

	if resource.resource_name == value:
		return

	resource.resource_name = value
	resource.emit_changed()

#endregion

#region 2D Helpers

## Returns the average distance between [[b]] and [[a]]
static func absdist2d(a: Vector2, b: Vector2) -> float:
	var delta := a - b
	return 0.5 * (abs(delta.x) + abs(delta.y))


## Returns true if A is facing B
## ((Animated)Sprite's flip_h can be used for the facing_left parameter)
static func sideness_test_2d(xa: float, xb: float, facing_left: bool) -> bool:
	return sign(xb - xa) == (-1.0 if facing_left else 1.0)

#endregion
