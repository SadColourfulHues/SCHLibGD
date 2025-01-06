## Defines a component for blending two animation parts together
@tool
class_name AnimatorPartBlend3
extends AnimatorPart

@export_group("Blend")
@export
var m_from: AnimatorInput

@export
var m_blend_neg: AnimatorInput

@export
var m_blend_pos: AnimatorInput

@export
var m_default_value: float


#region Part

func _init(id: StringName = &"",
		from: AnimatorInput = null,
		to_neg: AnimatorInput = null,
		to_pos: AnimatorInput = null) -> void:

	m_id = id
	m_from = from
	m_blend_neg = to_neg
	m_blend_pos = to_pos

	m_default_value = 0.0


func generate(_animator: AnimationTree) -> AnimationNode:
	return AnimationNodeBlend3.new()


func connect_inputs(previous_id: StringName, root: AnimationNodeBlendTree) -> void:
	__connect(root, m_blend_neg, 0)
	__connect_as_input(previous_id, root, m_from, 1)
	__connect(root, m_blend_pos, 2)


func apply_default_value(animator: AnimationTree) -> void:
	animator.set(&"parameters/%s/blend_amount" % m_id, m_default_value)

#endregion

#region Resource Name

func _validate_property(property: Dictionary) -> void:
	if !Engine.is_editor_hint() || property[&"name"] != &"m_id":
		return

	resource_name = "BLEND3 \"%s\"" % m_id
	emit_changed()

#endregion