## A variant of Area2D that stores overlapping bodies in an array
## Override _area_body_entered to add candidate filtering
class_name CachedArea2D
extends Area2D

var p_bodies: Array[Node2D]


#region Events

func _ready() -> void:
    body_entered.connect(_area_body_entered)
    body_exited.connect(_area_body_exited)


func _area_body_entered(candidate: Node2D) -> void:
    p_bodies.append(candidate)


func _area_body_exited(candidate: Node2D) -> void:
    p_bodies.erase(candidate)

#endregion
