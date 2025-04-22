## A helper VFX script that automatically adjusts the size of a
## [[GPUParticles3D]]'s first drawing pass based on the scale
## of its owner (root node of the template scene)
class_name VFXGlobalScalingQuad
extends GPUParticles3D

@export_subgroup("Scaling")
## When set to 'true', it will only the use the root's x scale
## when scaling the quad.
@export
var m_uniform_scale: bool = true

## Only works when [[m_uniform_scale]] is set to 'false'
## swaps the y value for the root's z scale when enabled.
@export
var m_scale_use_z_as_y: bool = false

var p_mesh: QuadMesh
var m_original_size: Vector2


#region Events

func _enter_tree() -> void:
    assert(!local_coords, "VFXGlobalScalingQuad: this script is meant to be used with global-space particle effects.")
    assert(is_instance_valid(owner) && owner is Node3D, "VFXGlobalScalingQuad: expects this to be used on a template scene with a Node3D descendant as its root.")
    assert(draw_pass_1 is QuadMesh, "VFXGlobalScalingQuad: expects the first draw pass to be a quad.")

    p_mesh = draw_pass_1.duplicate()
    m_original_size = p_mesh.size
    draw_pass_1 = p_mesh

    update.call_deferred()

#endregion

#region Functions

## Performs a manual scale update
func update() -> void:
    if m_uniform_scale:
        p_mesh.size = m_original_size * owner.scale.x
        return

    p_mesh.size = m_original_size * Vector2(
        owner.scale.x,
        owner.scale.z if m_scale_use_z_as_y else owner.scale.y
    )

#endregion
