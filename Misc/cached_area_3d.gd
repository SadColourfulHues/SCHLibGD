## A variant of Area3D that stores overlapping bodies in an array
## Override _area_body_entered to add candidate filtering
class_name CachedArea3D
extends Area3D

var p_bodies: Array[Node3D]


#region Events

func _ready() -> void:
    body_entered.connect(_area_body_entered)
    body_exited.connect(_area_body_exited)


func _area_body_entered(candidate: Node3D) -> void:
    p_bodies.append(candidate)


func _area_body_exited(candidate: Node3D) -> void:
    p_bodies.erase(candidate)

#endregion
