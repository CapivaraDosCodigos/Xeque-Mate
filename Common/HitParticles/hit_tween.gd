extends Object
class_name HitAnimation

const HIT_DURATION: float = 0.4
const KNOCKBACK_FORCE: float = 16.0
const STRETCH_VECTOR: Vector2 = Vector2(1.3, 0.7)


static func hit_enemy(damage: int, attacker: Vector2, target: Enemy2D) -> void:
	target.health.value -= damage
	target.is_stunned = true

	var tween: Tween = target.create_tween().set_parallel(true)

	target.sprite.material.set("shader_parameter/blink_intensity", 1.0)
	target.sprite.scale = STRETCH_VECTOR
	target.sprite.position -= target.global_position.direction_to(attacker) * KNOCKBACK_FORCE
	target.particles.emitting = true

	tween.tween_property(target.sprite.material, "shader_parameter/blink_intensity", 0.0, HIT_DURATION) \
		.set_ease(Tween.EASE_OUT_IN).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(target.sprite, "scale", Vector2.ONE, HIT_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(target.sprite, "position", Vector2.ZERO, HIT_DURATION) \
		.set_ease(Tween.EASE_OUT_IN).set_trans(Tween.TRANS_CUBIC)

	tween.tween_await(target.create_tween().tween_interval(0.6).finished)

	tween.tween_callback(func() -> void: if not target.health.is_life(): target.queue_free.call_deferred())


static func hit_player(damage: int, attacker: Vector2, target: Player2D) -> void:
	target.health.value -= damage

	var tween: Tween = target.create_tween().set_parallel(true)

	target.sprite.material.set("shader_parameter/blink_intensity", 1.0)
	target.sprite.scale = STRETCH_VECTOR
	target.sprite.position -= target.global_position.direction_to(attacker) * KNOCKBACK_FORCE
	target.particles.emitting = true
	target.camera.shake()

	tween.tween_property(target.sprite.material, "shader_parameter/blink_intensity", 0.0, HIT_DURATION) \
		.set_ease(Tween.EASE_OUT_IN).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(target.sprite, "scale", Vector2.ONE, HIT_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(target.sprite, "position", Vector2.ZERO, HIT_DURATION) \
		.set_ease(Tween.EASE_OUT_IN).set_trans(Tween.TRANS_CUBIC)

	tween.tween_await(target.create_tween().tween_interval(0.6).finished)

	tween.tween_callback(func() -> void: if not target.health.is_life(): target.queue_free.call_deferred())
