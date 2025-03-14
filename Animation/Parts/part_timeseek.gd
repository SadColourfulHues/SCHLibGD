## Defines a component for adding a seek control
class_name AnimatorPartTimeSeek
extends AnimatorPart

@export_group("TimeSeek")
@export
var m_original: AnimatorInput


#region Part

func _init(id: StringName = &"",
		original: AnimatorInput = null) -> void:

	m_id = id
	m_original = original


func generate(_animator: AnimationTree) -> AnimationNode:
	return AnimationNodeTimeSeek.new()


func connect_inputs(previous_id: StringName, root: AnimationNodeBlendTree) -> void:
	__connect_as_input(previous_id, root, m_original, 0)


func apply_default_value(animator: Animator) -> void:
	animator.seek(m_id, 0.0)

#endregion

#region Resource Name

func _validate_property(property: Dictionary) -> void:
	if !Engine.is_editor_hint() || property[&"name"] != &"m_id":
		return

	resource_name = "SEEK \"%s\"" % m_id
	emit_changed()

#endregion
