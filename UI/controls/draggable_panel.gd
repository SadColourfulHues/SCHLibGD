### A basic draggable panel
class_name DraggablePanel
extends Panel

## Called when the panel is clicked
signal drag_began(cursor_position: Vector2)
## Called when the panel is dragged
signal drag_tick(cursor_position: Vector2)
## Called when the panel is released
signal drag_ended(cursor_position: Vector2)

@export_subgroup("Draggable Panel")
@export
var m_drag_button: MouseButton = MOUSE_BUTTON_LEFT

@export
var m_edge_padding: float = 16.0

var m_cursor_inside_me: bool
var m_drag_offset: Vector2
var m_is_dragging: bool

var m_window_size: Vector2
var m_self_size: Vector2


#region Events

func _enter_tree() -> void:
    mouse_entered.connect(func(): m_cursor_inside_me = true)
    mouse_exited.connect(func(): m_cursor_inside_me = false)

    resized.connect(_on_resized)
    get_viewport().size_changed.connect(_on_window_size_changed)

    # Initialise values #
    _on_resized.call_deferred()
    _on_window_size_changed.call_deferred()
    snap_to_bounds.call_deferred()


func _exit_tree() -> void:
    get_viewport().size_changed.disconnect(_on_window_size_changed)


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index != m_drag_button:
            return

        if event.pressed:
            _on_drag_started(event)
            get_viewport().set_input_as_handled()
        else:
            _on_drag_ended(event)
            get_viewport().set_input_as_handled()

    elif event is InputEventMouseMotion:
        _on_drag_tick(event)
        get_viewport().set_input_as_handled()


func _on_resized() -> void:
    m_self_size = get_global_rect().size


func _on_window_size_changed() -> void:
    m_window_size = DisplayServer.window_get_size()
    snap_to_bounds()

#endregion

#region Functions

func snap_to_bounds() -> void:
    __set_control_position(global_position)

#endregion

#region Panel Events

func _on_drag_started(event: InputEventMouseButton) -> void:
    if !m_cursor_inside_me:
        return

    var cursor_pos := event.global_position

    m_is_dragging = true
    m_drag_offset = global_position - cursor_pos

    drag_began.emit()


func _on_drag_tick(event: InputEventMouseMotion) -> void:
    if !m_is_dragging:
        return

    var cursor_pos := event.global_position

    drag_tick.emit(cursor_pos)
    __set_control_position(cursor_pos + m_drag_offset)


func _on_drag_ended(_event: InputEventMouseButton) -> void:
    if !m_is_dragging:
        return

    m_is_dragging = false
    drag_ended.emit()

#endregion

#region Utils

func __set_control_position(target_position: Vector2) -> void:
    target_position.x = clamp(
        target_position.x,
        m_edge_padding,
        m_window_size.x - m_self_size.x - m_edge_padding
    )

    target_position.y = clamp(
        target_position.y,
        m_edge_padding,
        m_window_size.y - m_self_size.y - m_edge_padding
    )

    global_position = target_position

#endregion
