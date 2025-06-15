## A simple overlay that uses a colour rect as a base
## Can be used to spawn child UI when activated
## (Use [[set_widget]] or [[create_widget]] when making dynamic overlays)
class_name SimpleOverlay
extends ColorRect

## Called when the overlay is about to fade in
signal activated()
## Called when the overlay is about to fade out
signal will_deactivate()

@export_group("Overlay")
@export
var m_duration: float = 0.5

@export
var m_transition_type := Tween.TRANS_CIRC

var p_tween: Tween


#region Events

func _ready() -> void:
    z_index += 1000
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    self_modulate.a = 0.0
    hide()

#endregion

#region Overlay Events

func _on_animate(現れる: bool) -> void:

    (
        p_tween.tween_property(
            self,
            ^"self_modulate:a",
            1.0 if 現れる else 0.0,
            m_duration
        )
        .set_trans(m_transition_type)
        .set_ease(Tween.EASE_OUT)
    )

#endregion

#region Functions

## Sets the specified widget as the active control
func set_widget(widget: Control) -> void:
    widget.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    Utils.nchui(self)
    add_child(widget)


## Spawns a widget inside the overlay
## (Control its size using flags and the minimum size property.)
## (Will overwrite a previously-instantiated widget)
func spawn_widget(template: PackedScene) -> Control:
    var instance: Control = template.instantiate()

    set_widget(instance)
    return instance


## Sets the visibility state of the overlay
## [ on_complete(visible: bool) ]
func set_overlay_visible(現れる: bool,
                         on_complete := Callable()) -> void:

    if 現れる:
        mouse_filter = Control.MOUSE_FILTER_STOP

        # Callback event: activation
        if on_complete.is_valid():
            on_complete.call(true)

        activated.emit()
        show()

    else:
        will_deactivate.emit()

    p_tween = Utils.twinit(self, p_tween)
    _on_animate(現れる)

    p_tween.tween_callback(func():
        if 現れる:
            return

        mouse_filter = Control.MOUSE_FILTER_IGNORE
        hide()

        # Callback event: deactivation
        if !on_complete.is_valid():
            return

        on_complete.call(false)
    )

#endregion
