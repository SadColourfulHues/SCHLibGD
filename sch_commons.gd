## A collection of utilities that are relevant to my current game-dev workflow
class_name SCHUtils

#region Checks

## ([InputEvent]ButtonGuard)
## Returns true if [event] is not a button-press event (key/controller/mouse)
## (Meant to be used as a guard condition)
static func iebuttonguard(event: InputEvent) -> bool:
	return (
		event is not InputEventKey &&
		event is not InputEventJoypadButton &&
		event is not InputEventMouseButton
	)


## ([InputEvent]SetActionCallback)
## Assigns a button-press handler action [func(e: InputEvent) -> bool]
## [callback] should return true if an action is successfully performed.
## Call on [_input] or [_unhandled_input]
static func iesetactioncallback(event: InputEvent,
								viewport: Viewport,
								callback: Callable) -> void:

	if iebuttonguard(event) || !callback.call(event):
		return

	viewport.set_input_as_handled()

#endregion

#region Animation

## ([Animator]LockMake)
## Convenience method for initialising a lock timer to be used with
## [[aplaywlock]]
static func alockmake(owner: Node) -> Timer:
	var lock := Timer.new()
	lock.one_shot = true

	owner.add_child.call_deferred(lock)
	return lock


## ([Animator]PlayWithLock)
## Handles Animator-based playback with support for doubly-backed actions
## Use [true_id] for special setups where the node ID and animation ID
## are not the same.
static func aplaywlock(animator: Animator,
					   lock: Timer,
					   id: StringName,
					   lock_mod: float = 1.0,
					   fade_not_stop: bool = true,
					   true_id: StringName = &"") -> void:

	# Handle doubly-backed actions
	if animator.dbaction_is(id):
		aplaywlock(
			animator, lock,
			animator.dbaction_get_id(id, false),
			lock_mod, fade_not_stop, id)
		return

	true_id = id if true_id.is_empty() else true_id

	var anim_len := animator.get_action_length(true_id)
	assert(anim_len > 0.0, "aplaywlock: ID \"%s\" doesn't exist" % true_id)

	if fade_not_stop:
		animator.action_fade_except(id)
	else:
		animator.action_stop_except(id)

	animator.action_fire(id)
	lock.start(anim_len * lock_mod)

#endregion

#region Audio

## ([AudioStream3D]PlayWithFade)
## Plays/pauses an [AudioStream3D] with a specified fade duration
static func as3dplaywfade(sfx: AudioStreamPlayer3D,
						playing: bool,
						fade_duration: float = 0.45,
						vol_playing: float = 0.0,
						vol_stopped: float = -80.0) -> Tween:

	if is_equal_approx(sfx.volume_db, vol_playing if playing else vol_stopped):
		return null

	if playing:
		sfx.play()

	var tween := sfx.create_tween()
	tween.tween_property(sfx, ^"volume_db", vol_playing if playing else vol_stopped, fade_duration)

	if !playing:
		tween.tween_callback(sfx.stop)

	return tween

#endregion
