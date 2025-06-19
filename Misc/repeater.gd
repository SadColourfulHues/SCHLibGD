## A special utility node for repeatedly performing a specified action
class_name Repeater
extends Node

@export
var m_destroy_on_finish := false

var p_timer: Timer
var p_elapse_callback: Callable
var p_finish_callback: Callable

var m_elapse_index := 0
var m_times_left := 0


#region Functions

## Starts the repeater
## Use the callback parameters to configure repeater actions
func start(duration: float,
           count: int = 3,
           elapse_callback := Callable(),
           finished_callback := Callable()) -> void:

    p_timer.start(duration)
    m_times_left = count

    p_elapse_callback = elapse_callback
    p_finish_callback = finished_callback
    m_elapse_index = 0


## Stops the repeater
func stop() -> void:
    var empty := Callable()
    p_elapse_callback = empty
    p_finish_callback = empty
    p_timer.stop()


## When enabled, the repeater will run its timer in the physics tick
func set_process_in_physics(physics: bool) -> void:
    p_timer.process_callback = (
        Timer.TIMER_PROCESS_PHYSICS
        if physics else
        Timer.TIMER_PROCESS_IDLE
    )

#endregion

#region Events

func _ready() -> void:
    p_timer = Timer.new()
    p_timer.timeout.connect(_on_timer_elapsed)
    add_child(p_timer)


func _on_timer_elapsed() -> void:
    m_times_left -= 1

    if p_elapse_callback.is_valid():
        p_elapse_callback.call(m_elapse_index)

    m_elapse_index += 1

    if m_times_left > 0:
        return

    if !m_destroy_on_finish:
        if p_finish_callback.is_valid():
            p_finish_callback.call()

        p_timer.stop()
        return

    if p_finish_callback.is_valid():
        p_finish_callback.call()

    queue_free()

#endregion
