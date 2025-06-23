@warning_ignore_start("unused_private_class_variable")

@tool
## A horizontal sprite sheet that is played forwards
class_name VFXStrip2D
extends Sprite2D

@export_subgroup("VFX Strip")
@export_tool_button("Preview", "__editor_preview")
var __preview_button = __editor_preview

@export
var m_duration := 0.25

var p_playback: Tween


#region Events

func _ready() -> void:
    if Engine.is_editor_hint():
        return

    visible = false

#endregion

#region Functions

## Plays the VFX Strip from front to back
func play(finished_callback := Callable()) -> void:
    p_playback = Utils.twinit(self, p_playback)
    visible = true
    frame = 0

    p_playback.tween_property(self, ^"frame", hframes - 1, m_duration)
    p_playback.tween_callback(func():
        visible = false

        if !finished_callback.is_valid():
            return

        finished_callback.call()
    )

#endregion

#region Utils

func __editor_preview() -> void:
    p_playback = Utils.twinit(self, p_playback)
    frame = 0

    p_playback.tween_property(self, ^"frame", hframes - 1, m_duration)

#endregion
