## An animation controller for 2D sprites
## Also adds a behaviour that automatically goes back into the
## idle state once a non-looping animation finishes)
## (If a FlipSymmetry is being used with this sprite,
## use [[flip]] instead of [[flip_h]] to apply
## the symmetry mechanism.)
class_name SpriteAnimator2D
extends AnimatedSprite2D

## Called when the 'flip_h' property has changed
signal flipped()

var p_lock_timer: Timer
var p_callbacks: Array[CallbackData]

@export
var m_idle_animation = &"default"

@export
var m_callbacks_enabled := true


#region Events

func _ready() -> void:
    p_lock_timer = Timer.new()
    p_lock_timer.one_shot = true
    add_child(p_lock_timer)

    animation_finished.connect(return_to_idle)

    if !m_callbacks_enabled:
        return

    frame_changed.connect(_on_animation_frame_changed)


func _notification(what: int) -> void:
    if what != NOTIFICATION_PREDELETE:
        return

    clear_callbacks()


func _on_animation_frame_changed() -> void:
    for callback: CallbackData in p_callbacks:
        if (callback.m_id != animation ||
            callback.m_frame != frame):
            continue

        callback.p_callback.call()

        # (Because) only one callback per animation/frame at a time
        return

#endregion

#region Functions

## Starts the action and activates the lock
## (Use [[is_locked]] in input processing events.)
## (Use the normal [[play]] method when locks are not needed.)
func fire(id: StringName, lock_mod: float = 1.0) -> void:
    assert(
        is_instance_valid(sprite_frames) && sprite_frames.has_animation(id),
        "SpriteAnimator2D: no animation named \"%s\"" % id
    )

    if animation == id:
        stop()

    p_lock_timer.start(lock_mod * get_action_length(id))
    play(id)


## Plays the idle animation
## (Automatically triggers on non-looping animations)
func return_to_idle() -> void:
    play(m_idle_animation)


## Returns the duration of a specified animation
## (Outputs 0.0 for animations that don't exist)
func get_action_length(id: StringName) -> float:
    var active_frame := sprite_frames
    assert(is_instance_valid(active_frame), "SpriteAnimator2D: sprite has no frames!")

    if !active_frame.has_animation(id):
        return 0.0

    # According to:
    # https://docs.godotengine.org/en/stable/classes/class_spriteframes.html#class-spriteframes-method-get-frame-duration
    var speed_fac := 1.0 / (speed_scale * active_frame.get_animation_speed(id))
    var duration: float = 0.0

    for i: int in active_frame.get_frame_count(id):
        duration += speed_fac * active_frame.get_frame_duration(id, i)

    return duration


## Removes all registered callbacks
func clear_callbacks() -> void:
    for callback in p_callbacks:
        if !is_instance_valid(callback):
            continue

        callback.free()
    p_callbacks.clear()


## Adds a callback to trigger on a specified frame
func register_callback(anim_id: StringName,
                       frame_num: int,
                       callback: Callable,
                       overwrite := true) -> void:

    assert(
        m_callbacks_enabled,
        "SpriteAnimator2D: Trying to add a callback to a sprite that doesn't support callbacks."
    )

    var idx := __find(anim_id, frame_num)

    if idx != -1:
        if overwrite:
            p_callbacks[idx].p_callback = callback
            return
        return

    p_callbacks.append(CallbackData.new(anim_id, frame_num, callback))


## Removes a callback
func unregister_callback(anim_id: StringName,
                         frame_num: int) -> void:

    var idx := __find(anim_id, frame_num)

    if idx == -1:
        return

    p_callbacks[idx].free()
    p_callbacks.remove_at(idx)

#endregion

#region Utils

func __find(id: StringName, frame_num: int) -> int:
    for i: int in range(p_callbacks.size()):
        if p_callbacks[i].m_id != id || p_callbacks[i].m_frame != frame_num:
            continue
        return i
    return -1

#endregion

#region Properties

## Returns true for the duration of an action playback
var is_locked: bool :
    get():
        return !p_lock_timer.is_stopped()


## Helper for FlipSymmetry
## Has the same effect as setting/getting [[flip_h]]
var flip: bool :
    get():
        return flip_h

    set(value):
        flip_h = value
        flipped.emit()

#endregion

#region Callback Data

class CallbackData extends Object:
    var m_id: StringName
    var m_frame: int
    var p_callback: Callable

    func _init(animation_id: StringName, frame: int, callback: Callable) -> void:
        m_id = animation_id
        m_frame = frame
        p_callback = callback

#endregion
