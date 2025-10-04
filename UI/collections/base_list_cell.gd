@warning_ignore_start("unused_parameter")

## Base class for BaseListView cells
## Adding a node called "Highlight" can be added to the root to
## add an optional active indicator to the cell.
@abstract
class_name BaseListCell
extends Button

signal cell_activated(index: int)

var p_highlight: Control


#region Events

func _ready() -> void:
    p_highlight = get_node_or_null(^"Highlight")


func _on_activator_triggered() -> void:
    cell_activated.emit(get_index())


func _on_list_selection_changed(index: int) -> void:
    __set_highlight_visible(index == get_index())

#endregion


#region Cell

## Called by the owning list view whenever the view needs to update its data.
## (Note: [data] is untyped to allow subclasses to be able to add type hints
## for the data they're supposed to be used with.)
## (e.g. `_cell_configure(data: ItemEntry)`)
@abstract
func _cell_configure(data) -> void;

## Override this to add configurations to custom list view cells
## Just make sure to call [super::_cell_init] to finalise the cell configuration!
func _cell_init() -> void:
    __set_highlight_visible(false)
    pressed.connect(_on_activator_triggered)

#endregion

#region Utils

func __set_highlight_visible(visible_: bool) -> void:
    if !is_instance_valid(p_highlight):
        return

    p_highlight.visible = visible_

#endregion
