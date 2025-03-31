## A resource used by SCHLib's audio system to handle playback of named audio items
class_name AudioLibrary
extends Resource

@export
var p_entries: Dictionary[StringName, AudioItem]

#region Methods

## Returns the first AudioItem named [id]
func get_audio_item(id: StringName) -> AudioItem:
    return p_entries.get(id)


## Returns the AudioStream of the first AudioItem named [id]
func get_stream(id: StringName) -> AudioStream:
    var item: AudioItem = p_entries.get(id)

    if item == null:
        return null

    return item.get_stream()

#endregion
