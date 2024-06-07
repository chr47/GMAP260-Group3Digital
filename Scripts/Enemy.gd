extends CharacterBody3D
#Different control states for enemy ai
enum States{
	patrol,
	chasing,
	hunting,
	waiting
}

#Constants for states, nav, speed, wait time, sight and sound
@onready var currentState := States.patrol
@onready var navigationAgent := $NavigationAgent3D
@export var waypoints: Array[Marker3D]
@onready var player := get_tree().get_nodes_in_group("Player")[0]
@onready var patrolTimer := $PatrolTimer
@export var chaseSpeed = 6
@export var patrolSpeed = 4

var waypointIndex : int
var playerInEarshotFar : bool
var playerInEarshotClose : bool
var playerInSightFar : bool
var playerInSightClose : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("enemy")
	navigationAgent.set_target_position(waypoints[0].global_position)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#Changing between events and their functions
	match currentState:
		States.patrol:
			if(navigationAgent.is_navigation_finished()):
				currentState = States.waiting
				patrolTimer.start()
				return
			MoveTowardsPoint(delta, patrolSpeed)
			pass
			
		States.chasing:
			if(navigationAgent.is_navigation_finished()):
				patrolTimer.start()
				currentState = States.waiting
			navigationAgent.set_target_position(player.global_position)
			MoveTowardsPoint(delta, chaseSpeed)
			pass
			
		States.hunting:
			if(navigationAgent.is_navigation_finished()):
				patrolTimer.start()
				currentState = States.waiting
			
			MoveTowardsPoint(delta, patrolSpeed)
			pass
		States.waiting:
			pass
	pass
	
func MoveTowardsPoint(delta, speed):
	var targetPos = navigationAgent.get_next_path_position()
	var direction = global_position.direction_to(targetPos)
	faceDirection(targetPos)
	velocity = direction * speed
	move_and_slide()
	if(playerInEarshotFar):
		CheckForPlayer()

#Raycasting for the player based on distance sound and crouching
func CheckForPlayer():
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create($Head.global_position, player.get_node("PlayerHeadCrouch").global_position, 1, [self]))
	#Event system for tracking changes in distance relative to crouching
	if result.size() > 0:
		if(result["collider"].is_in_group("Player")):
			if(playerInEarshotClose):
				if(result["collider"].crouched == false):
					currentState = States.chasing
					
			if(playerInEarshotFar):
				if(result["collider"].crouched == false):
					currentState = States.hunting
					navigationAgent.set_target_position(player.global_position)
			
			#In the event that the monster is close and can see you,
			#The monster will begin to hunt you instantly.
			if(playerInSightClose):
				if result["collider"].LightLevel > .3:
					currentState = States.chasing
					
			if(playerInSightFar):
				if(result["collider"].crouched == false) && result["collider"].LightLevel > .6:
					currentState = States.hunting
					navigationAgent.set_target_position(player.global_position)
				if(result["collider"].crouched == true) && result["collider"].LightLevel > .7:
					currentState = States.hunting
					navigationAgent.set_target_position(player.global_position)
	pass

#Directional look for monster
func faceDirection(direction: Vector3):
	look_at(Vector3(direction.x, global_position.y, direction.z), Vector3.UP)

#Patrol behavior system
func _on_patrol_timer_timeout():
	currentState = States.patrol
	waypointIndex += 1
	if waypointIndex > waypoints.size() - 1:
		waypointIndex = 0
	navigationAgent.set_target_position(waypoints[waypointIndex].global_position)
	pass # Replace with function body.

#Function event system for sight and sound
func _on_hearing_far_body_entered(body):
	if body.is_in_group("Player"):
		playerInEarshotFar = true
		print("Player is far in earshot")
	pass # Replace with function body.


func _on_hearing_far_body_exited(body):
	if body.is_in_group("Player"):
		playerInEarshotFar = false
		print("Player has left far earshot")
	pass # Replace with function body.


func _on_hearing_close_body_entered(body):
	if body.is_in_group("Player"):
		playerInEarshotClose = true
		print("Player is close in earshot")
	pass # Replace with function body.


func _on_hearing_close_body_exited(body):
	if body.is_in_group("Player"):
		playerInEarshotClose = false
		print("Player has left close earshot")
	pass # Replace with function body.


func _on_sight_far_body_entered(body):
	if body.is_in_group("Player"):
		playerInSightFar = true
		print("Player has entered far sight")
	pass # Replace with function body.


func _on_sight_far_body_exited(body):
	if body.is_in_group("Player"):
		playerInSightFar = false
		print("Player has left far sight")
	pass # Replace with function body.


func _on_sight_close_body_entered(body):
	if body.is_in_group("Player"):
		playerInSightClose = true
		print("Player has entered close sight")
	pass # Replace with function body.


func _on_sight_close_body_exited(body):
	if body.is_in_group("Player"):
		playerInSightClose = false
		print("Player has left close sight")
	pass # Replace with function body.
