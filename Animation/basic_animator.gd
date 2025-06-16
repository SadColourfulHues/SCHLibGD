## A simplified version of Animator that focuses on a cross-fade action
## playback. The idle state can be provided by a single animation track
## or through one or more blenders.
class_name BasicAnimator
extends AnimationTree

## Fired when an action has started playback
signal action_started(id: StringName, duration: float)

const BL_SNAP := Utils.DEFAULT_LSNAP_EDGE

const BKEY_SEEK := &"parameters/active_seek/seek_request"
const AKEY_ACTIVE := &"parameters/active/request"
const AKEY_NEXT := &"parameters/next/request"

var p_paths: Dictionary[StringName, StringName]
var p_actlens: Dictionary[StringName, float]

var p_prefade_shutdown_timer: Timer
var p_action_timer: Timer

var p_active_one_shot: AnimationNodeOneShot
var p_next_one_shot: AnimationNodeOneShot
var p_anim_active: AnimationNodeAnimation
var p_anim_next: AnimationNodeAnimation

var m_active_animation_id: StringName
var m_active_length: float = 0.0


#region Functions

func fire(id: StringName,
		  fade_in: float = 0.15,
		  fade_out: float = 0.2) -> float:

	var length := get_action_length(id)

	assert(length > 0.0, "BasicAnimator: invalid animation ID")

	if !m_active_animation_id.is_empty() && !p_action_timer.is_stopped():
		var offset := m_active_length - p_action_timer.time_left
		p_anim_active.animation = m_active_animation_id

		# Prevent animations from 'bleeding through' if the remaining length
		# from the previous animation is longer than the current one
		if (m_active_animation_id == id ||
			((m_active_length - offset) >= (length - (fade_in + fade_out)))):

			p_prefade_shutdown_timer.start(0.25 * length)
		else:
			p_prefade_shutdown_timer.stop()

		set(BKEY_SEEK, offset)
		set(AKEY_ACTIVE, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	p_next_one_shot.fadein_time = fade_in
	p_next_one_shot.fadeout_time = fade_out

	p_anim_next.animation = id
	p_action_timer.start(length)
	set(AKEY_NEXT, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	m_active_animation_id = id
	m_active_length = length

	action_started.emit(id, length)
	return length


## Creates the necessary tree nodes to make the animator functional
## Make sure to call this before any of the animator functions!
func initialise(blenders: Array[AnimatorPartBlend2] = [],
				root_anim: StringName = &"") -> void:

	#### Initialise Timers ####
	if !is_instance_valid(p_action_timer):
		## Action Timer ##
		p_action_timer = Timer.new()
		p_action_timer.one_shot = true

		p_action_timer.timeout.connect(func():
			set(AKEY_NEXT, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
		)

		## Shutdown Timer ##
		p_prefade_shutdown_timer = Timer.new()
		p_prefade_shutdown_timer.one_shot = true

		p_prefade_shutdown_timer.timeout.connect(func():
			set(AKEY_ACTIVE, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
		)

		match callback_mode_process:
			ANIMATION_CALLBACK_MODE_PROCESS_IDLE:
				p_action_timer.process_callback = Timer.TIMER_PROCESS_IDLE
				p_prefade_shutdown_timer.process_callback = Timer.TIMER_PROCESS_IDLE

			ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS:
				p_action_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
				p_prefade_shutdown_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS

		add_child(p_action_timer)
		add_child(p_prefade_shutdown_timer)

	#### Initialise Tree ####

	var blend_count := blenders.size()

	assert(
		blend_count > 0 || !root_anim.is_empty(),
		"BasicAnimator: provide at least one blender, or a root animation for initialisation to complete."
	)

	var root := AnimationNodeBlendTree.new()
	var head_id: StringName = &""

	### Pre Pass ###

	# Generate blends
	for blender: AnimatorPartBlend2 in blenders:
		var node = blender.generate(self)
		root.add_node(blender.m_id, node)
		head_id = blender.m_id

	# Generate main action setup
	p_anim_active = __push_action_node(&"active", root, __make_anim_node_active)
	p_anim_next = __push_action_node(&"next", root, __make_anim_node_next)
	p_next_one_shot = root.get_node(&"next")
	p_active_one_shot = root.get_node(&"active")

	### Connection Pass ###

	# Connect Blenders #
	for i: int in range(blend_count):
		blenders[i].connect_inputs(&"" if i == 0 else blenders[i-1].m_id, root)

	# Finalise connections #
	root.connect_node(&"next", 0, &"active")

	if blend_count > 0:
		# head of blenders -> actions
		root.connect_node(&"active", 0, head_id)
	else:
		var root_anim_node := AnimationNodeAnimation.new()
		root.add_node(&"root_anim", root_anim_node)

		# root animation -> actions
		root.connect_node(&"active", 0, &"root_anim")

	# head of actions -> output
	root.connect_node(&"output", 0, &"next")

	# For debugging purposes
	tree_root = root


## If set to true, the animator will stop at the current frame
## freezing all of its processes until it gets unpaused, or deleted
func set_paused(paused: bool) -> void:
	Utils.atpause(self, paused)


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

#region Utils

func __get_blendpath(id: StringName) -> StringName:
	var stored: StringName = p_paths.get(id, &"")

	if stored != &"":
		return stored

	var path = &"parameters/%s/blend_amount" % id
	p_paths[id] = path

	return path


func __make_anim_node_next(id: StringName,
						   tree: AnimationNodeBlendTree) -> AnimationNode:

	var input := AnimationNodeAnimation.new()

	tree.add_node(&"next_input", input)
	tree.connect_node(id, 1, &"next_input")

	return input


func __make_anim_node_active(id: StringName,
							 tree: AnimationNodeBlendTree) -> AnimationNode:

	var input := AnimationNodeAnimation.new()

	tree.add_node(&"active_input", input)
	tree.add_node(&"active_seek", AnimationNodeTimeSeek.new())

	tree.connect_node(&"active_seek", 0, &"active_input")
	tree.connect_node(id, 1, &"active_seek")

	return input


func __push_action_node(id: StringName,
						tree: AnimationNodeBlendTree,
						make_anim_node_callback: Callable) -> AnimationNodeAnimation:

	var one_shot := AnimationNodeOneShot.new()
	tree.add_node(id, one_shot)

	return make_anim_node_callback.call(id, tree)

#endregion

#region Blenders

func set_blend(id: StringName, fac: float) -> void:
	set(__get_blendpath(id, ), fac)


func lerp_blend(id: StringName, fac: float, weight: float = 0.1) -> void:
	var key := __get_blendpath(id)
	return set(key, Utils.blsnap(float(get(key)), fac, weight, BL_SNAP))


func tween_blend(id: StringName,
				fac: float,
				duration: float = 0.33,
				ease_type := Tween.EaseType.EASE_IN,
				trans_type := Tween.TransitionType.TRANS_SINE) -> Tween:

	var key: String = __get_blendpath(id)
	var tween := create_tween()

	(
		tween.tween_property(self, key, fac, duration)
			.set_ease(ease_type)
			.set_trans(trans_type)
	)

	return tween

#endregion

#region Properties

## Returns true if the animator has a currently-playing action
var is_playing: bool:
	get():
		return !p_action_timer.is_stopped()

#endregion
