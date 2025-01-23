@warning_ignore_start("unused_parameter")

## Base class for input nodes to be used on [AnimatorPart]s
class_name AnimatorInput
extends Resource

#region Input

## Use this function to generate the animation node associated with this part
func generate(root: AnimationNodeBlendTree) -> AnimationNode:
    return AnimationNode.new()

#endregion