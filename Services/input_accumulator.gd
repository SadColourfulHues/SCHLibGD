## An optional Autoload service that can be used to track the state of certain actions
extends Node

signal pressed(action_id: StringName)
signal tick(action_id: StringName)
signal released(action_id: StringName)

var m_block_requested: bool
var p_actions: Dictionary[StringName, bool]


#region Functions

## Returns true if the given action ID is being pressed
## (this method assumes that the action has already been registered using [track])
func is_pressed(action_id: StringName) -> bool:
    return p_actions[action_id]


## Registers an action to be observed for each process tick
func track(action_id: StringName) -> void:
    if p_actions.has(action_id):
        return

    p_actions[action_id] = false


## Unregisters an action from being observed
func untrack(action_id: StringName) -> void:
    p_actions.erase(action_id)


## Prevents the current input state from changing in the current evaluation
func block() -> void:
    m_block_requested = true

#endregion

#region Events

func _process(_delta: float) -> void:
    for action_id: StringName in p_actions:
        var action_pressed_state := Input.is_action_pressed(action_id)
        var current_state := p_actions[action_id]

        # Pressed/Tick/Released Events #
        if !current_state && action_pressed_state:
            pressed.emit(action_id)

        elif current_state && action_pressed_state:
            tick.emit(action_id)

        elif current_state && !action_pressed_state:
            released.emit(action_id)

        # Allow certain events to be held until a condition is satisfied
        if m_block_requested:
            m_block_requested = false
            continue

        # Update value #
        p_actions[action_id] = action_pressed_state

#endregion
