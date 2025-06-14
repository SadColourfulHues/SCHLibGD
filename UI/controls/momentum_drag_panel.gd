### Slightly fancier Draggable panel that adds a 'slippery' feel when dragging
class_name MomentumDragPanel
extends DraggablePanel

@export_group("Momentum Panel")
@export
var m_momentum_scale: float = 30.0

@export_range(0.01, 1.0)
var m_ease_decay_fac := 0.1

@export
var m_drag_deadzone_size: float = 8.0

var m_last_position: Vector2
var m_motion: Vector2
var m_ease := 0.0


#region Events

func _enter_tree() -> void:
    super._enter_tree()
    set_process(false)


func _process(delta: float) -> void:
    if m_motion.is_zero_approx():
        set_process(false)
        return

    # Actual motion behaviour #
    m_motion = m_motion.move_toward(Vector2.ZERO, 10.0 * Easing.sine(m_ease, false))
    m_ease = min(1.0, m_ease + (m_ease_decay_fac * delta))

    __set_control_position(global_position + (m_motion * m_momentum_scale * delta))

#endregion

#region Panel Events

func _on_drag_started(event: InputEventMouseButton) -> void:
    super._on_drag_started(event)
    set_process(false)

    m_last_position = global_position


func _on_drag_tick(event: InputEventMouseMotion) -> void:
    if !m_is_dragging:
        return

    var cursor_pos := event.global_position

    drag_tick.emit(cursor_pos)
    __set_control_position(cursor_pos + m_drag_offset)

    # Mouse motion update #
    m_motion = global_position - m_last_position
    m_last_position = global_position


func _on_drag_ended(event: InputEventMouseButton) -> void:
    super._on_drag_ended(event)

    # drag deadzone test ~ to prevent the panel from sliding on every click ~
    if m_motion.length_squared() <= (m_drag_deadzone_size * m_drag_deadzone_size):
        return

    m_ease = 0.0
    set_process(true)

#endregion
