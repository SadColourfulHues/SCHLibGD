@warning_ignore_start("unused_parameter")

## Base class for BaseListView cells
class_name BaseListCell
extends Control

signal cell_activated(index: int)

@export_group("Cell")
## The activator is a button that catches mouse events and forwards it to the cell
@export
var p_activator: Button

## An optional [Control] view that shows the highlight state of the cell
@export
var p_highlight: Control


#region Events

func _on_activator_triggered() -> void:
    cell_activated.emit(get_index())


func _on_list_selection_changed(index: int) -> void:
    __set_highlight_visible(index == get_index())

#endregion


#region Cell

## Override this to add configurations to custom list view cells
## Just make sure to call [super::_cell_init] to finalise the cell configuration!
func _cell_init() -> void:
    __set_highlight_visible(false)

    # Bind activator #
    if !is_instance_valid(p_activator):
        return

    p_activator.pressed.connect(_on_activator_triggered)

## Called by the owning list view whenever the view needs to update its data.
## (Note: [data] is untyped to allow subclasses to be able to add type hints
## for the data they're supposed to be used with.)
## (e.g. `_cell_configure(data: ItemEntry)`)
func _cell_configure(data) -> void:
    pass

#endregion

#region Utils

func __set_highlight_visible(visible_: bool) -> void:
    if !is_instance_valid(p_highlight):
        return

    p_highlight.visible = visible_

#endregion