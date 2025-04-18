## Defines a component for blending two animation parts together
@tool
class_name AnimatorPartBlend2
extends AnimatorPart

@export_group("Blend")
@export
var m_from: AnimatorInput

@export
var m_to: AnimatorInput

@export
var m_default_value: float


#region Part

func _init(id: StringName = &"", from_: AnimatorInput = null, to: AnimatorInput = null) -> void:
	m_id = id
	m_from = from_
	m_to = to

	m_default_value = 0.0


func generate(_animator: AnimationTree) -> AnimationNode:
	return AnimationNodeBlend2.new()


func connect_inputs(previous_id: StringName, root: AnimationNodeBlendTree) -> void:
	__connect_as_input(previous_id, root, m_from, 0)
	__connect(root, m_to, 1)


func apply_default_value(animator: Animator) -> void:
	animator.set_blend(m_id, m_default_value)

#endregion

#region Properties

func default_value(value: float) -> AnimatorPartBlend2:
	m_default_value = value
	return self

#endregion

#region Utils

## Creates a blend2 using the specified animation IDs
static func from(id: StringName,
				a_id: StringName,
				b_id: StringName,
				def_value: float = 0.0) -> AnimatorPartBlend2:

	return (
		AnimatorPartBlend2.new(
			id,
			AnimatorInputAnimation.new(a_id),
			AnimatorInputAnimation.new(b_id)
		)
		.default_value(def_value)
	)

#endregion

#region Resource Name

func _validate_property(property: Dictionary) -> void:
	if !Engine.is_editor_hint() || property[&"name"] != &"m_id":
		return

	resource_name = "BLEND2 \"%s\"" % m_id
	emit_changed()

#endregion