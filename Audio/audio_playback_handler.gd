## A node that handles convenient audio playback
## (Based of SCHLib.Audio.AudioPlayer)
class_name AudioPlaybackHandler
extends Node

#region Configuration

@export_group("Playback")
@export
var p_playback_resource: AudioPlayback

@export
var p_audio_library: AudioLibrary

@export_group("Features")
## The maximum number of audio players per type (non-positional, 2D, 3D)
@export
var m_max_players := 32

## This flag sets whether or not this node is capable of playing non-positional audio
@export
var m_supports_non_positional := false
## This flag sets whether or not this node is capable of playing back 2D audio
@export
var m_supports_2d := false
## This flag sets whether or not this node is capable of playing back 3D audio
@export
var m_supports_3d := false

@export_group("Configuration/Shared")
## The default bus to target when playing back audio
@export
var m_default_bus := &"Master"

@export_range(0.0, 3.0)
var m_panning_strength := 1.0

@export_group("Configuration/2D")
## Maximum distance where a sound could be heard in 2D
@export
var m_2d_max_distance := 1000.0

## How quickly is sound attenuated in 2D
@export_exp_easing
var m_2d_attenuation := 1.0

@export_group("Configuration/3D")
## Maximum distance where a sound can be heard in 3D
@export
var m_3d_max_distance := 15.0

## The unit size to base all 3D sound players on. (Higher values makes the sound audible over larger distances.)
@export
var m_3d_base_unit_size := 10.0

## The attenuation model to use for 3D audio
@export
var m_3d_attenuation_model := AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC

## The cutoff frequency of the attenuation filter in Hz
@export
var m_3d_attenuation_cutoff := 20500

## This value affects how much the attenuation filter affects the loudness in decibels
@export
var m_3d_attenuation_db := -60.0

## The absolute maximum sound level in decibels
@export
var m_3d_max_decibels := 0.0

#endregion

var p_np_players: Array[AudioStreamPlayer]
var p_2d_players: Array[AudioStreamPlayer2D]
var p_3d_players: Array[AudioStreamPlayer3D]

#region Events

func _enter_tree() -> void:
    __configure.call_deferred()

    p_playback_resource.stream_request_np_playback.connect(play_stream)
    p_playback_resource.stream_request_2d_playback.connect(play_stream_2d)
    p_playback_resource.stream_request_3d_playback.connect(play_stream_3d)
    p_playback_resource.item_request_np_playback.connect(play_item)
    p_playback_resource.item_request_2d_playback.connect(play_item_2d)
    p_playback_resource.item_request_3d_playback.connect(play_item_3d)


func _exit_tree() -> void:
    if !is_instance_valid(p_playback_resource):
        return

    p_playback_resource.stream_request_np_playback.disconnect(play_stream)
    p_playback_resource.stream_request_2d_playback.disconnect(play_stream_2d)
    p_playback_resource.stream_request_3d_playback.disconnect(play_stream_3d)
    p_playback_resource.item_request_np_playback.disconnect(play_item)
    p_playback_resource.item_request_2d_playback.disconnect(play_item_2d)
    p_playback_resource.item_request_3d_playback.disconnect(play_item_3d)


#endregion

#region Playback

## Plays a specified AudioStream through one of its non-positional players
func play_stream(stream: AudioStream,
                volume: float = 1.0,
                max_pitch_variance: float = 0.0,
                bus: StringName = m_default_bus) -> void:

    if !m_supports_non_positional:
        return

    var player: AudioStreamPlayer = __get_player(p_np_players)

    if player == null:
        return

    player.stream = stream
    player.volume_db = __get_volume(volume)
    player.pitch_scale = __get_pitch_variance(max_pitch_variance)
    player.bus = bus

    player.play()


## Plays a positional AudioStream through one of its 2D audio players
func play_stream_2d(stream: AudioStream,
                    position: Vector2,
                    volume: float = 1.0,
                    max_pitch_variance: float = 0.0,
                    max_distance_mod: float = 1.0,
                    bus: StringName = m_default_bus) -> void:

    if !m_supports_2d:
        return

    var player: AudioStreamPlayer2D = __get_player(p_2d_players)

    if player == null:
        return

    player.stream = stream
    player.volume_db = __get_volume(volume)
    player.pitch_scale = __get_pitch_variance(max_pitch_variance)
    player.max_distance = m_2d_max_distance * max_distance_mod
    player.bus = bus

    player.global_position = position
    player.play()


