@warning_ignore_start("unused_parameter")

## A variant of [[BaseListView]] that supports drag-and-drop interactions
@abstract
class_name BaseDragDropListView
extends BaseListView


#region Events

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    if data is not BaseDragDropCell.DragData:
        return false

    return _list_is_data_droppable(data.m_type, data.p_data)


func _drop_data(at_position: Vector2, data: Variant) -> void:
    var true_data: BaseDragDropCell.DragData = data

    _list_will_drop_data(
        true_data.p_data,
        true_data.m_type,
        true_data.m_index
    )

    true_data.p_callback.call(_list_get_drop_context())

#endregion

#region Drag and Drop

## Called when compatible data is being dropped to the list view
@abstract
func _list_will_drop_data(data, id: StringName, origin_idx: int);

## Called when a cell has been dropped successfully
@abstract
func _list_data_dropped(index: int, context: Variant);

## Called to check if a drag data is compatible with this list view
@abstract
func _list_is_data_droppable(id: StringName, data) -> bool;

## Override this method to provide a context object on a successful drag operation
func _list_get_drop_context() -> Variant:
    return null

#endregion

#region List

func _list_cell_updated(is_update: bool, index: int, data, cell) -> void:
    assert(
        cell is BaseDragDropCell,
        "BaseDragDropList: associated cell type is incompatible with this list view."
    )

    cell.p_data = data

    if cell.dropped.is_connected(_list_data_dropped):
        return

    cell.dropped.connect(_list_data_dropped)

#endregion
