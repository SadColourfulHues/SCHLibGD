## A container view for UI for displaying
## controls-related information depending on the user's current device
## count
@tool
class_name HybridInputDisplay2D
extends MarginContainer

@export
var m_mouse_and_key_default := true

var p_controller_view: MarginContainer
var p_mouse_and_keys_view: MarginContainer


#region Events

func _enter_tree() -> void:
    if Engine.is_editor_hint():
        __create_if_unavailable("controller")
        __create_if_unavailable("mouseAndKeys")
        return

    # Grab #
    p_controller_view = get_node(^"controller")
    p_mouse_and_keys_view = get_node(^"mouseAndKeys")

    # Init #
    p_mouse_and_keys_view.visible = m_mouse_and_key_default
    p_controller_view.visible = !m_mouse_and_key_default

    # Bind #
    Input.joy_connection_changed.connect(_on_joy_count_changed)


func _exit_tree() -> void:
    if Engine.is_editor_hint():
        return

    Input.joy_connection_changed.disconnect(_on_joy_count_changed)


func _on_joy_count_changed(_device_idx: int, _is_connected: bool) -> void:
    var is_active := Input.get_connected_joypads().size() > 0

    p_controller_view.visible = is_active
    p_mouse_and_keys_view.visible = !is_active

#endregion

#region Utils

func __create_if_unavailable(node_name: String) -> void:
    if has_node(node_name):
        return

    var node := MarginContainer.new()
    node.name = node_name

    add_child(node)
    node.owner = get_tree().edited_scene_root

#endregion
