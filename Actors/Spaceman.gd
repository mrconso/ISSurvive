extends Actor

const ACCELERATION = 10
const MAX_SPEED = 600.0
const HORIZONTAL_FRICTION = 0.15
const PROPULSION = 800

const MAX_JUMP = -750.0
const AIR_RESIST = 0.02

const reloadTime = 1
export var inertia = 10

onready var timer = get_node("Timer")

var readyToFire = false

func _on_reload_timeout() -> void:
	readyToFire = true
	
func _ready():
	timer.set_wait_time(reloadTime)
	timer.start()

func _process(delta: float):
	if Input.is_action_just_pressed("mouse_click_left") and readyToFire:
			readyToFire = false
			timer.set_wait_time(reloadTime)
			timer.start()
			propulsion(self.global_position)

#Runs in parallel with the parent process
func _physics_process(delta: float) -> void:
	var is_jump_interrupted: = Input.is_action_just_released("jump") and _velocity.y < 0.0
	var direction: = get_direction()
	_velocity = calculate_velocity(_velocity, direction, is_jump_interrupted)
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL, false, 4, PI/4, false)
	apply_rigid_collision()

func get_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
		-1.0 if Input.is_action_just_pressed("jump") and is_on_floor() else 1.0
	)

func calculate_velocity(
		linear_velocity: Vector2, 
		direction: Vector2,
		is_jump_interrupted: bool
	) -> Vector2:
	var velocity = linear_velocity
	
	#Horizontal Velocity with resistance 
	if direction.x > 0:
		velocity.x = min(velocity.x + ACCELERATION * direction.x, MAX_SPEED * direction.x)
	elif direction.x < 0:
		velocity.x = max(velocity.x + ACCELERATION * direction.x, MAX_SPEED * direction.x)
	elif is_on_floor():
		velocity.x = lerp(velocity.x, 0, HORIZONTAL_FRICTION)
	else:
		velocity.x = lerp(velocity.x, 0, AIR_RESIST)
		
	#Vertical Velocity with resistance
	velocity.y += gravity * get_physics_process_delta_time()
	if direction.y == -1.0:
		velocity.y = MAX_JUMP
	if is_jump_interrupted:
		velocity.y -= velocity.y / 2
	return velocity

func propulsion(start_pos: Vector2): 
	var direction = (get_global_mouse_position() - start_pos).normalized()
	_velocity = -direction * PROPULSION
	
func apply_rigid_collision():
	#Loop through al the collisions
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider.is_in_group("bodies"):
			collision.collider.apply_central_impulse(-collision.normal * inertia)






