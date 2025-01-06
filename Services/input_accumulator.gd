## An optional Autoload service that can be used to track the state of certain actions
extends Node

signal pressed(action_id: StringName)
signal tick(action_id: StringName)
signal released(action_id: StringName)

var m_block_requested: bool
var p_actions: Dictionary[StringName, Data]


#region Functions

## Returns true if the given action ID is being pressed
## (this method assumes that the action has already been registered using [track])
func is_pressed(action_id: StringName) -> bool:
    return p_actions[action_id].m_active


## Returns the amount of time (in seconds) an action is held
func get_press_duration(action_id: StringName) -> float:
    if !p_actions.has(action_id):
        return 0.0

    var action := p_actions[action_id]

    if !action.m_active:
        return 0.0

    return action.get_press_duration()


## Registers an action to be observed for each process tick
## (If fresh checks are disabled, this action can be state-blocked indefinitely.)
func track(action_id: StringName,
        do_fresh_checks: bool = true,
        check_type: CheckType = CheckType.BOTH,
        input_window: float = 0.33) -> void:

    if p_actions.has(action_id):
        return

    p_actions[action_id] = Data.new(input_window, do_fresh_checks, check_type)


## Unregisters an action from being observed
func untrack(action_id: StringName) -> void:
    if !p_actions.has(action_id):
        return

    p_actions[action_id].free()
    p_actions.erase(action_id)


## Prevents the current input state from changing in the current evaluation
func block() -> void:
    m_block_requested = true

#endregion

#region Events

func _process(_delta: float) -> void:
    for action_id: StringName in p_actions:
        var input_active := Input.is_action_pressed(action_id)
        var state := p_actions[action_id]

        # Pressed/Tick/Released Events #
        if !state.m_active && input_active:
            state.mark_press_start()
            pressed.emit(action_id)

        elif state.m_active && input_active:
            tick.emit(action_id)

        elif state.m_active && !input_active:
            released.emit(action_id)

        # Allow certain events to be held until a condition is satisfied
        var was_blocked := m_block_requested
        m_block_requested = false

        # but also prevent it from being held for too long
        if was_blocked && state.is_fresh(input_active):
            continue

        # Update value #
        state.m_active = input_active

#endregion

#region Data Struct

enum CheckType
{
    PRESS,
    RELEASE,
    BOTH
}

class Data extends Object:
    var m_active: bool
    var m_last: int
    var m_input_window: float
    var m_do_fresh_checks: bool
    var m_check_type: CheckType

    func _init(window: float,
            do_fresh_checks: bool,
            check_type: CheckType) -> void:

        m_active = false

        m_do_fresh_checks = do_fresh_checks
        m_check_type = check_type
        m_input_window = window
        m_last = 0


    func mark_press_start() -> void:
        m_last = Time.get_ticks_msec()


    func is_fresh(active: bool) -> bool:
        if !m_do_fresh_checks:
            return true

        # State-dependent guards #
        match m_check_type:
            CheckType.PRESS:
                # Blocks checks on release updates #
                if m_active && !active:
                    return true

            CheckType.RELEASE:
                # Blocks checks on press updates #
                if !m_active && active:
                    return true

        return get_press_duration() <= m_input_window


    func get_press_duration() -> float:
        return (Time.get_ticks_msec() - m_last) * 0.001


#endregion