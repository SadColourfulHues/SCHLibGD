## An audio playback mechanism that handles sfx playback for individual nodes
## (Meant to be used for Player/NPC nodes)
class_name LocalAudioPlayer2D
extends Node2D

@export_subgroup("System")
@export
var p_library: AudioLibrary

@export
var m_max_players: int = 4

@export_subgroup("Default Settings")
@export_exp_easing("attenuation")
var m_attenuation: float = 1.0

@export
var m_max_distance: float = 1000.0

@export
var m_panning_strength: float = 1.0

@export
var m_pitch_scale: float = 1.0

@export
var m_bus: StringName = &"Master"

var p_players: Array[AudioStreamPlayer2D]


#region Events

func _ready() -> void:
    assert(
        is_instance_valid(p_library),
        "LocalAudioPlayer2D: no audio library assigned"
    )

    for _i: int in range(m_max_players):
        var player := AudioStreamPlayer2D.new()

        player.attenuation = m_attenuation
        player.pitch_scale = m_pitch_scale
        player.max_distance = m_max_distance
        player.panning_strength = m_panning_strength
        player.bus = m_bus

        p_players.append(player)
        add_child(player)

#endregion

#region Functions

## Plays a specified SFX with the given ID
func play(id: StringName, volume: float = 1.0) -> void:
    var player := __get_free_player()

    if player == null:
        return

    var item := p_library.get_stream(id)
    assert(item != null, "LocalAudioPlayer2D: invalid SFX ID \"%s\"" % id)

    player.stream = item
    player.volume_linear = volume
    player.pitch_scale = m_pitch_scale

    player.play()


## Plays a specified SFX with the given ID at the specified position
func play_offset(id: StringName, offset: float, volume: float = 1.0) -> void:
    var player := __get_free_player()

    if player == null:
        return

    var item := p_library.get_stream(id)
    assert(item != null, "LocalAudioPlayer2D: invalid SFX ID \"%s\"" % id)

    player.stream = item
    player.volume_linear = volume
    player.pitch_scale = m_pitch_scale

    player.play(offset)


## Randomises the pitch of the next SFX
func randomise_pitch(max_variance: float = 0.1) -> void:
    assert(
        max_variance >= 0.0 && max_variance <= 1.0,
        "LocalAudioPlayer2D: max_variance must be within the range of 0.0 -> 1.0"
    )

    m_pitch_scale = randf_range(
        max(0.0, 1.0 - max_variance),
        min(1.0, 1.0 + max_variance)
    )

#endregion

#region Utils

func __get_free_player() -> AudioStreamPlayer2D:
    for player: AudioStreamPlayer2D in p_players:
        if player.playing:
            continue
        return player
    return null

#endregion
