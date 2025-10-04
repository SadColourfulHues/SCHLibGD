## An AnimationTree controller that uses AnimationNodeStateMachine as its internal node
## (Use [[Animator]] or [[SyncedAnimator]] if you need to customise behaviour further,
## e.g. the state animator currently doesn't have anything to help with timescaling.)
class_name StateAnimator
extends AnimationTree

const SM_AT_END := AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_AT_END
const SM_INSTANT := AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_IMMEDIATE
const SM_SYNC := AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_SYNC

const AM_AUTO := AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
const AM_NORMAL := AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED

@export
var m_bl_snap_override := Utils.DEFAULT_LSNAP_EDGE

var p_paths: Dictionary[StringName, StringName]
var p_actlens: Dictionary[StringName, float]

var p_sm: AnimationNodeStateMachine
var p_playback: AnimationNodeStateMachinePlayback

var p_transition_fade_curve: Curve = null
var m_transition_switch_mode := SM_INSTANT
var m_transition_advance_mode := AM_NORMAL
var m_transition_reset := false
var m_transition_priority := 1


#region Events

func _init() -> void:
	reset()

#endregion

#region Playback

## Equivalent to calling start on the tree's playback object
func start(id: StringName, reset_playback := true) -> void:
	assert(p_sm.has_node(id), "StateAnimator: invalid node ID \"%s\"" % id)
	p_playback.start(id, reset_playback)


## Equivalent to calling jump on the tree's playback object
func jump(id: StringName, reset_on_teleport := true) -> void:
	assert(p_sm.has_node(id), "StateAnimator: invalid node ID \"%s\"" % id)
	p_playback.jump(id, reset_on_teleport)


## Equivalent to calling travel on the tree's playback object
func travel(id: StringName, reset_on_teleport := true) -> void:
	assert(p_sm.has_node(id), "StateAnimator: invalid node ID \"%s\"" % id)
	p_playback.travel(id, reset_on_teleport)

#endregion

#region Configuration

## Sets whether or not the return transition should reset on subsequent [[connect_return]] calls
func transition_reset(do_reset: bool) -> StateAnimator:
	m_transition_reset = do_reset
	return self

## Sets the switch mode of transitions used by subsequent 'connect_*' calls
func transition_switch_mode(mode: AnimationNodeStateMachineTransition.SwitchMode) -> StateAnimator:
	m_transition_switch_mode = mode
	return self


## Sets the priority of transitions used by subsequent 'connect_*' calls
func transition_priority(priority: int) -> StateAnimator:
	m_transition_priority = priority
	return self


## Sets whether or not transitions used by subsequent 'connect_*' calls
## uses the 'auto' advance mode
func transition_auto_advance(yes: bool) -> StateAnimator:
	m_transition_advance_mode = AM_AUTO if yes else AM_NORMAL
	return self


## Sets the fade curve of transitions used by subsequent 'connect_*' calls
func transition_curve(curve: Curve) -> StateAnimator:
	p_transition_fade_curve = curve
	return self


## Resets the state of the state machine
func reset() -> void:
	p_sm = AnimationNodeStateMachine.new()
	tree_root = p_sm

	p_playback = get(&"parameters/playback")


## Quickly sets up a single root -> actions tree using the specified animations
func fast_root_setup(return_id: StringName,
					 fade_time: float,
					 instant_mode: bool,
					 ...action_ids: Array) -> void:

	# Because typed arrays are still broken somehow
	var actual_array: Array[StringName]
	actual_array.append_array(action_ids)

	push_animations(actual_array)
	connect_multi(return_id, fade_time, actual_array)
	connect_return(return_id, fade_time, instant_mode, actual_array)

	connect_entry(return_id)


## Adds a specified animation to the state machine
## (Its ID will be used as the node name)
func push_animation(id: StringName) -> void:
	assert(has_animation(id), "StateAnimator: invalid animation ID \"%s\"" % id)
	assert(!p_sm.has_node(id), "StateAnimator: attempted to add duplicate ID \"%s\"" % id)

	var node := AnimationNodeAnimation.new()
	node.animation = id

	p_sm.add_node(id, node)


## Adds a list of specified animations to the state machine
## (Its ID will be used as the node name)
func push_animations(ids: Array[StringName]) -> void:
	for id: StringName in ids:
		assert(has_animation(id), "StateAnimator: invalid animation ID \"%s\"" % id)
		assert(!p_sm.has_node(id), "StateAnimator: attempted to add duplicate ID \"%s\"" % id)

		var node := AnimationNodeAnimation.new()
		node.animation = id

		p_sm.add_node(id, node)


## adds a blendspace with the specified IDs at specified positions
func push_blend(id: StringName,
				default_blend: float,
				blends: Dictionary[StringName, float]) -> void:

	assert(!p_sm.has_node(id), "StateAnimator: attempted to add duplicate ID \"%s\"" % id)

	var ids: Array[StringName] = blends.keys()
	var positions: Array[float] = blends.values()

	var blendspace := AnimationNodeBlendSpace1D.new()

	for i: int in range(blends.size()):
		assert(has_animation(ids[i]), "StateAnimator: invalid animation ID \"%s\"" % ids[i])

		var anim_node := AnimationNodeAnimation.new()
		anim_node.animation = ids[i]

		blendspace.add_blend_point(anim_node, positions[i])

	set_blendspace(id, default_blend)
	p_sm.add_node(id, blendspace)


