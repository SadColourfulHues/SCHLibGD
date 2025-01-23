@warning_ignore_start("integer_division")

## A resource containing information for crafting recipes
@tool
class_name RecipeDefinition
extends Resource

@export
var m_output_id: StringName

@export
var m_output_count := 1

@export
var p_ingredients: Dictionary[StringName, int]


#region Utils

## Returns true if the given item bag has all the ingredients needed to craft this recipe
func can_craft(bag: ItemBag, multiplier: int = 1) -> bool:
    var item_def := bag.get_definition(m_output_id)

    if (item_def == null ||
        bag.get_count(m_output_id) >= (item_def.m_max_count / multiplier)):
        return false

    for item_id: StringName in p_ingredients:
        var count := p_ingredients[item_id]

        if bag.get_count(item_id) >= (multiplier * count):
            continue

        return false

    return true


## Performs the crafting action in the specified item bag
func craft(bag: ItemBag, multiplier: int = 1) -> bool:
    if !can_craft(bag, multiplier):
        return false

    var existing_count := bag.get_count(m_output_id)
    var item_def := bag.get_definition(m_output_id)

    var true_count: int = min(multiplier * m_output_count,
                            max(0, (item_def.m_max_count - existing_count) / multiplier))

    if true_count < 1:
        return false

    for item_id: StringName in p_ingredients:
        bag.add_item(item_id, -true_count * p_ingredients[item_id])

    bag.add_item(m_output_id, multiplier * m_output_count)
    return true


## Returns true if this recipe contains the given item ID
func has_ingredient(item_id: StringName) -> bool:
    return p_ingredients.keys().has(item_id)

#endregion

#region Resource Name

func _validate_property(property: Dictionary) -> void:
    Utils.rsyncprop2name(self, &"m_output_id", property)

#endregion