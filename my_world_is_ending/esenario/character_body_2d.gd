extends CharacterBody2D

# --------------------------------------
#  MOVIMIENTO BÁSICO
# --------------------------------------
@export var speed: float = 300.0
@export var acceleration: float = 25.0
@export var friction: float = 20.0
# --------------------------------------
#  SALTO MEJORADO
# --------------------------------------
@export var jump_force: float = 500.0
@export var jump_cut_multiplier: float = 0.5
@export var coyote_time: float = 0.1
@export var jump_buffer: float = 0.1
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_jump_cut: bool = false
# --------------------------------------
#  DASH MEJORADO
# --------------------------------------
@export var dash_speed: float = 1200.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.4
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 1.0
var can_dash: bool = true
# --------------------------------------
#  WALL JUMP / WALL SLIDE
# --------------------------------------
@export var wall_slide_speed: float = 100.0
@export var wall_jump_force: Vector2 = Vector2(400, -400)
var is_wall_sliding: bool = false
var wall_direction: int = 0
# --------------------------------------
#  COMBATE
# --------------------------------------
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.3
var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
var combo_count: int = 0
var last_attack_time: float = 0.0
# --------------------------------------
#  EFECTOS
# --------------------------------------
@export var screen_shake_intensity: float = 5.0
var is_invulnerable: bool = false
# --------------------------------------
#  FÍSICA
# --------------------------------------
@export var gravity: float = 1200.0
# --------------------------------------
#  REFERENCIAS
# --------------------------------------
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	animated_sprite.play("idle")
	setup_input_actions()


func setup_input_actions() -> void:
	if not InputMap.has_action("dash"):
		var dash_event := InputEventKey.new()
		dash_event.keycode = KEY_SHIFT
		InputMap.add_action("dash")
		InputMap.action_add_event("dash", dash_event)
		print("✅ Acción 'dash' creada")

	if not InputMap.has_action("attack"):
		var attack_event := InputEventKey.new()
		attack_event.keycode = KEY_Z
		InputMap.add_action("attack")
		InputMap.action_add_event("attack", attack_event)
		print("✅ Acción 'attack' creada")


# ------------------------------------------------------------------
#  BUCLE PRINCIPAL
# ------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	update_timers(delta)

	var direction := Input.get_axis("ui_left", "ui_right")
	var jump_pressed := Input.is_action_just_pressed("ui_accept")
	var jump_released := Input.is_action_just_released("ui_accept")
	var dash_pressed := Input.is_action_just_pressed("dash")
	var attack_pressed := Input.is_action_just_pressed("attack")

	handle_dash(delta, direction, dash_pressed)
	if is_dashing:
		move_and_slide()
		return

	handle_wall_mechanics(direction, jump_pressed)
	handle_gravity(delta)
	handle_horizontal_movement(direction, delta)
	handle_jump(jump_pressed, jump_released)
	handle_attack(attack_pressed)

	move_and_slide()
	handle_animations(direction)


# ------------------------------------------------------------------
#  TIMERS
# ------------------------------------------------------------------
func update_timers(delta: float) -> void:
	coyote_timer = coyote_time if is_on_floor() else coyote_timer - delta
	jump_buffer_timer -= delta
	dash_cooldown_timer -= delta
	attack_cooldown_timer -= delta


# ------------------------------------------------------------------
#  DASH
# ------------------------------------------------------------------
func handle_dash(delta: float, direction: float, dash_pressed: bool) -> void:
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			velocity.x *= 0.5
		return

	if dash_pressed and dash_cooldown_timer <= 0.0 and direction != 0.0:
		start_dash(direction)


func start_dash(direction: float) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_direction = sign(direction)

	velocity.x = dash_direction * dash_speed
	velocity.y = 0.0

	animated_sprite.play("dash")
	animated_sprite.flip_h = dash_direction < 0.0
	create_dash_trail()

	if camera and camera.has_method("screen_shake"):
		camera.screen_shake(screen_shake_intensity, dash_duration)

	is_invulnerable = true
	await get_tree().create_timer(dash_duration).timeout
	is_invulnerable = false


# ------------------------------------------------------------------
#  WALL
# ------------------------------------------------------------------
func handle_wall_mechanics(_direction: float, jump_pressed: bool) -> void:
	wall_direction = 0
	if is_on_wall():
		var space := get_world_2d().direct_space_state
		var left := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2.LEFT * 20.0)
		var right := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2.RIGHT * 20.0)

		if space.intersect_ray(left):
			wall_direction = -1
		elif space.intersect_ray(right):
			wall_direction = 1

	is_wall_sliding = false
	if wall_direction != 0 and not is_on_floor() and velocity.y > 0.0:
		is_wall_sliding = true
		velocity.y = min(velocity.y, wall_slide_speed)
		if jump_pressed:
			velocity.x = wall_jump_force.x * -float(wall_direction)
			velocity.y = wall_jump_force.y
			is_wall_sliding = false


# ------------------------------------------------------------------
#  GRAVEDAD
# ------------------------------------------------------------------
func handle_gravity(delta: float) -> void:
	if not is_on_floor() and not is_wall_sliding and not is_dashing:
		velocity.y += gravity * delta
	elif is_wall_sliding:
		velocity.y += gravity * delta * 0.3


