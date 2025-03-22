## An input node that resolves to a specific animation in an animation player
@tool
class_name AnimatorInputAnimation
extends AnimatorInput

@export
var m_animation_id: StringName


#region Input

func _init(id: StringName = "") -> void:
	m_animation_id = id


func generate(_root: AnimationNodeBlendTree) -> AnimationNode:
	var node := AnimationNodeAnimation.new()
	node.animation = m_animation_id

	return node

#endregion

#region Resource Name

func _validate_property(property: Dictionary) -> void:
	if !Engine.is_editor_hint() || property[&"name"] != &"m_animation_id":
		return

	resource_name = "%s" % m_animation_id
	emit_changed()

#endregion
