extends CharacterBody3D


const SPEED:float = 5.0
const AIR_SPEED:float = 3.0
const JUMP_VELOCITY:float = 14.0
const ROT_SMOOTHING:float = 20.0
const SPRINT_MULTIPLIER:float = 1.75


var can_dash:bool = true
var camera:Camera3D;
#var camera_ray_origin
#var camera_ray_end

var health:int;
const MAX_HEALTH:int = 100;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _rotate_player(delta):
	#$PlayerRot.rotation.y = lerp_angle($PlayerRot.rotation.y,atan2(-velocity.z,velocity.x),delta*ROT_SMOOTHING)
	pass
#func _rotate_player(delta):
#	var space_state = get_world_3d().direct_space_state
#	var mouse_position = get_viewport().get_mouse_position()
#
#	camera_ray_origin = camera.project_ray_origin(mouse_position)
#	camera_ray_end = camera_ray_origin+camera.project_ray_normal(mouse_position) * 2000
#
#	var query = PhysicsRayQueryParameters3D.create(camera_ray_origin, camera_ray_end); 
#	var intersection = space_state.intersect_ray(query)
#
#	if not intersection.is_empty():
#		var look_pos = intersection.position
#		$PlayerRot.look_at(Vector3(look_pos.x,position.y,look_pos.z),Vector3.UP)    


func _unhandled_input(event):
	if(event is InputEventMouseMotion):
		$Control/crosshair.position = event.position - $Control/crosshair.scale/2
		var cwinsize = Vector2(get_window().size.x,get_window().size.y)/2
		var mouse_pos_center = cwinsize - event.position
		var angle_mouse_from_center = atan2(mouse_pos_center.y,mouse_pos_center.x)
		$PlayerRot.rotation.y = PI-angle_mouse_from_center
		

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	camera = get_viewport().get_camera_3d()
	health = MAX_HEALTH

func dash_handler(delta):
	var dash_end_position = %DashTarget.global_position
	if($PlayerRot/RayCast3D.get_collider()):
		dash_end_position = $PlayerRot/RayCast3D.get_collision_point()
		
	%DashParticles.emitting = true
	var tweeni = create_tween()
	tweeni.set_parallel(true)
	tweeni.tween_property(self,"global_position",dash_end_position, 0.1)
	tweeni.tween_property(camera,"fov",76, 0.01)
	tweeni.set_parallel(false)
	tweeni.tween_property(%DashParticles,"emitting",false, 0.1)
	tweeni.tween_property(camera,"fov",75, 0.01)

func take_damage(hitpoints:float):
	$Control/BottomBars/UIAnimplayer.play("hurt")
	health -= hitpoints
	process_health()

func process_health():
	var remapped = remap(health,0,MAX_HEALTH,0,256)
	$Control/BottomBars/BASE/HEALTHBAR.size.x = remapped

func _process(delta):
	# Add the gravity.
	var move_speed = SPEED
	if not is_on_floor(): 
		velocity.y -= 3 * gravity * delta
		move_speed = lerp(move_speed,AIR_SPEED,40*delta)

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if(Input.is_action_just_pressed("sprint") and can_dash):
		move_speed *= SPRINT_MULTIPLIER
		can_dash = false
		$Cooldowns/DashTimer.start(1)
		dash_handler(delta)
	$Control/Button.disabled = not can_dash
	if(can_dash):
		$Control/Button.text = str(ceil($Cooldowns/DashTimer.time_left))
		
	if(Input.is_action_just_pressed("attack")):
		$rot_delayed/sword_attacker.play("ATTACK")
		take_damage(10)
	
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		_rotate_player(delta)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 10 * delta)
		velocity.z = move_toward(velocity.z, 0, move_speed * 10 * delta)

	move_and_slide()

func _on_dash_timer_timeout():
	can_dash = true

func hurt_particles():
	$Control/BottomBars/HurtUIParticles.emitting=true