## adds a 2D blendspace with the specified IDs at specified positions
func push_blend2(id: StringName,
				 default_blend: Vector2,
				 blends: Dictionary[StringName, Vector2]) -> void:

	assert(!p_sm.has_node(id), "StateAnimator: attempted to add duplicate ID \"%s\"" % id)

	var ids: Array[StringName] = blends.keys()
	var positions: Array[Vector2] = blends.values()

	var blendspace := AnimationNodeBlendSpace2D.new()

	for i: int in range(blends.size()):
		assert(has_animation(ids[i]), "StateAnimator: invalid animation ID \"%s\"" % ids[i])

		var anim_node := AnimationNodeAnimation.new()
		anim_node.animation = ids[i]

		blendspace.add_blend_point(anim_node, positions[i])

	set_blendspace_2d(id, default_blend)
	p_sm.add_node(id, blendspace)


## Adds a single transition from one specified node to another
func connect_single(id: StringName,
					to: StringName,
					fade_time: float = 0.15) -> void:

	assert(p_sm.has_node(id), "StateAnimator: invalid node ID \"%s\"" % id)
	assert(p_sm.has_node(to), "StateAnimator: invalid target ID \"%s\"" % to)

	var transition := __make_transition(fade_time)
	p_sm.add_transition(id, to, transition)


## Adds transitions from the specified node to a list of target nodes
func connect_multi(id: StringName,
				   fade_time: float,
				   to: Array[StringName]) -> void:

	assert(p_sm.has_node(id), "StateAnimator: invalid node ID \"%s\"" % id)

	var transition := __make_transition(fade_time)

	for node_id: StringName in to:
		assert(p_sm.has_node(node_id), &"StateAnimator: invalid target ID \"%s\"" % node_id)
		p_sm.add_transition(id, node_id, transition)


## Adds a "return" transition from the specified nodes to the target node
func connect_return(target: StringName,
					fade_time: float,
					instant_mode: bool,
					from: Array[StringName]) -> void:

	assert(p_sm.has_node(target), "StateAnimator: invalid target ID \"%s\"" % target)

	var transition := __make_transition(fade_time)
	transition.reset = m_transition_reset
	transition.advance_mode = AM_AUTO if instant_mode else AM_NORMAL

	for node_id: StringName in from:
		assert(p_sm.has_node(node_id), "StateAnimator: invalid node ID \"%s\"" % node_id)
		p_sm.add_transition(node_id, target, transition)


## Connects one or more nodes to the state machine's start node
func connect_entry(...node_ids: Array) -> void:
	var transition := AnimationNodeStateMachineTransition.new()
	transition.advance_mode = AM_AUTO
	transition.switch_mode = SM_INSTANT

	for node_id: StringName in node_ids:
		assert(p_sm.has_node(node_id), "StateAnimator: invalid node ID \"%s\"" % node_id)
		p_sm.add_transition(&"Start", node_id, transition)


## Connects one or more nodes to the state machine's exit node
func connect_exit(auto_advance: bool, ...node_ids: Array) -> void:
	var transition := AnimationNodeStateMachineTransition.new()
	transition.advance_mode = AM_AUTO if auto_advance else AM_NORMAL
	transition.switch_mode = SM_AT_END

	for node_id: StringName in node_ids:
		assert(p_sm.has_node(node_id), "StateAnimator: invalid node ID \"%s\"" % node_id)
		p_sm.add_transition(node_id, &"End", transition)


#endregion

#region Utils

func __get_key(id: StringName, format: StringName) -> StringName:
	var stored: StringName = p_paths.get(id, &"")

	if stored != &"":
		return stored

	var path = format % id
	p_paths[id] = path

	return path


func __make_transition(fade_time: float) -> AnimationNodeStateMachineTransition:
	var transition := AnimationNodeStateMachineTransition.new()
	transition.advance_mode = m_transition_advance_mode
	transition.switch_mode = m_transition_switch_mode
	transition.priority = m_transition_priority

	if is_instance_valid(p_transition_fade_curve):
		transition.xfade_curve = p_transition_fade_curve

	transition.xfade_time = fade_time

	return transition


## Returns the length of the specified animation track
## (Note: use the actual animation name -- including its library -- instead of the action key)
func get_action_length(action_id: StringName) -> float:
	var cached_length: float = p_actlens.get(action_id, -1.0)

	if cached_length != -1.0:
		return cached_length

	if !has_animation(action_id):
		print_debug("Animator: tried to get length of nonexistent action \"%s\"" % action_id)
		return 0.0

	var length := get_animation(action_id).length
	p_actlens[action_id] = length

	return length

#endregion

#region Setters

func set_blendspace(id: StringName, value: float) -> void:
	set(__get_key(id, &"parameters/%s/blend_position"), value)


func set_blendspace_2d(id: StringName, value: Vector2) -> void:
	set(__get_key(id, &"parameters/%s/blend_position"), value)


func lerp_blendspace(id: StringName, fac: float, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/blend_position")
	return set(key, Utils.blsnap(float(get(key)), fac, weight, m_bl_snap_override))


func lerp_blendspace_2d(id: StringName, fac: Vector2, weight: float = 0.1) -> void:
	var key := __get_key(id, &"parameters/%s/blend_position")
	return set(key, Utils.v2blsnap(get(key), fac, weight, m_bl_snap_override))

#endregion

#region Animated Setters

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

#endregion
