extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
var speed = 200  # <-- velocidad en píxeles/s

func _ready():
	animated_sprite.play("idle")

func _physics_process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed
	move_and_slide()

	if direction != 0:
		animated_sprite.play("walk")
		animated_sprite.flip_h = direction < 0
	else:
		animated_sprite.play("idle")
