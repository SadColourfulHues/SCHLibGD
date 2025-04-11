## @experimental
## A helper object that helps synchronise root motion disparity
## when the physics tick is ran at a lower tick (physics interpolation)
## Call the [[update]] method on [[_process]], then [[apply]] on [[_physics_process]]
class_name RootMotionAccumulator
extends RefCounted

var p_body: Node3D
var p_animator: AnimationTree

var m_motion_accumulated: Vector3
var m_rotation_accumulated: Quaternion
var m_last_rotation: Quaternion

## Modify to change the intensity of positional root motion
var m_scale: float

## Set to true to prevent root motion changes in the Y axis
var m_lock_xz: bool = true


#region Events

func _init(body: Node3D, animator: AnimationTree) -> void:
    m_scale = 1.0
    p_body = body
    p_animator = animator

    clear()

#endregion

#region Functions

## Will keep accumulating root motion data until the next [[apply]]
func update() -> void:
    var rotation := p_animator.get_root_motion_rotation()

    m_motion_accumulated += m_scale * __oprm(p_animator.get_root_motion_position())
    m_rotation_accumulated *= rotation


## Applies accumulated root motion since the last [[apply]]
func apply() -> void:
    p_body.quaternion *= m_rotation_accumulated

    if m_lock_xz:
        m_motion_accumulated.y = 0.0

    p_body.velocity = m_motion_accumulated
    p_body.move_and_slide()

    clear()


## Clears accumulated root motion data
func clear() -> void:
    m_motion_accumulated = Vector3.ZERO
    m_rotation_accumulated = Quaternion.IDENTITY
    m_last_rotation = p_body.quaternion

#endregion

#region Utils

## 'Oriented Positional Root Motion'
func __oprm(motion: Vector3) -> Vector3:
    return ((
        # Consider the body's orientation when applying motion
        p_animator.get_root_motion_rotation_accumulator().inverse()
            * m_last_rotation)

        # Note:
        # Positional root motion seems to behave better when
        # scaled using the physics process delta
        * (motion / p_body.get_physics_process_delta_time())
    )

#endregion
