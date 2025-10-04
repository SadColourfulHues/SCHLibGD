## A variant of [[BaseListCell]] with support for drag-and-drop interactions
@abstract
class_name BaseDragDropCell
extends BaseListCell

signal dropped(index: int, context: Variant)

var p_data


#region Events

func _get_drag_data(at_position: Vector2) -> Variant:
    set_drag_preview(_list_create_drag_preview(at_position))
    return _list_get_data()


func _on_data_dragdrop_success(context: Variant) -> void:
    dropped.emit(get_index(), context)


#endregion

#region Drag and Drop

## Returns a string that can be used to test data compatibility
@abstract
func _list_get_drag_data_identifier() -> StringName;


## Override this method to provide an alternate drag preview
func _list_create_drag_preview(offset: Vector2) -> Node:
    var preview: Control = self.duplicate()
    preview.custom_minimum_size = Vector2.ZERO
    preview.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
    preview.pivot_offset = 0.5 * preview.size

    if !offset.is_zero_approx():
        var offset_delta := offset - preview.get_global_rect().position

        for child: Node in preview.get_children():
            if child is not Control:
                continue

            child.position -= offset_delta

    return preview


func _list_get_data() -> DragData:
    var data := DragData.new()
    data.m_type = _list_get_drag_data_identifier()
    data.m_index = get_index()
    data.p_data = p_data
    data.p_callback = _on_data_dragdrop_success

    return data

#endregion

#region Data

class DragData extends RefCounted:
    var m_type: StringName
    var m_index: int

    var p_callback: Callable
    var p_data: Variant

#endregion
