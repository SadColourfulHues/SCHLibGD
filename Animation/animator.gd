## A high-level controller for blend-tree based animators
## (Note: the purpose of this node is to provide an -often- faster-to-setup alternative to
## creating blend trees, or as an added utility for editor-pregenerated ones.)
@tool
class_name Animator
extends AnimationTree

const DBA_FORMAT := [&"%s_a", &"%s_b"]

@export_tool_button("Pre-Generate", "AnimationTree")
var editor_pregen_button = __editor_generate_tree_action

@export
var p_parts: Array[AnimatorPart]

@export
var m_bl_snap_override := Utils.DEFAULT_LSNAP_EDGE

var p_dbaction_state: Dictionary[StringName, bool]

var p_key_paths: Dictionary[StringName, StringName]
var p_action_lengths: Dictionary[StringName, float]

var p_original_root: AnimationNodeBlendTree = null


#region Functions

## Returns the length of the specified animation track
## (Note: use the actual animation name -- including its library -- instead of the action key)
func get_action_length(action_id: StringName) -> float:
	var cached_length: float = p_action_lengths.get(action_id, -1.0)

	if cached_length != -1.0:
		return cached_length

	if !has_animation(action_id):
		print_debug("Animator: tried to get length of nonexistent action \"%s\"" % action_id)
		return 0.0

	var length := get_animation(action_id).length
	p_action_lengths[action_id] = length

	return length


## @experimental: partial generation is currently experimental
## Generates a blend tree and clears the parts array
## [param gen_root_id]
## The name of the part to use as the root of the
## generated nodes.
## [param root_id]
## When set, this method will be ran in partial-generation mode.
## The newly-generated section will be attached to the node specified
## by this parameter.
## This can be used to add repetitive attachments to specialised blend
## trees. e.g. generic actions mixed with specially-configured
## blenders done in-editor.
## (Note: partial generation expects a valid [[AnimationNodeBlendTree]] as
## the tree's root. Additionally, nodes on the original tree will not have
## their values pre-initialised: which may cause issues with lerp/tween
## related functionality. Simply call the appropriate set_* method on them
## to initialise them.)
func generate(gen_root_id: StringName = &"",
			  root_id: StringName = &"",
			  root_connect_idx: int = 0) -> void:

	var part_count := p_parts.size()
	var partial_mode := !root_id.is_empty()

	if part_count < 1:
		printerr("Animator: warning: empty parts on tree generation")
		return

	# Prepare tree for generation #
	var root: AnimationNodeBlendTree

	if partial_mode:
		# Keep the original tree in memory when using partial generation
		# to allow for subsequent re-generations
		if tree_root == null || tree_root is not AnimationNodeBlendTree:
			printerr("Animator: to use partial-generation, ensure that there is a valid AnimationNodeBlendTree root set on this object.")
			return

		if p_original_root == null:
			p_original_root = tree_root

		root = p_original_root.duplicate()
		root.disconnect_node(&"output", 0)
	else:
		root = AnimationNodeBlendTree.new()

	# Pre-pass: generate nodes + inputs
	for part: AnimatorPart in p_parts:
		var node := part.generate(self)
		root.add_node(part.m_id, node)

	# Handle node connections
	if part_count == 1:
		p_parts[0].connect_inputs(&"", root)
	else:
		for i: int in range(part_count):
			p_parts[i].connect_inputs(&"" if i == 0 else p_parts[i-1].m_id, root)

	# Connect the 'root' of the generated nodes to the output
	root.connect_node(
		&"output",
		0,
		p_parts[-1].m_id if gen_root_id.is_empty() else gen_root_id
	)

	for part: AnimatorPart in p_parts:
		part.apply_default_value.call_deferred(self)

	# (partial-gen) join the old and new connectionss at the specified point
	if partial_mode:
		root.connect_node(p_parts[0].m_id, root_connect_idx, root_id)

	if !Engine.is_editor_hint():
		p_parts.clear.call_deferred()

	tree_root = root


## Gets the current positional root motion
func get_root_motion(body: Node3D, delta: float, apply_rotation: bool = true) -> Vector3:
	return Utils.atgetrootmotion(body, self, delta, apply_rotation)


## Fades out all one-shot actions except the specified ID (setting it to empty fades everything)
func action_fade_except(action_id: StringName = &"") -> void:
	var path = &"" if action_id.is_empty() else __get_key(action_id, &"parameters/%s/request")

	for id: StringName in p_key_paths.values():
		if !id.ends_with(&"request"):
			continue

		if path == id:
			continue

		set(id, AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)


## Aborts all one-shot actions except the specified ID (setting it to empty stops everything)
func action_stop_except(action_id: StringName = &"") -> void:
	var path = &"" if action_id.is_empty() else __get_key(action_id, &"parameters/%s/request")

	for id: StringName in p_key_paths.values():
		if !id.ends_with(&"request"):
			continue

		if path == id:
			continue

		set(id, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)


#endregion

#region Utils

func __get_key(property_id: StringName, path_format: StringName) -> StringName:
	if !p_key_paths.has(property_id):
		var path := StringName(path_format % property_id)
		p_key_paths[property_id] = path

		return path

	return p_key_paths[property_id]


func __editor_generate_tree_action() -> void:
	if !Engine.is_editor_hint():
		return

	generate()

#endregion

#region Setters

