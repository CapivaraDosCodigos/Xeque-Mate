class_name CameraCustom2D extends Camera2D
#
#static var global_camera: CameraCustom2D
#
#@export var smoothing_speed: float = 5.0
#
#@export var zoom_speed: float = 3.0
#@export var offset_above_player: Vector2 = Vector2.ZERO
#
#@export var peek_distance: float = 160.0
#@export var peek_tween_duration: float = 0.4
#
#@export var player: CharacterBody2D
#
#@export var all_areas: Array[CameraArea2D] = []
#
#var current_area: CameraArea2D
#var previous_area: CameraArea2D
#
#var transitioning: bool = false
#
#var transition_tween: Tween
#var peek_tween: Tween
#
#var base_offset: Vector2 = Vector2.ZERO
#var peek_offset: Vector2 = Vector2.ZERO # problem
#var shake_offset: Vector2 = Vector2.ZERO
#
#
#func _enter_tree() -> void:
	#base_offset = offset
#
	#if enabled:
		#global_camera = self
#
#
#func _physics_process(delta: float) -> void:
	#offset = base_offset + peek_offset + shake_offset
#
	#if not player or all_areas.is_empty():
		#return
#
	#_find_current_area()
#
	#var desired_position: Vector2 = _get_desired_position(delta)
	#var bound_position: Vector2
#
	#if current_area:
		#bound_position = current_area.get_bound_position(desired_position)
	#else:
		#bound_position = desired_position
#
	#_update_camera_position(bound_position, delta)
	#_update_zoom(delta)
#
#
#func instant_snap() -> void:
	#if not player:
		#return
#
	#for area in all_areas:
		#if area.contains_point(player.global_position):
			#current_area = area
			#current_area.enter()
			#global_position = area.get_bound_position(player.global_position + offset_above_player)
			#zoom = Vector2.ONE * area.zoom_level
			#break
#
#
## Todo Provavelmente inútil
#func reset_current_area() -> void:
	#if current_area and not current_area.auto_restart:
		#current_area.enter()
#
#
## Todo Provavelmente inútil
#func request_peek(dir: int) -> void:
	#if dir == 0:
		#cancel_peek()
		#return
	#var y: float = dir * peek_distance
	#tween_peek(Vector2(0.0, y))
#
#
## Todo Provavelmente inútil
#func cancel_peek() -> void:
	#tween_peek(Vector2.ZERO)
#
#
## Todo Provavelmente inútil
#func tween_peek(target: Vector2) -> void:
	#if peek_tween:
		#peek_tween.kill()
#
	#peek_tween = create_tween()
	#peek_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#peek_tween.tween_property(self, "peek_offset", target, peek_tween_duration)
#
#
#func shake(magnitude: float, duration: float) -> void:
	#var elapsed: float = 0.0
	#var shake_interval: float = 0.05
#
	#while elapsed < duration:
		#shake_offset = Vector2(
			#randf_range(-magnitude, magnitude),
			#randf_range(-magnitude, magnitude)
		#)
		#await get_tree().create_timer(shake_interval).timeout
		#elapsed += shake_interval
#
	#shake_offset = Vector2.ZERO
#
#
#func _get_zoom_area() -> Vector2:
	#if not current_area:
		#return zoom
#
	#return current_area.zoom_level * Vector2.ONE
#
#
#func _get_desired_position(_delta: float) -> Vector2:
	#return player.global_position + offset_above_player
#
#
#func _update_camera_position(target_position: Vector2, delta: float) -> void:
	#if transitioning:
		#return
#
	#global_position = global_position.lerp(target_position, clamp(smoothing_speed * delta, 0.0, 1.0))
#
#
#func _update_zoom(delta: float) -> void:
	#if not current_area or transitioning:
		#return
#
	#zoom = zoom.lerp(_get_zoom_area(), zoom_speed * delta) # Aqui pode ter problema
#
#
#func _find_current_area() -> void:
	#var player_pos: Vector2 = player.global_position
#
	#if not current_area == null and current_area.contains_point(player_pos):
		#return
#
	#for area: CameraArea2D in all_areas:
		#if area.contains_point(player_pos):
			#if area != current_area:
				#_enter_area(area)
			#return
#
#func _enter_area(next: CameraArea2D) -> void:
	#if transitioning and previous_area:
		#_try_despawn_area(previous_area)
#
	#previous_area = current_area
	#current_area = next
	#current_area.enter()
#
	#if not previous_area:
		#return
#
	#var desired: Vector2 = player.global_position + offset_above_player
	#var new_bound_pos: Vector2 = current_area.get_bound_position(desired)
#
	#if transition_tween:
		#transition_tween.kill()
#
	#transitioning = true
	#player.process_mode = Node.PROCESS_MODE_DISABLED
	#transition_tween = create_tween()
	#transition_tween.set_trans(current_area.enter_trans).set_ease(current_area.enter_ease)
	#transition_tween.tween_property(self, "global_position", new_bound_pos, current_area.enter_duration)
	#transition_tween.parallel().tween_property(self, "zoom", _get_zoom_area(), current_area.enter_duration)
	#transition_tween.finished.connect(_on_transition_finished.bind(previous_area))
#
#
#func _on_transition_finished(area_left: CameraArea2D) -> void:
	#transitioning = false
	#player.process_mode = Node.PROCESS_MODE_INHERIT
	#_try_despawn_area(area_left)
#
#
#func _try_despawn_area(area: CameraArea2D) -> void:
	#if area and not area.auto_restart and not area.has_spawned:
		#area.exit()
