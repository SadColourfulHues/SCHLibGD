## A static class holding a collection of easing functions
## Using https://easings.net as a reference
class_name Easing
extends Object


#region Float

## Applies a sine ease to a given value
## [[x]] is expected to be between the range of 0.0 - 1.0
static func sine(x: float, ease_in: bool = true) -> float:
    if ease_in:
        return 1.0 - cos(0.5 * (x * PI))
    return sin(0.5 * (x * PI))


## Applies a quadratic ease to a given value
## [[x]] is expected to be between the range of 0.0 - 1.0
static func quad(x: float, ease_in: bool = true) -> float:
    if ease_in:
        return pow(x, 2.0)
    return 1.0 - pow(1.0 - x, 2.0)


## Applies a cubic ease to a given value
## [[x]] is expected to be between the range of 0.0 - 1.0
static func cubic(x: float, ease_in: bool = true) -> float:
    if ease_in:
        return pow(x, 3.0)
    return 1.0 - pow(1.0 - x, 3.0)


## Applies a quartic ease to a given value
## [[x]] is expected to be between the range of 0.0 - 1.0
static func quart(x: float, ease_in: bool = true) -> float:
    if ease_in:
        return pow(x, 4.0)
    return 1.0 - pow(1.0 - x, 4.0)


## Applies a quintic ease to a given value
## [[x]] is expected to be between the range of 0.0 - 1.0
static func quint(x: float, ease_in: bool = true) -> float:
    if ease_in:
        return pow(x, 5.0)
    return 1.0 - pow(1.0 - x, 5.0)


## Applies an exponential ease to a given value
## [[x]] is expected to be between the range of 0.0 - 1.0
static func expo(x: float, ease_in: bool = true) -> float:
    if ease_in:
        if is_zero_approx(x):
            return 0.0

        return pow(2.0, 10.0 * x - 10.0)

    ## Ease Out ##
    if is_equal_approx(x, 1.0):
        return 1.0

    return 1.0 - pow(2.0, -10.0 * x)


## Applies a circular ease to a given value
## [[x]] is expected to be between the range of 0.0 - 1.0
static func circ(x: float, ease_in: bool = true) -> float:
    if ease_in:
        return 1.0 - sqrt(1.0 - pow(x, 2.0))
    return sqrt(1.0 - pow(x - 1.0, 2.0))


## Applies an elastic ease to a given value (ease-out only)
## [[x]] is expected to be between the range of 0.0 - 1.0
static func elastic(x: float) -> float:
    if is_zero_approx(x):
        return x
    elif is_equal_approx(x, 1.0):
        return 1.0
    return (
        pow(2.0, -10.0 * x)
        * sin((x * 10.0 - 0.75)
              * (TAU / 3.0))
        + 1.0
    )

#endregion
