extends CharacterBody3D


const SPEED_INICIAL = 5.0
var speed = SPEED_INICIAL
const JUMP_VELOCITY = 12
var is_dashing = false
var can_dash = true
var dash_recharging = false

var xform : Transform3D

@export var sensitivity = 1000

@export var hud : CanvasLayer

func _physics_process(delta: float) -> void:
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("andar_esquerda", "andar_direita", "andar_frente", "andar_tras")
	
	# Play Robot Animations:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		$AnimationPlayer.play("jump")
	elif is_on_floor() and input_dir != Vector2.ZERO:
		$AnimationPlayer.play("run")
	elif is_on_floor() and input_dir == Vector2.ZERO:
		$AnimationPlayer.play("idle")
	
	# Rotate the camera left / right <<< Custom
	#if Input.is_action_just_pressed("cam_left"):
	#	$Camera_Controller.rotate_y(deg_to_rad(30))
	#if Input.is_action_just_pressed("cam_right"):
	#	$Camera_Controller.rotate_y(deg_to_rad(-30))
	
	# Tentativa minha de melhorar a camera
	#if Input.is_action_pressed("cam_left"):
	#	$Camera_Controller.rotate_y(deg_to_rad(2))
	#if Input.is_action_pressed("cam_right"):
	#	$Camera_Controller.rotate_y(deg_to_rad(-2))
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		$SoundJump.play()
		velocity.y = JUMP_VELOCITY
	
	recharging_dash()
	
	# Handle dash.
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		dash()
	
	# New Vector3 direction, taking into account the user arrow inputs and the camera rotation
	# var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var direction := Vector3 ($Camera_Controller.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Rotate the character mash so oriented towards the direction moving in relation to the camera
	if input_dir != Vector2(0,0):
		$Armature.rotation_degrees.y = $Camera_Controller.rotation_degrees.y - rad_to_deg(input_dir.angle()) - 90
	
	# Rotate the character to align with the floor
	# $RayCast3D.position = position << Resolução dos comentarios que não ta funcionando
	if is_on_floor():
		align_with_floor($RayCast3D.get_collision_normal())
		global_transform = global_transform.interpolate_with(xform, 0.3)
	elif not is_on_floor():
		align_with_floor(Vector3.UP)
		global_transform = global_transform.interpolate_with(xform, 0.3)
	
	# Update the velocity and move the character
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		#print("velocity.x: ", velocity.x, " velocity.z: ", velocity.z)
	elif not is_dashing:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	
	# Make Camera_Controller match the position of myself <<< Custom
	$Camera_Controller.position = lerp($Camera_Controller.position, position, 0.15)

func _input(event):
	if event is InputEventMouseMotion:
		#rotation.y -= event.relative.x / sensitivity
		#$CameraPivot.rotation.x -= event.relative.y / sensitivity
		$Camera_Controller.rotation.y -= event.relative.x / sensitivity
		$Camera_Controller.rotation.x -= event.relative.y / sensitivity
		$Camera_Controller.rotation.x = clamp($Camera_Controller.rotation.x, deg_to_rad(-45), deg_to_rad(90))
	
func align_with_floor(floor_normal):
	xform = global_transform
	xform.basis.y = floor_normal
	xform.basis.x = -xform.basis.z.cross(floor_normal)
	xform.basis = xform.basis.orthonormalized()
	
func _on_fall_zone_body_entered(body: Node3D) -> void:
	SoundManager.play_fall_sound()
	get_tree().change_scene_to_file("res://menu_game_over.tscn")
	# Comentário bom do youtube:
	# * WorldBoundaryShape3D shape is an infinite plane designed specifically for this purpose, so you don't have to worry that your collision box is big/thick enough.
	# * Godot engine doesn't like when you remove objects and/or switch scenes in physics signal handlers. You should use call_deferred() method, or use a Timer
	# * You might need to setup collision layers, otherwise a random falling object will trigger scene transition.
	# * You can use get_tree().reload_current_scene() if you just need to restart the level.

func bounce():
	#$SoundJump.play()
	velocity.y = JUMP_VELOCITY * 0.7

func dash():
	is_dashing = true
	can_dash = false
	hud.updateDash(false)
	
	var timer1 = get_tree().create_timer(0.15)
	var dash_tween = create_tween()
	dash_tween.tween_property($Armature, "rotation_degrees", Vector3(-30, 0, 0), 0.15).as_relative()
	speed = speed * 3
	var forward = -$Armature.global_transform.basis.z
	velocity.x = snappedf(forward.x, 0) * speed
	velocity.z = snappedf(forward.z, 0) * speed
	# print("velocity.x: ", velocity.x, " velocity.z: ", velocity.z)
	$SoundDash.play()
	$ParticulasDash.emitir(true)
	await timer1.timeout
	
	var timer2 = get_tree().create_timer(0.05)
	var dash_return_tween = create_tween()
	dash_return_tween.tween_property($Armature, "rotation_degrees", Vector3(30, 0, 0), 0.05).as_relative()
	await timer2.timeout
	$ParticulasDash.emitir(false)
	
	speed = 5.0
	is_dashing = false

func recharging_dash():
	if not can_dash and not dash_recharging:
		dash_recharging = true
		await get_tree().create_timer(1.0).timeout
		while dash_recharging:
			if is_on_floor():
				recharge_dash()
			await get_tree().create_timer(0.2).timeout
		
func recharge_dash():
	hud.updateDash(true)
	can_dash = true
	dash_recharging = false
