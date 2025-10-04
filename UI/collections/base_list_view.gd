@warning_ignore_start("unused_parameter")

## A base-class for list-like UIs
@abstract
class_name BaseListView
extends Control

signal list_selection_changed(index: int)

@export_group("List")
@export
var p_pkg_cell: PackedScene

var p_viewport: Control
var m_last_cell_count: int

## The currently-selected index (It returns -1 if nothing is selected.)
var m_selected_index: int = -1

#region Data Provider

## The return value of this function determines the number of cells to be created
## When the [regenerate] function is called.
@abstract
func _list_get_count() -> int;


## The return value of this function determines the data to be used when updating
## the cell at the specified index
@abstract
func _list_get_data(i: int) -> Variant;

#endregion

#region Events

func _enter_tree() -> void:
    assert(
        is_instance_valid(p_pkg_cell),
        "BaseListView: invalid configuration -- no cell template assigned"
    )

    assert(
        has_node(^"%Viewport"),
        "BaseListView: a list view must have a scene-unique node called \"Viewport\""
    )

    p_viewport = get_node(^"%Viewport")
    m_last_cell_count = 0


func _on_cell_activated(index: int) -> void:
    if m_selected_index == index:
        return

    m_selected_index = index
    list_selection_changed.emit(index)

#endregion

#region List

## A processing method that is called whenever the list is updated
## [[is_update]] is true when cells have been regenerated
func _list_cell_updated(is_update: bool, index: int, data, cell) -> void:
    pass


## Destroys all active cells in the list
func clear() -> void:
    for child: Node in p_viewport.get_children():
        if child is not BaseListCell || !child.visible:
            continue

        if list_selection_changed.is_connected(child._on_list_selection_changed):
            list_selection_changed.disconnect(child._on_list_selection_changed)

        child.queue_free()


## Destroys all active cells and creates new ones using the template.
## (Try to limit the use of this function at runtime. Use [update] to refresh
## the contents of existing cells.)
func regenerate() -> void:
    clear()

    var count := _list_get_count()

    m_selected_index = -1
    m_last_cell_count = count

    for i: int in range(count):
        # Init
        var cell: BaseListCell = p_pkg_cell.instantiate()
        p_viewport.add_child(cell)

        var data: Variant = _list_get_data(i)

        cell._cell_init()
        cell._cell_configure(data)

        _list_cell_updated(false, i, data, cell)

        # Bind
        list_selection_changed.connect(cell._on_list_selection_changed)
        cell.cell_activated.connect(_on_cell_activated)


## Refreshes the contents of this list view.
## (Prefer this over [regenerate] if the cell count has not changed.)
func update() -> void:
    for i: int in range(m_last_cell_count):
        var data: Variant = _list_get_data(i)
        var cell: BaseListCell = p_viewport.get_child(i)

        _list_cell_updated(true, i, data, cell)


## Automatically picks [[regenerate]] or [[update]] depending on
## whether or not the cell count has changed
func refresh() -> void:
    if _list_get_count() == m_last_cell_count:
        update()
        return

    regenerate()

#endregion
