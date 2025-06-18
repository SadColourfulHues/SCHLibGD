## A convenience control that allows for easy manipulation of parameters
## provided by the bar shader material.
class_name SCHBar
extends Panel

const SKEY_FAC := &"instance_shader_parameters/fac"
const SKEY_DELTA := &"instance_shader_parameters/delta_fac"
const NP_FAC := ^"instance_shader_parameters/fac"
const NP_DELTA := ^"instance_shader_parameters/delta_fac"

@export_subgroup("Duration")
@export
var m_duration_in: float = 0.65

@export
var m_duration_out: float = 0.45

@export_subgroup("Tween")
@export
var m_trans_main := Tween.TransitionType.TRANS_SINE

@export
var m_trans_delta := Tween.TransitionType.TRANS_SINE

var p_tween: Tween
var m_last_value: float


#region Events

func _enter_tree() -> void:
    m_last_value = get(SKEY_FAC)
    set(SKEY_DELTA, m_last_value)

#endregion

#region Function

## Animates the value of the bar
func set_value(next_value: float) -> void:
    p_tween = Utils.twinit(self, p_tween)

    next_value = clamp(next_value, 0.0, 1.0)
    m_last_value = next_value

    var add := next_value > m_last_value
    var main_duration := m_duration_in if add else m_duration_out
    var delta_duration := m_duration_out if add else m_duration_in

    (
        p_tween.tween_property(self, NP_FAC, next_value, main_duration)
            .set_trans(m_trans_main)
            .set_ease(Tween.EASE_OUT if add else Tween.EASE_IN)
    )

    (
        p_tween.tween_property(self, NP_DELTA, next_value, delta_duration)
            .set_trans(m_trans_delta)
            .set_ease(Tween.EASE_IN if add else Tween.EASE_OUT)
    )

#endregion

#region Properties

var value: float :
    set(value):
        set_value(value)

    get():
        return m_last_value

#endregion
