## A variant of Repeater that uses an access index to randomise its processing order
class_name RandomRepeater
extends Repeater

var p_access_index: Array[int]


#region Repeater

## Starts the repeater
## Use the callback parameters to configure repeater actions
func start(duration: float,
           count: int = 3,
           elapse_callback := Callable(),
           finished_callback := Callable()) -> void:

    # Temporary workaround until GDscript's weird typing behaviour is fixed
    # TODO: replace with "p_access_index = range(count)" once that's a thing that can be done
    if p_access_index.size() != count:
        p_access_index.resize(count)

        for i: int in range(count):
            p_access_index[i] = i

    p_access_index.shuffle()
    super.start(duration, count, elapse_callback, finished_callback)


func _on_timer_elapsed() -> void:
    m_times_left -= 1

    if p_elapse_callback.is_valid():
        p_elapse_callback.call(p_access_index[m_elapse_index])

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
