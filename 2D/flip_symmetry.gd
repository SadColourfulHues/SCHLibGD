@warning_ignore_start("unused_private_class_variable")

## A helper utility for 2D sprites
## When flipped, it will invert the x axis of its children.
## (Attach to a [[SpriteAnimator2D]] if possible for the most
## efficient flip observer performance.)

## When attached to a [[Sprite2D]] or an [[AnimatedSprite2D]], it
## will automatically update its flipped state depending on its parent's value.
@tool
class_name FlipSymmetry
extends Marker2D

## (Editor Only: forces a rebuild of the affected list)
@export_tool_button("Rebuild Affected List", "rebuild")
var __editor_rebuild_btn = SCHUtils.test.bind(rebuild)

@export_subgroup("Configuration")
## The max depth of the affected build list
## (Try to keep this as low as humanly possible to ensure optimal performance.)
@export
var m_max_build_recursion_depth := 3

@export
var m_reset_interpolation := true

var m_flipped: bool = false
var p_affected: Array[Node2D]

var p_parent: Node
var m_tick: float = 0.0


#region Events

func _ready() -> void:
    rebuild()

    var parent: Node = get_parent()

    if !is_instance_valid(parent):
        set_process(false)
        return

    p_parent = parent

    # when we're using our own SpriteAnimator2D, we can
    # spare the pointless observer cost and just perform
    # the flip when it's actually needed.

    # But since SpriteAnimator2D is not a @tool script
    # use the 'subpar' variant of the observer in the Editor
    if !Engine.is_editor_hint() && p_parent is SpriteAnimator2D:
        p_parent.flipped.connect(_on_flip_handler)
        set_process(false)
        return

    if parent is not Sprite2D && parent is not AnimatedSprite2D:
        return

    # Please try not to use this at runtime :)
    set_process(true)


func _process(delta: float) -> void:
    m_tick += delta

    if m_tick < 0.25:
        return

    flipped = p_parent.flip_h
    m_tick = 0.0


func _on_flip_handler() -> void:
    flipped = p_parent.flip_h

#endregion

#region Functions

## Forces a rebuild of the affected list
func rebuild() -> void:
    p_affected.clear()

    for child: Node in get_children():
        __push_to_affected_list(child, m_max_build_recursion_depth)


## Applies flip symmetry
## (Called automatically when the property [[flipped]] is modified
func apply() -> void:
    var flipped_fac := -1.0 if m_flipped else 1.0
    var is_flipped := flipped_fac == -1.0

    for node: Node2D in p_affected:
        var ogsign: float = node.get_meta(&"ogsign", 1.0)

        node.position.x = (
            abs(node.position.x)
            * ogsign
            * flipped_fac
        )

        match node.get_meta(&"type", 0):
            1:
                node.flip = is_flipped

            2:
                node.flip_h = is_flipped

        if !m_reset_interpolation:
            continue

        node.reset_physics_interpolation()

#endregion

#region Properties

## When set to true, it inverts the x axis of its children
@export
var flipped: bool :
    set(value):
        if m_flipped == value:
            return

        m_flipped = value
        apply()

    get():
        return m_flipped

#endregion

#region Utils

func __push_to_affected_list(base: Node, level: int) -> void:
    if (level <= 0 ||
        !is_instance_valid(base) ||
        base is not Node2D):
        return

    base.set_meta(&"ogsign", sign(base.position.x) as float)
    p_affected.append(base)

    if base is SpriteAnimator2D:
        base.set_meta(&"type", 1)
    elif base is Sprite2D || base is AnimatedSprite2D:
        base.set_meta(&"type", 2)
    else:
        base.set_meta(&"type", 0)

    for child: Node in base.get_children():
        __push_to_affected_list(child, level - 1)

#endregion
