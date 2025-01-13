## A high-level controller for AnimationTree-based animators
## (Note: the purpose of this node is to provide an -often- faster-to-setup alternative to
## creating blend trees, or as an added utility for editor-pregenerated ones.)
@tool
class_name Animator
extends AnimationTree

@export_tool_button("Pre-Generate", "AnimationTree")
var editor_pregen_button = __editor_generate_tree_action

@export
var p_parts: Array[AnimatorPart]

var p_key_paths: Dictionary[StringName, StringName]
var p_action_lengths: Dictionary[StringName, float]


#region Events

func _ready() -> void:
	if Engine.is_editor_hint() || p_parts.is_empty():
		return

	generate()


#endregion

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


## Generates a blend tree and clears the parts array
func generate(root_id_override: StringName = &"") -> void:
	var part_count := p_parts.size()

	if part_count < 1:
		printerr("Animator: warning: empty parts on tree generation")
		return

	# Prepare parts #
	var root := AnimationNodeBlendTree.new()

	for part: AnimatorPart in p_parts:
		var node := part.generate(self)
		root.add_node(part.m_id, node)

	# Finalise inputs #
	if part_count == 1:
		p_parts[0].connect_inputs(&"", root)
	else:
		for i: int in range(part_count):
			p_parts[i].connect_inputs(&"" if i == 0 else p_parts[i-1].m_id, root)

	if root_id_override.is_empty():
		root.connect_node(&"output", 0, p_parts[-1].m_id)
	else:
		root.connect_node(&"output", 0, root_id_override)

	for part: AnimatorPart in p_parts:
		part.apply_default_value.call_deferred(self)

	if !Engine.is_editor_hint():
		p_parts.clear.call_deferred()

	tree_root = root


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


func lerp_blend(id: StringName, fac: float, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/blend_amount")
	return set(key, lerp(float(get(key)), fac, weight))


func lerp_blendspace(id: StringName, fac: float, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/blend_position")
	return set(key, lerp(float(get(key)), fac, weight))


func lerp_blendspace_2d(id: StringName, fac: Vector2, weight: float = 0.1) -> void:
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