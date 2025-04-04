## A type of VFX emitter that only emits when it is touching something
## Unless specified otherwise, it will automatically sleep upon emitting
## and must be awoken to be able to emit again.
class_name VFXContactEmitter3D
extends RayCast3D

## Called whenever the emitter spawns a new VFX node into existence
signal emitted(vfx_node: Node3D)

@export_group("Emitter")
@export
var p_vfx_library: Dictionary[StringName, PackedScene]

@export
var m_align_to_normal: bool = true

@export
var m_follow_scale: bool = true

@export
var m_emit_scale_mod: float = 1.0

@export
var m_wake_emission_window: float = 0.15

@export
var m_spawn_offset: Vector3 = Vector3(0.0, 0.1, 0.0)


@export_group("Emitter/Continuous")
@export
var m_auto_sleep := true

@export
var m_default_vfx: StringName = &""

@export
var m_continuous_debounce: float = 0.25

var p_timer: Timer
var p_template: PackedScene

var m_sleeping: bool


#region Functions

## Awakens the emitter, allows it to re-emit the specified visual effect
## If no [[vfx_id]] is provided, it will use the first item in the VFX
## library.
func wake(vfx_id: StringName = &"") -> void:
    if !p_timer.is_stopped():
        return

    if vfx_id.is_empty():
        if p_vfx_library.is_empty():
            return

        p_template = p_vfx_library.values()[0]

    p_template = p_vfx_library.get(vfx_id)
    assert(is_instance_valid(p_template), "VFXContactEmitter: invalid VFX ID")

    m_sleeping = false


## Toggles the activation state of this emitter
## Use [[wake]] to make it re-emit particles.
## This is only meant to be used when the emitter
## is not expected to do any processing at all.
func set_active(active: bool) -> void:
    m_sleeping = active
    set_physics_process(active)


## Sets the VFX item to emit
func set_vfx(id: StringName) -> void:
    if id.is_empty():
        return

    p_template = p_vfx_library.get(id)
    assert(is_instance_valid(p_template), "VFXContactEmitter: Invalid default VFX ID")

#endregion

#region Events

func _ready() -> void:
    m_sleeping = true

    p_timer = Timer.new()
    p_timer.one_shot = true
    add_child.call_deferred(p_timer)

    set_vfx(m_default_vfx)
    set_physics_process(m_auto_sleep)

    # Timer mode: sleep
    if !m_auto_sleep:
        return

    p_timer.timeout.connect(func(): m_sleeping = true)


func _physics_process(_delta: float) -> void:
    # Timer mode: debounce
    if !m_auto_sleep:
        if !p_timer.is_stopped():
            return

        p_timer.start(m_continuous_debounce)

    # Timer mode: sleep
    else:
        if m_sleeping:
            return

        p_timer.start(m_wake_emission_window)

    if !is_colliding() || !is_instance_valid(p_template):
        return

    var vfx_instance: Node3D = p_template.instantiate()
    var normal := get_collision_normal()

    vfx_instance.top_level = true

    add_child(vfx_instance)

    vfx_instance.global_position = (get_collision_point() + (normal * m_spawn_offset))

    if m_align_to_normal:
        var vfx_trans := vfx_instance.global_transform
        vfx_trans.basis.y = normal
        vfx_trans.basis.x = Vector3.RIGHT
        vfx_trans.basis.z = normal.cross(vfx_trans.basis.x)
        vfx_trans.basis = vfx_trans.basis.orthonormalized()

        vfx_instance.global_transform = vfx_trans

    if m_follow_scale:
        vfx_instance.scale = owner.scale * m_emit_scale_mod
    else:
        vfx_instance.scale = Vector3.ONE * m_emit_scale_mod

    emitted.emit(vfx_instance)
    vfx_instance.reset_physics_interpolation()

    if m_auto_sleep:
        m_sleeping = true
        p_timer.stop()

#endregion