# ------------------------------------------------------------------
#  MOVIMIENTO HORIZONTAL
# ------------------------------------------------------------------
func handle_horizontal_movement(_direction: float, _delta: float) -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * speed, acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction)


# ------------------------------------------------------------------
#  SALTO
# ------------------------------------------------------------------
func handle_jump(jump_pressed: bool, _jump_released: bool) -> void:
	if jump_pressed:
		jump_buffer_timer = jump_buffer

	if jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0) and not is_wall_sliding:
		velocity.y = -jump_force
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		animated_sprite.play("jump")
		if camera and camera.has_method("screen_shake"):
			camera.screen_shake(screen_shake_intensity * 0.5, 0.1)


# ------------------------------------------------------------------
#  ATAQUE
# ------------------------------------------------------------------
# ------------------------------------------------------------------
#  ATAQUE - SISTEMA CORREGIDO (GODOT 4)
# ------------------------------------------------------------------
func handle_attack(attack_pressed: bool) -> void:
	if attack_pressed and attack_cooldown_timer <= 0.0 and not is_attacking and is_on_floor():
		start_attack()

func start_attack() -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	
	# SISTEMA DE COMBO
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_attack_time < 0.8:
		combo_count = (combo_count + 1) % 3
	else:
		combo_count = 0
	
	last_attack_time = current_time
	
	# DETENER MOVIMIENTO DURANTE ATAQUE
	velocity.x *= 0.3
	
	# ELEGIR Y REPRODUCIR ANIMACIÓN DE ATAQUE
	var attack_animation = get_attack_animation_name()
	animated_sprite.play(attack_animation)
	print("🔫 Iniciando ataque: ", attack_animation)
	
	# EMPUJE DURANTE ATAQUE
	velocity.x += 100.0 * dash_direction
	
	# SCREEN SHAKE
	if camera and camera.has_method("screen_shake"):
		camera.screen_shake(screen_shake_intensity * 0.3, 0.15)
	
	# ESPERAR A QUE TERMINE EL ATAQUE (TIEMPO FIJO)
	var attack_duration = get_attack_duration(attack_animation)
	await get_tree().create_timer(attack_duration).timeout
	
	# FINALIZAR ATAQUE
	is_attacking = false
	print("✅ Ataque terminado")

func get_attack_animation_name() -> String:
	# VERIFICAR QUÉ ANIMACIONES DE ATAQUE EXISTEN
	if animated_sprite.sprite_frames.has_animation("attack_" + str(combo_count + 1)):
		return "attack_" + str(combo_count + 1)
	elif animated_sprite.sprite_frames.has_animation("attack"):
		return "attack"
	else:
		# SI NO HAY ANIMACIÓN DE ATAQUE, USAR WALK COMO FALLBACK
		print("⚠️ No hay animación de ataque, usando 'walk'")
		return "walk"

func get_attack_duration(animation_name: String) -> float:
	# DURACIONES PREDEFINIDAS PARA CADA ANIMACIÓN
	var durations = {
		"attack_1": 0.4,
		"attack_2": 0.35,
		"attack_3": 0.5,
		"attack": 0.4,
		"walk": 0.3  # Fallback
	}
	
	return durations.get(animation_name, 0.4)  # 0.4 segundos por defecto
# ------------------------------------------------------------------
#  ANIMACIONES
# ------------------------------------------------------------------
# ------------------------------------------------------------------
#  ANIMACIONES - SISTEMA CORREGIDO
# ------------------------------------------------------------------
func handle_animations(direction: float) -> void:
	# Si está atacando, no cambiar animación hasta que termine
	if is_attacking:
		return
	
	# Si está en dash, mantener animación de dash
	if is_dashing:
		if animated_sprite.animation != "dash":
			animated_sprite.play("dash")
		return
	
	# WALL SLIDE
	if is_wall_sliding:
		if animated_sprite.animation != "wall_slide":
			animated_sprite.play("wall_slide")
		animated_sprite.flip_h = wall_direction > 0
		return
	
	# EN EL AIRE
	if not is_on_floor():
		# Determinar si está subiendo o cayendo
		if velocity.y < 0:
			# SALTO (subiendo)
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
		else:
			# CAÍDA
			if animated_sprite.sprite_frames.has_animation("fall"):
				if animated_sprite.animation != "fall":
					animated_sprite.play("fall")
			else:
				# Si no tiene animación "fall", usar "jump"
				if animated_sprite.animation != "jump":
					animated_sprite.play("jump")
		return
	
	# EN EL SUELO
	if abs(velocity.x) > 10:
		# CAMINANDO
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
		# Voltear sprite según dirección
		animated_sprite.flip_h = direction < 0 if direction != 0 else animated_sprite.flip_h
	else:
		# QUIETO
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")


# ------------------------------------------------------------------
#  TRAIL DASH
# ------------------------------------------------------------------
func create_dash_trail() -> void:
	var trail := Sprite2D.new()
	trail.texture = animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation,
		animated_sprite.frame
	)
	trail.global_position = global_position
	trail.flip_h = animated_sprite.flip_h
	trail.modulate = Color(1, 1, 1, 0.5)
	trail.z_index = -1
	get_parent().add_child(trail)

	var tween := create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(trail, "scale", Vector2(1.3, 1.3), 0.3)
	tween.tween_callback(trail.queue_free)