## Plays a positional AudioStream through one of its 3D audio players
func play_stream_3d(stream: AudioStream,
                    position: Vector3,
                    volume: float = 1.0,
                    max_pitch_variance: float = 0.0,
                    max_distance_mod: float = 1.0,
                    unit_size_mod: float = 1.0,
                    bus: StringName = m_default_bus) -> void:

    if !m_supports_3d:
        return

    var player: AudioStreamPlayer3D = __get_player(p_3d_players)

    if player == null:
        return

    player.stream = stream
    player.volume_db = __get_volume(volume)
    player.pitch_scale = __get_pitch_variance(max_pitch_variance)
    player.max_distance = m_3d_max_distance * max_distance_mod
    player.unit_size = m_3d_base_unit_size * unit_size_mod
    player.bus = bus

    player.global_position = position
    player.play()


## Plays a specified item from its library through one of its non-positional players
func play_item(id: StringName,
                volume: float = 1.0,
                max_pitch_variance: float = 0.0,
                bus: StringName = m_default_bus) -> void:

    var stream := __get_stream(id)

    if stream == null:
        return

    play_stream(
        stream,
        volume,
        max_pitch_variance,
        bus
    )


## Plays a specified item from its library positionally in 2D space
func play_item_2d(id: StringName,
                position: Vector2,
                volume: float = 1.0,
                max_pitch_variance: float = 0.0,
                max_distance_mod: float = 1.0,
                bus: StringName = m_default_bus) -> void:

    var stream := __get_stream(id)

    if stream == null:
        return

    play_stream_2d(
        stream,
        position,
        volume,
        max_pitch_variance,
        max_distance_mod,
        bus
    )


## Plays a specified item from its library positionally in 3D space
func play_item_3d(id: StringName,
                position: Vector3,
                volume: float = 1.0,
                max_pitch_variance: float = 0.0,
                max_distance_mod: float = 1.0,
                unit_size_mod: float = 1.0,
                bus: StringName = m_default_bus) -> void:

    var stream := __get_stream(id)

    if stream == null:
        return

    play_stream_3d(
        stream,
        position,
        volume,
        max_pitch_variance,
        max_distance_mod,
        unit_size_mod,
        bus
    )

#endregion

#region Utils

func __get_player(source: Array):
    for candidate in source:
        if (!is_instance_valid(candidate) ||
            (candidate.stream != null && candidate.playing)):
            continue
        return candidate
    return null


func __get_stream(id: StringName) -> AudioStream:
    if p_audio_library == null:
        return null

    return p_audio_library.get_stream(id)


func __get_volume(volume: float) -> float:
    return linear_to_db(max(0.001, volume))


func __get_pitch_variance(fac: float) -> float:
    if is_zero_approx(fac):
        return 1.0
    return 1.0 + randf_range(-fac, fac)


func __configure() -> void:
    if m_supports_non_positional:
        p_np_players.resize(m_max_players)

        for i: int in range(m_max_players):
            var np_player := AudioStreamPlayer.new()
            add_child(np_player)

            np_player.process_thread_group = Node.PROCESS_THREAD_GROUP_MAIN_THREAD
            p_np_players[i] = np_player

    if m_supports_2d:
        p_2d_players.resize(m_max_players)

        for i: int in range(m_max_players):
            var a2d_player := AudioStreamPlayer2D.new()
            add_child(a2d_player)

            a2d_player.panning_strength = m_panning_strength
            a2d_player.attenuation = m_2d_attenuation
            a2d_player.process_thread_group = Node.PROCESS_THREAD_GROUP_MAIN_THREAD

            p_2d_players[i] = a2d_player

    if m_supports_3d:
        p_3d_players.resize(m_max_players)

        for i: int in range(m_max_players):
            var a3d_player := AudioStreamPlayer3D.new()
            add_child(a3d_player)

            a3d_player.panning_strength = m_panning_strength
            a3d_player.attenuation_filter_cutoff_hz = m_3d_attenuation_cutoff
            a3d_player.attenuation_filter_db = m_3d_attenuation_db
            a3d_player.attenuation_model = m_3d_attenuation_model
            a3d_player.max_db = m_3d_max_decibels
            a3d_player.process_thread_group = Node.PROCESS_THREAD_GROUP_MAIN_THREAD

            p_3d_players[i] = a3d_player

#endregion
