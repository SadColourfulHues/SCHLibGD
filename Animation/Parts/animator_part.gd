@warning_ignore_start("unused_parameter")

## Base class for parts used to create an animation tree
class_name AnimatorPart
extends Resource

@export_group("Essential")
@export
var m_id: StringName

#region Part

## Use this function to generate the animation node associated with this part
func generate(animator: Animator) -> AnimationNode:
	return AnimationNode.new()

## Use this function to generate the node's inputs and connect them to their respective ports
func connect_inputs(previous_id: StringName, root: AnimationNodeBlendTree) -> void:
	pass

## Use this function to set the associated node's default value
func apply_default_value(animator: Animator) -> void:
	pass

#endregion

#region Utils

## Use on [connect_inputs]
## Finalises connection in the animation tree
func __connect(root: AnimationNodeBlendTree,
			input: AnimatorInput,
			port: int) -> void:

	var input_node := input.generate(root)

	# TODO: find a better way of doing this thing
	# WHY on earth is this mechanism not documented anywhere??
	# This is probably the least tree-like structure in Godot so far, which is ironic considering its name

	if input is AnimatorInputAnimation:
		# e.g. this_node_0 <- port 0 of 'this_node'
		var input_name := "%s_in%d" % [m_id, port]
		root.add_node(input_name, input_node)
		root.connect_node(m_id, port, input_name)

	elif input is AnimatorInputNode:
		root.connect_node(m_id, port, input.m_target_id)


## Use on [connect_inputs]
## A variant of [_connect] that also handles connection fallback (to the previous [AnimatorPart])
## if [input] is is not provided (typically used on input ports)
func __connect_as_input(previous_id: StringName,
					root: AnimationNodeBlendTree,
					input: AnimatorInput,
					port: int) -> void:

	if previous_id.is_empty():
		return

	if is_instance_valid(input):
		__connect(root, input, port)
		return

	root.connect_node(m_id, port, previous_id)


#endregion
