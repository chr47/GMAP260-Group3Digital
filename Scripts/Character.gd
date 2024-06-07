extends CharacterBody3D

#Constants for player movement
const SPEED = 5.0
const CROUCHSPEED = 2.0
const JUMP_VELOCITY = 4.5
@export var sensitivity = 3
var crouched : bool
var flashLightIsOut : bool
var LightLevel : float

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#Taking mouse input for camera look
func _ready():
	add_to_group("character")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#Tracking jump for physics data
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	LightLevel = get_node("Light Detect").LightLevel
	print(LightLevel)

# Get the input direction and handle the movement/deceleration.
# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("MoveLeft", "MoveRight", "MoveForward", "MoveBackwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed = SPEED
	if Input.is_action_pressed("Crouch"):
		if !crouched:
			$AnimationPlayer.play("Crouch")
			crouched = true
	else:
		if crouched:
			var space_state = get_world_3d().direct_space_state
			var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(position, position + Vector3(0,2,0), 1, [self]))
			if result.size() == 0:
				$AnimationPlayer.play("UnCrouch")
				crouched = false
#Handles bug that makes player run fast while under objects
		if crouched:
			speed = CROUCHSPEED
	
#Flashlight input and animation player
	if Input.is_action_just_pressed("Flashlight"):
		if flashLightIsOut:
			$AnimationPlayer.play("FlashlightHide")
		else:
			$AnimationPlayer.play("FlashlightShow")
		flashLightIsOut = !flashLightIsOut
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		

	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		print(collision.get_collider().name)
		if collision.get_collider().name == "Enemy":
			kill_character()


func kill_character():
	# Handle character death, e.g., remove it from the scene
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")
	
#Camera clamping for controlled rotational movement
func _input(event):
	if(event is InputEventMouseMotion): 
		rotation.y -= event.relative.x / 1000 * sensitivity
		$Camera3D.rotation.x -= event.relative.y / 1000 * sensitivity
		rotation.x = clamp(rotation.x, PI/-2, PI/2)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -.2, .2)
