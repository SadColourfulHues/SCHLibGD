@warning_ignore_start("unused_private_class_variable")

## A sprite that randomises its appearance based on its horizontal strip
@tool
class_name StripRandomiser2D
extends Sprite2D

@export_tool_button("Randomise", "randomise")
var __btn_randomise = randomise


#region Events

func _enter_tree() -> void:
    frame = randi() % hframes

#endregion

#region Functions

## Randomises its appearance based on its horizontal strip
func randomise() -> void:
    frame = randi() % hframes

#endregion
