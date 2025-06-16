## A helper utility for 2D sprites
## When flipped, it will invert the x axis of its children.
## When attached to a [[Sprite2D]] or an [[AnimatedSprite2D]], it
## will automatically update its flipped state depending on its parent's value.
@tool
class_name FlipSymmetry
extends Marker2D

@export
var m_observe_flip_state: bool = true

var m_flipped: bool = false
var p_children: Array[Node2D]

var p_parent: Node
var m_tick: float = 0.0


#region Events

func _ready() -> void:
    for child: Node in get_children():
        if child is not Node2D:
            continue

        p_children.append(child)

    var parent: Node = get_parent()

    if (parent == null ||
        !(parent is Sprite2D || parent is AnimatedSprite2D)):

        set_process(false)
        return

    p_parent = parent
    set_process(m_observe_flip_state)


func _process(delta: float) -> void:
    m_tick += delta

    if m_tick < 0.45:
        return

    var flipped_state: bool = p_parent.flip_h

    if m_flipped == flipped_state:
        return

    flipped = flipped_state

#endregion

#region Properties

## When set to true, it inverts the x axis of its children
@export
var flipped: bool :
    set(value):
        m_flipped = value
        var flipped_fac := -1.0 if m_flipped else 1.0

        for child: Node2D in p_children:
            child.position.x = abs(child.position.x) * flipped_fac

    get():
        return m_flipped

#endregion
