## A controller resource that handles the storage and management of item entries
class_name ItemBag
extends Resource

#region Signals

## Called whenever an item has been 'updated' [use-case e.g: item collection notifications, count label updates, etc.]
signal item_changed(slot_idx: int, item_id: StringName, delta: int)

## Called whenever a new item entry has been added into the bag. [use-case e.g: initialising new cells for inventory UIs.]
signal item_added(slot_idx: int)

## Called whenever an item entry has been invalidated in the bag. [use-case e.g: destroying the associated UI cell.]
signal item_removed(slot_idx: int)

## Called whenver the bag's state changes
signal items_updated()

#endregion

## A resource defining potential item entries
@export
var p_registry: ItemRegistry

## The maximum number of items that can be held by this item bag
@export
var m_max_capacity := 24

var p_items: Array[ItemEntry]
var m_initialised := false

var p_sort_callback := ItemEntry.sort_callback


#region Events

func _notification(what: int) -> void:
    if what != NOTIFICATION_PREDELETE:
        return

    # Ensure that all items are freed by deinit
    for item: ItemEntry in p_items:
        if item == null:
            continue

        item.free()

    p_items.clear()

#endregion

#region Item Control

## Initialises the item bag for use [Call this at least once before doing anything.]
func initialise() -> void:
    if m_initialised:
        return

    m_initialised = true

    # Zero-out items array
    p_items.resize(m_max_capacity)
    p_items.fill(null)


## Adds/removes item from the bag.
## [If the added item count exceeds its max count, it will be discarded.]
## [Similarly, if it goes below 1, the entire item entry will be invalidated.]
func add_item(id: StringName, count: int) -> bool:
    var item_def := p_registry.get_definition(id)

    # Invalid item
    if item_def == null:
        return false

    # Add/remove item to/from existing entry #
    var item_idx := __find(id)

    if item_idx != -1:
        # Prevent item overflow
        var current_count := p_items[item_idx].m_count

        p_items[item_idx].m_count = min(
            item_def.m_max_count,
            current_count + count
        )

        var new_count := p_items[item_idx].m_count

        # If items underflow, consider it removed
        if new_count < 1:
            p_items[item_idx].free()
            p_items[item_idx] = null

            item_removed.emit(item_idx)
            items_updated.emit()
            emit_changed()
            return true

        # Item add to existing successful!
        item_changed.emit(item_idx, id, new_count - current_count)
        items_updated.emit()
        emit_changed()
        return true

    # Register as new item #
    if count < 1:
        return false

    # Find an open slot
    var open_idx := __get_open_idx()

    if open_idx == -1:
        return false

    # Insert as new entry!
    var new_entry = ItemEntry.new()
    new_entry.m_id = id
    new_entry.m_count = min(item_def.m_max_count, count)

    p_items[open_idx] = new_entry

    item_added.emit(open_idx)
    items_updated.emit()
    emit_changed()
    return true


## Invalidates all item entries in this bag
func clear_items() -> void:
    for i: int in range(m_max_capacity):
        p_items[i].free()
        p_items[i] = null

        item_removed.emit(i)

    items_updated.emit()
    emit_changed()


## Returns the total stored count of a specified item ID
func get_count(id: StringName) -> int:
    var item_idx := __find(id)

    if item_idx == -1:
        return 0

    return p_items[item_idx].m_count


## Returns the item def for a specified item ID (Calls [ItemRegistry::get_definition])
func get_definition(id: StringName) -> ItemDefinition:
    return p_registry.get_definition(id)


## Returns the item entry for a specified item ID [Returns null if the specified item ID does not have an entry in this bag.]
func get_item_with_id(id: StringName) -> ItemEntry:
    var item_idx := __find(id)

    if item_idx == -1:
        return null

    return p_items[item_idx]


## Returns the item entry at the specified slot [Returns null on empty/invalid entries, and indices provided outside the bounds of the bag's array.]
func get_item_at_slot(slot_idx: int) -> ItemEntry:
    if slot_idx < 0 || slot_idx >= m_max_capacity:
        return null

    return p_items[slot_idx]


## Sorts the items based on their ID string
func sort_items() -> void:
    p_items.sort_custom(p_sort_callback)
    items_updated.emit()
    emit_changed()

#endregion

#region Utilities

func __find(id: StringName) -> int:
    for i: int in range(p_items.size()):
        if p_items[i] != null && p_items[i].m_id != id:
            continue
        return i
    return -1


## Returns the first open index in the bag, [Returns -1 if the bag has no more space]
func __get_open_idx() -> int:
    for i: int in range(p_items.size()):
        if p_items[i] != null:
            continue
        return i
    return -1

#endregion
