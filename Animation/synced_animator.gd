## A specialised Animator that provides an inbuilt mechanism for
## synchronising action state-changes to reduce the amount of
## playback-related bugs caused by state-change conflicts
## Use the [[request_action]] and [[request_clear]] methods
## to control animation playback.
@tool
class_name ActionStateAnimator
extends Animator

## The type of action clear to use in the next frame
enum StopType
{
    NONE,
    FADE,
    STOP
}

@export_subgroup("Synced Animator")
@export
var m_anim_lock_process_mode := Timer.TimerProcessCallback.TIMER_PROCESS_IDLE

var p_lock: Timer

var p_requested_action_callback: Callable
var m_requested_action_id: StringName
var m_requested_action_true_id: StringName
var m_requested_action_fade: bool
var m_requested_action_lock_mod: float
var m_last_action_priority: int

var m_requested_clear := StopType.NONE


#region Control

## Requests an action to be fired in the next action state sync
## (Unlike [[action_fire]], this does not guarantees that [[action_id]]
## will be played back, specify a callback if post-action processing is required.)
func request_action(action_id: StringName,
                    lock_mod: float,
                    true_id: StringName,
                    fade_out: bool = true,
                    priority: int = 0,
                    callback := Callable()) -> bool:

   if priority <= m_last_action_priority:
       return false

   m_requested_action_id = action_id
   m_requested_action_lock_mod = lock_mod
   m_requested_action_true_id = true_id
   m_requested_action_fade = fade_out
   m_last_action_priority = priority

   p_requested_action_callback = callback
   return true


## Blocks any actions from being requested further and applies the specified
## clear on the next action state sync.
func request_clear(type := StopType.STOP) -> void:
    m_last_action_priority = 1_000_000
    m_requested_clear = type


## Sets the paused state of the animation lock
## Will automatically unpause when a 'clear' command has been synced
## (Useful for timing-modifying events e.g. hitstop)
func set_anim_lock_paused(paused: bool) -> void:
    p_lock.paused = paused

#endregion

#region Events

func _ready() -> void:
    if Engine.is_editor_hint():
        return

    p_lock = Timer.new()
    p_lock.process_callback = m_anim_lock_process_mode
    p_lock.one_shot = true

    add_child.call_deferred(p_lock)
    __reset_request()


func _physics_process(_delta: float) -> void:
    # Sync action clear #
    if m_requested_clear != StopType.NONE:
        match m_requested_clear:
            StopType.FADE:
                action_fade_except()

            StopType.STOP:
                action_stop_except()

        p_lock.stop()

        m_requested_clear = StopType.NONE
        p_lock.paused = false
        __reset_request()

        return

    # Sync action #
    if m_requested_action_id.is_empty():
        return

    if m_requested_action_fade:
        action_fade_except()
    else:
        action_stop_except()

    # Handle doubly-backed actions
    if dbaction_is(m_requested_action_id):
        var dbid := dbaction_get_id(m_requested_action_id, false)
        m_requested_action_true_id = m_requested_action_id
        m_requested_action_id = dbid

    # True IDs are used when more than one animation node is pointing to
    # the same action take. Since Godot (4.4), for some reason, doesn't allow
    # for reuse in its bloody animation system, we'll just have to resort
    # to keeping track of the actual ID for instances when it happens.
    var action_id = (
        m_requested_action_id
        if m_requested_action_true_id.is_empty()
        else m_requested_action_true_id
    )

    action_fire(m_requested_action_id)
    p_lock.start(m_requested_action_lock_mod * get_action_length(action_id))

    if p_requested_action_callback.is_valid():
        p_requested_action_callback.call()

    __reset_request()

#endregion

#region Utils

func __reset_request() -> void:
    p_requested_action_callback = Callable()
    m_requested_action_id = &""
    m_requested_action_true_id = &""
    m_requested_action_lock_mod = 1.0
    m_requested_action_fade = true
    m_last_action_priority = -1

#endregion

#region Properties

## Returns true if the animator has a currently-playing action
var is_locked: bool:
    get():
        return !p_lock.is_stopped()

#endregion
