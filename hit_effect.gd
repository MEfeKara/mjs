extends Node2D

func _ready():
	$GPUParticles2D.emitting = true
	# Efekt bitince kendi kendini silsin, hafızada yer kaplamasın
	await get_tree().create_timer(1.0).timeout
	queue_free()
