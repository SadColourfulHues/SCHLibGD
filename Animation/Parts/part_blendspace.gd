## Defines a component for blending multiple animations along a 1D/2D space
@tool
class_name AnimatorPartBlendSpace
extends AnimatorPart

@export_group("Blendspace")
@export
var p_points: Dictionary[StringName, Vector2]

@export
var m_default_value: float

@export
var m_default_value_2d: Vector2


#region Part

func _init(id: StringName = &"", points: Dictionary[StringName, Vector2] = {}) -> void:
	m_id = id

	m_default_value = 0.0
	m_default_value_2d = Vector2.ZERO

	if points.is_empty():
		return

	p_points = points


func generate(_animator: AnimationTree) -> AnimationNode:
	# Populate 1D Blend Space #
	if is_1d:
		var bspace1d := AnimationNodeBlendSpace1D.new()
		var min_value_1d := 100_000_000.0
		var max_value_1d := -100_000_000.0

		for anim_id: StringName in p_points:
			var point := p_points[anim_id].x
			bspace1d.add_blend_point(__anim_node_for_id(anim_id), point)

			if point > max_value_1d:
				max_value_1d = point

			if point < min_value_1d:
				min_value_1d = point

		bspace1d.min_space = min_value_1d
		bspace1d.max_space = max_value_1d

		return bspace1d

	# Populate 2D Blend Space #

	var bspace2d := AnimationNodeBlendSpace2D.new()
	var min_value_2d := Vector2.ONE * 100_000_000
	var max_value_2d := -min_value_2d

	for anim_id: StringName in p_points:
		var point := p_points[anim_id]

		bspace2d.add_blend_point(__anim_node_for_id(anim_id), point)

		if point > max_value_2d:
			max_value_2d = point

		if point < min_value_2d:
			min_value_2d = point

	bspace2d.min_space = min_value_2d
	bspace2d.max_space = max_value_2d
	return bspace2d


func apply_default_value(animator: Animator) -> void:
	if is_1d:
		animator.set_blendspace(m_id, m_default_value)
		return

	animator.set_blendspace_2d(m_id, m_default_value_2d)

#endregion

#region Properties

func default_value(value: float) -> AnimatorPartBlendSpace:
	m_default_value = value
	return self


func default_value_2d(value: Vector2) -> AnimatorPartBlendSpace:
	m_default_value_2d = value
	return self

#endregion

#region Utils

func __anim_node_for_id(id: StringName) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = id

	return node


## Returns 'true' if the blend space is one dimensional
var is_1d: bool :
	get():
		# 2d blendspaces needs at least three points to create a "triangle"
		if p_points.size() < 3:
			return true

		for position: Vector2 in p_points.values():
			if !is_zero_approx(position.y):
				return false

		return true

#endregion

#region Resource Name

func _validate_property(property: Dictionary) -> void:
	if (!Engine.is_editor_hint() || property[&"name"] != &"m_id"):
		return

	resource_name = ("BS1D \"%s\"" if is_1d else "BS2D \"%s\"") % m_id
	emit_changed()

#endregion