func action_fire(id: StringName) -> void:
	set(__get_key(id, &"parameters/%s/request"), AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func action_stop(id: StringName) -> void:
	set(__get_key(id, &"parameters/%s/request"), AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)


func action_fade_out(id: StringName) -> void:
	set(__get_key(id, &"parameters/%s/request"), AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)


func action_is_playing(id: StringName) -> bool:
	return get(__get_key(id, &"parameters/%s/active"))


func trans_set_state(id: StringName, state: StringName) -> void:
	set(__get_key(id, &"parameters/%s/transition_request"), state)


func set_blend(id: StringName, fac: float) -> void:
	set(__get_key(id, &"parameters/%s/blend_amount"), fac)


func set_blendspace(id: StringName, value: float) -> void:
	set(__get_key(id, &"parameters/%s/blend_position"), value)


func set_blendspace_2d(id: StringName, value: Vector2) -> void:
	set(__get_key(id, &"parameters/%s/blend_position"), value)


func set_time_scale(id: StringName, scale: float) -> void:
	set(__get_key(id, &"parameters/%s/scale"), scale)


func seek(id: StringName, amount: float) -> void:
	var key := __get_key(id, &"parameters/%s/seek_request")

	if is_zero_approx(amount):
		return

	set(key, amount)


func lerp_blend(id: StringName, fac: float, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/blend_amount")
	return set(key, Utils.blsnap(float(get(key)), fac, weight, m_bl_snap_override))


func lerp_blendspace(id: StringName, fac: float, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/blend_position")
	return set(key, Utils.blsnap(float(get(key)), fac, weight, m_bl_snap_override))


func lerp_blendspace_2d(id: StringName, fac: Vector2, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/blend_position")
	return set(key, Utils.v2blsnap(get(key), fac, weight, m_bl_snap_override))


func lerpnosnap_blend(id: StringName, fac: float, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/blend_amount")
	return set(key, lerp(float(get(key)), fac, weight))


func lerpnosnap_blendspace(id: StringName, fac: float, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/blend_position")
	return set(key, lerp(float(get(key)), fac, weight))


func lerpnosnap_blendspace_2d(id: StringName, fac: Vector2, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/blend_position")
	return set(key, Vector2(get(key)).lerp(fac, weight))


func lerp_time_scale(id: StringName, fac: float, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/scale")
	return set(key, lerp(float(get(key)), fac, weight))


#endregion

#region Animated

func tween_blend(id: StringName,
				fac: float,
				duration: float = 0.33,
				ease_type := Tween.EaseType.EASE_IN,
				trans_type := Tween.TransitionType.TRANS_SINE) -> Tween:

	var key: String = __get_key(id, &"parameters/%s/blend_amount")
	var tween := create_tween()

	(
		tween.tween_property(self, key, fac, duration)
			.set_ease(ease_type)
			.set_trans(trans_type)
	)

	return tween


func tween_blendspace(id: StringName,
				fac: float,
				duration: float = 0.33,
				ease_type := Tween.EaseType.EASE_IN,
				trans_type := Tween.TransitionType.TRANS_SINE) -> Tween:

	var key: String = __get_key(id, &"parameters/%s/blend_position")
	var tween := create_tween()

	(
		tween.tween_property(self, key, fac, duration)
			.set_ease(ease_type)
			.set_trans(trans_type)
	)

	return tween


func tween_blendspace_2d(id: StringName,
				fac: Vector2,
				duration: float = 0.33,
				ease_type := Tween.EaseType.EASE_IN,
				trans_type := Tween.TransitionType.TRANS_SINE) -> Tween:

	var key: String = __get_key(id, &"parameters/%s/blend_position")
	var tween := create_tween()

	(
		tween.tween_property(self, key, fac, duration)
			.set_ease(ease_type)
			.set_trans(trans_type)
	)

	return tween


func tween_time_scale(id: StringName,
				fac: float,
				duration: float = 0.33,
				ease_type := Tween.EaseType.EASE_IN,
				trans_type := Tween.TransitionType.TRANS_SINE) -> Tween:

	var key: String = __get_key(id, &"parameters/%s/scale")
	var tween := create_tween()

	(
		tween.tween_property(self, key, fac, duration)
			.set_ease(ease_type)
			.set_trans(trans_type)
	)

	return tween


#endregion

#region Special Actions

## ~ push_(doubly-backed)action ~
## (use before [[generate]])
## Adds two one shot nodes to allow certain actions to be played
## back-to-back with crossfade support
func dbaction_push(base_id: StringName,
				   fade_in: float = 0.25,
				   fade_out: float = 0.25) -> void:

	if p_dbaction_state.has(base_id):
		return

	for dbid: StringName in DBA_FORMAT:
		p_parts.append(
			AnimatorPartOneShot.from_with_id(dbid % base_id, base_id, fade_in, fade_out)
		)

	p_dbaction_state[base_id] = false


## Fires a doubly-backed action.
## It must be first registered using [[dbaction_push]]
func dbaction_fire(base_id: StringName) -> void:
	var state: bool = p_dbaction_state[base_id]
	var base_action := DBA_FORMAT[0] % base_id
	var alt_action := DBA_FORMAT[1] % base_id

	action_fade_out(base_action if state else alt_action)
	action_fire(alt_action if state else base_action)

	p_dbaction_state[base_id] = !state


## Gets the current animation ID or
## animation node path (OneShot request) for a doubly-backed action
## (It must be first registered using [[dbaction_push]]
## (This method flips its state once it has been called.)
## (Use for custom action firing methods.)
func dbaction_get_id(base_id: StringName, to_path: bool = true) -> StringName:
	var state := p_dbaction_state[base_id]
	p_dbaction_state[base_id] = !state

	var id: StringName = DBA_FORMAT[1 if state else 0] % base_id

	if to_path:
		return __get_key(id, &"parameters/%s/request")

	return id


## Returns true if the specified ID is a doubly-backed action
func dbaction_is(base_id: StringName) -> bool:
	return p_dbaction_state.has(base_id)

#endregion
