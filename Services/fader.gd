## An optional Autoload service that handles simple fade in/out transitions
extends CanvasLayer

var p_tween: Tween
var p_rect: ColorRect


#region Events

func _enter_tree() -> void:
    layer = 100

    p_rect = ColorRect.new()
    add_child.call_deferred(p_rect)

    p_rect.modulate = Color(0.0, 0.0, 0.0, 0.0)
    p_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

    p_rect.anchor_left = 0.0
    p_rect.anchor_top = 0.0
    p_rect.anchor_right = 1.0
    p_rect.anchor_bottom = 1.0

#endregion

#region Faders

## Force sets the opacity of the fader rect into the specified state
func force_fade_state(faded: bool) -> void:
    p_rect.modulate.a = 1.0 if faded else 0.0


## Updates the fade effect colour
func set_fade_colour(colour: Color) -> void:
    p_rect.modulate = Color(colour.r, colour.g, colour.b, p_rect.modulate.a)


## Starts a fade out transition
func fade_out(delay: float,
            duration: float,
            callback := Callable()) -> bool:

    if !__begin_tween():
        return false

    __delay(delay)
    __fade_out(duration)
    __callback(callback)

    return true


## Starts a fade in transition
func fade_in(delay: float,
            duration: float,
            callback := Callable()) -> bool:

    if !__begin_tween():
        return false

    __delay(delay)
    __fade_in(duration)
    __callback(callback)

    return true


## Starts a full fade transition
func fade_out_in(fade_out_duration: float,
                fade_in_duration: float,
                wait_delay: float = 0.0,
                callback := Callable()) -> bool:

    if !__begin_tween():
        return false

    __fade_out(fade_out_duration)
    __delay(wait_delay)
    __fade_in(fade_in_duration)
    __callback(callback)

    return true

#endregion

#region Utils

func __begin_tween() -> bool:
    if is_instance_valid(p_tween) && p_tween.is_running():
        return false

    p_tween = create_tween()
    return true


func __fade_out(duration: float) -> void:
    p_tween.tween_property(p_rect, ^"modulate:a", 1.0, duration) \
            .set_trans(Tween.TRANS_SINE) \
            .set_ease(Tween.EASE_IN)


func __fade_in(duration: float) -> void:
    p_tween.tween_property(p_rect, ^"modulate:a", 0.0, duration) \
        .set_trans(Tween.TRANS_SINE) \
        .set_ease(Tween.EASE_OUT)


func __delay(amount: float) -> void:
    if is_zero_approx(amount):
        return

    p_tween.tween_interval(amount)


func __callback(callback: Callable) -> void:
    if !callback.is_valid():
        return

    p_tween.tween_callback(callback)

#endregion