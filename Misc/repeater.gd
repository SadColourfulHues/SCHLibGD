## A special utility node for repeatedly performing a specified action
class_name Repeater
extends Node

## Attach actions that needs to be performed repeatedly here
signal elapsed(i: int)
## Called once all repetitions have been completed
signal finished()

@export
var m_destroy_on_finish := false

var p_timer: Timer
var p_tmp_callback: Callable

var m_elapse_index := 0
var m_times_left := 0


#region Functions

## Starts the repeater
## (A temporary callback can provided if signals are a bit inconvenient)
func start(duration: float,
           count: int = 3,
           callback := Callable()) -> void:

    p_timer.start(duration)
    m_times_left = count
    p_tmp_callback = callback
    m_elapse_index = 0


## Stops the repeater
func stop() -> void:
    p_timer.stop()

#endregion

#region Events

func _ready() -> void:
    p_timer = Timer.new()
    p_timer.timeout.connect(_on_timer_elapsed)
    add_child(p_timer)


func _on_timer_elapsed() -> void:
    m_times_left -= 1
    elapsed.emit(m_elapse_index)

    if p_tmp_callback.is_valid():
        p_tmp_callback.call(m_elapse_index)

    m_elapse_index += 1

    if m_times_left > 0:
        return

    if !m_destroy_on_finish:
        p_tmp_callback = Callable()
        finished.emit()
        p_timer.stop()
        return

    finished.emit()
    queue_free()

#endregion
