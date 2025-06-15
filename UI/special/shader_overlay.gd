## A variant of SimpleOverlay that uses a shader-driven overlay effect
## instead of its usual fades
class_name ShaderOverlay
extends SimpleOverlay

@export_subgroup("Shader Overlay")
@export
var m_param_fac_path: NodePath

@export
var m_inactive_value: float = 0.0

@export
var m_active_value: float = 1.0

#region Events

func _ready() -> void:
    super._ready()

    set(m_param_fac_path as String, m_inactive_value)
    self_modulate.a = 1.0

#endregion

#region Shader Overlay

func _on_animate(現れる: bool) -> void:
    (
        p_tween.tween_property(
            self,
            m_param_fac_path,
            m_active_value if 現れる else m_inactive_value,
            m_duration
        )
        .set_trans(m_transition_type)
        .set_ease(Tween.EASE_OUT)
    )

#endregion
