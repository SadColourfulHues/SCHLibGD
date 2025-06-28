## An optional Autoload service that can be used to track the state of certain actions
extends Node

## Triggered when an action has been pressed
signal pressed(action_id: StringName)
## Triggered when an action has been held
signal tick(action_id: StringName, hold_ticks: float)
## Triggered when an action has been released
signal released(action_id: StringName)

## Repeats the current action's state event until unheld (or expires)
const HOLD_REPEAT := HoldMode.REPEAT
## Triggers the action's tick event
const HOLD_TICK := HoldMode.TICK

var p_actions: Array[Action]

var m_signal := ProcessSignal.NONE
var m_sleep_ticks := 0.0


#region Functions

## Sets the input accumulator to run in [[_physics_process]]
## Setting this to false will revert it back to [[_process]]
func set_process_in_physics(physics_mode: bool = true) -> void:
    set_process(!physics_mode)
    set_physics_process(physics_mode)


## Returns true if the given action ID is being pressed
## (Returns false if the action has not been registered)
func is_pressed(action_id: StringName) -> bool:
    for action: Action in p_actions:
        if action.m_id != action_id:
            continue

        if action.is_held:
            return action.m_held_state

        return action.m_active

    return false


## Returns the amount of ticks an action has been held
func get_hold_duration(action_id: StringName) -> float:
    for action: Action in p_actions:
        if action.m_id != action_id:
            continue

        return action.m_hold_ticks

    return 0.0


## Stops processing for a set amount of time
## (Useful for UIs -- e.g. handling a button press that returns the game to a resumed state.)
func sleep(ticks: float = 0.25) -> void:
    m_sleep_ticks = ticks


## Registers an action to be observed for each process tick
func track(action_id: StringName,
           max_hold_duration: float = 0.15,
           hold_mode := HOLD_REPEAT) -> void:

    p_actions.append(Action.new(action_id,  max_hold_duration, hold_mode))


## Unregisters an action from being observed
func untrack(action_id: StringName) -> void:
    var i: int = 0

    for action: Action in p_actions:
        if action.m_id != action_id:
            i += 1
            continue

        p_actions.remove_at(i)
        return


## Clears all tracked actions
func clear() -> void:
    for action: Action in p_actions:
        action.free()

    p_actions.clear()


## Holds the currently processing action
func hold() -> void:
    m_signal = ProcessSignal.HOLD


## Releases the hold on the currently processing action
func unhold() -> void:
    m_signal = ProcessSignal.UNHOLD

#endregion

#region Events

func _init() -> void:
    set_process(true)
    set_physics_process(false)


func _process(_delta: float) -> void:
    __process_main()


func _physics_process(_delta: float) -> void:
    __process_main()

#endregion

#region Utils

func __process_main() -> void:
    var active_signal: ProcessSignal
    var delta := get_process_delta_time()

    for action: Action in p_actions:
        if m_sleep_ticks > 0.0:
            m_signal = ProcessSignal.NONE
            m_sleep_ticks -= delta
            return

        var next_is_pressed := Input.is_action_pressed(action.m_id)

        # Held Action #

        if action.is_held:
            match action.m_hold_mode:
                HoldMode.TICK:
                    tick.emit(action.m_id, action.m_hold_ticks)

                HoldMode.REPEAT:
                    if action.m_held_state:
                        pressed.emit(action.m_id)
                    else:
                        released.emit(action.m_id)

            action.m_hold_ticks += delta
            continue

        # Normal Action Processing #

        if next_is_pressed && !action.m_pressed:
            action.mark_pressed()
            pressed.emit(action.m_id)

        elif next_is_pressed && action.m_pressed:
            tick.emit(action.m_id, action.m_hold_ticks)

        elif !next_is_pressed && action.m_pressed:
            action.mark_released()
            released.emit(action.m_id)

        # Handle Signals #

        active_signal = m_signal
        m_signal = ProcessSignal.NONE

        match active_signal:
            ProcessSignal.HOLD:
                action.request_hold()

            ProcessSignal.UNHOLD:
                action.m_is_held = false

#endregion

#region Enums

enum ProcessSignal
{
    NONE,
    HOLD,
    UNHOLD,
}

enum HoldMode
{
    REPEAT,
    TICK,
}

#endregion

#region Data Structs

class Action extends Object:
    var m_id: StringName
    var m_pressed: bool

    var m_held_state: bool
    var m_hold_mode: HoldMode
    var m_hold_ticks: float

    var m_max_hold_duration: float
    var m_is_held: bool


    func _init(id: StringName,
               max_hold_duration: float,
               hold_mode: HoldMode) -> void:

        m_id = id
        m_pressed = false

        m_held_state = false
        m_hold_mode = hold_mode
        m_hold_ticks = 0.0

        m_max_hold_duration = max_hold_duration
        m_is_held = false


    func mark_pressed() -> void:
        m_pressed = true
        m_held_state = false
        m_is_held = false

        m_hold_ticks = 0.0


    func mark_released() -> void:
        m_pressed = false
        m_is_held = false


    func request_hold() -> void:
        if hold_remaining <= 0.0:
            return

        m_held_state = m_pressed
        m_is_held = true


    var hold_remaining: float :
        get():
            return max(0.0, m_max_hold_duration - m_hold_ticks)


    var is_held: bool :
        get():
            return m_is_held && hold_remaining > 0.0

#endregion
