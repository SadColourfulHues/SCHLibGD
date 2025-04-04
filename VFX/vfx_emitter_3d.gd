## A utility object that spawns VFX items at a specified interval
class_name VFXEmitter
extends Marker3D

## Called whenever the emitter spawns a new VFX node into existence
signal emitted(vfx_node: Node3D)

@export_group("Emitter")
@export
var m_locked: bool

@export
var p_vfx_library: Dictionary[StringName, PackedScene]

@export
var m_follow_transform: bool = true

@export
var m_emit_scale_mod: float = 1.0

@export
var m_default_vfx: StringName = &""

@export
var m_spawn_debounce: float = 0.25

var p_template: PackedScene
var p_timer: Timer


#region Functions

## When set to 'true', this prevents this emitter from being able to spawn
## VFX items
func lock(is_locked: bool) -> void:
    m_locked = is_locked

    if !is_locked:
        return

    set_physics_process(false)


## Toggles if this emitter should be spawning VFX items
func set_active(active: bool) -> void:
    if m_locked:
        return

    set_physics_process(active)

    p_timer = Timer.new()
    p_timer.wait_time = m_spawn_debounce
    p_timer.one_shot = true
    add_child.call_deferred(p_timer)


## Sets the VFX item to emit
func set_vfx(id: StringName) -> void:
    if id.is_empty():
        return

    p_template = p_vfx_library.get(id)
    assert(is_instance_valid(p_template), "VFXEmitter: Invalid default VFX ID")

#endregion

#region Events

func _ready() -> void:
    set_active(false)
    set_vfx(m_default_vfx)


func _physics_process(_delta: float) -> void:
    if !p_timer.is_stopped():
        return

    p_timer.start()

    if !is_instance_valid(p_template):
        return

    var vfx_instance: Node3D = p_template.instantiate()
    vfx_instance.top_level = true

    add_child(vfx_instance)

    vfx_instance.global_position = global_position

    if m_follow_transform:
        vfx_instance.global_basis = global_basis
        vfx_instance.scale = owner.scale * m_emit_scale_mod

    emitted.emit(vfx_instance)
    vfx_instance.reset_physics_interpolation()


#endregion
