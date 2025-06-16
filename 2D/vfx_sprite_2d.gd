## A VFX item for drawn effects
## (Automatically gets destroyed on playback end)
class_name VFXSprite2D
extends Sprite2D

## Called when the VFX item is about to be destroyed
signal shutdown()

@export
var m_duration: float = 0.33

@export
var m_destruction_delay: float = 0.3

@export
var m_random_rotate: bool = false


#region Events

func _ready() -> void:
    if m_random_rotate:
        rotation = randf() * TAU

    # Activate child items
    for child: Node in get_children():
        if child is AudioStreamPlayer || child is AudioStreamPlayer2D:
            child.play()
        elif child is GPUParticles2D || child is CPUParticles2D:
            child.restart()

    var tween := create_tween()
    tween.tween_property(self, ^"frame", hframes - 1, m_duration)
    tween.tween_callback(func(): self_modulate.a = 0.0)
    tween.tween_interval(m_destruction_delay)
    tween.tween_callback(_on_shutdown)


func _on_shutdown() -> void:
    shutdown.emit()
    queue_free()

#endregion
