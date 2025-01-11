## Defines a component that adds a time scale modifier
@tool
class_name AnimatorPartTimeScale
extends AnimatorPart

@export_group("Timing")
@export
var m_input: AnimatorInput

@export
var m_default_value := 1.0


#region Part

func _init(id: StringName = &"", input: AnimatorInput = null) -> void:
	m_id = id
	m_input = input


func generate(_animator: AnimationTree) -> AnimationNode:
	return AnimationNodeTimeScale.new()


func connect_inputs(previous_id: StringName, root: AnimationNodeBlendTree) -> void:
	__connect_as_input(previous_id, root, m_input, 0)


func apply_default_value(animator: AnimationTree) -> void:
	animator.set(&"parameters/%s/scale" % m_id, m_default_value)


#endregion

#region Properties

func default_value(value: float) -> AnimatorPartTimeScale:
	m_default_value = value
	return self

#endregion

#region Resource Name

func _validate_property(property: Dictionary) -> void:
	if !Engine.is_editor_hint() || property[&"name"] != &"m_id":
		return

	resource_name = "TIMING \"%s\"" % m_id
	emit_changed()

#endregion