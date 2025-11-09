extends Camera2D

@export var target_node: Node2D
@export var suavizado: float = 5.0

func _process(delta: float) -> void:
	if target_node:
		global_position = global_position.lerp(target_node.global_position, suavizado * delta)
