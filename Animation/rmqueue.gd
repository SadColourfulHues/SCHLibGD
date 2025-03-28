## @experimental
## A helper object that synchronises root motion disparity
## when the physics tick is ran at a lower tick (e.g. physics interpolation.)
## Call the [[update]] method on [[_process]], then [[apply]] on [[_physics_process]]
class_name RootMotionQueue
extends RefCounted

var p_body: Node3D
var p_animator: AnimationTree
var p_queue: Array[Data]
var m_max_queued_item_count: int = 8

var m_last_rotation: Quaternion

## Modify to change the intensity of positional root motion
var m_scale: float

## Set to true to prevent root motion changes in the Y axis
var m_lock_xz: bool = true


#region Events

func _init(body: Node3D, animator: AnimationTree, max_items: int = 8) -> void:
    m_scale = 1.0
    p_body = body
    p_animator = animator
    m_max_queued_item_count = max_items

    m_last_rotation = body.quaternion

    p_queue.resize(m_max_queued_item_count)
    p_queue.fill(null)


func _notification(what: int) -> void:
    if what != NOTIFICATION_PREDELETE:
        return

    # Cleanup #
    for i: int in range(m_max_queued_item_count):
        if p_queue[i] == null:
            continue

        p_queue[i].free()

#endregion

#region Functions

## Will keep enqueue-ing root motion data until the next [[apply]]
func update(delta: float) -> void:
    __enqueue(
        p_animator.get_root_motion_position() / delta,
        p_animator.get_root_motion_rotation()
    )


## Applies all enqueued root motion actions
func apply() -> void:
    for i: int in range(m_max_queued_item_count):
        if p_queue[i] == null:
            continue

        var item := p_queue[i]

        var motion := (
            (p_animator.get_root_motion_rotation_accumulator().inverse() * p_body.quaternion) *
            (m_scale * item.m_motion)
        )

        p_body.quaternion *= item.m_rotation

        if m_lock_xz:
            motion.y = 0.0

        p_body.velocity = motion
        p_body.move_and_slide()

        p_queue[i].free()
        p_queue[i] = null

    m_last_rotation = p_body.quaternion


## Clears queued root motion data
func clear() -> void:
    for i: int in range(m_max_queued_item_count):
        if p_queue[i] == null:
            continue

        p_queue[i].free()
        p_queue[i] = null

#endregion

#region Utils

func __enqueue(motion: Vector3, rotation: Quaternion) -> bool:
    var open_idx := p_queue.find(null)

    if open_idx == -1:
        return false

    p_queue[open_idx] = Data.new(motion, rotation)
    return true

#endregion

#region Data

class Data extends Object:
    var m_motion: Vector3
    var m_rotation: Quaternion

    func _init(motion: Vector3, rotation: Quaternion) -> void:
        m_motion = motion
        m_rotation = rotation

#endregion
