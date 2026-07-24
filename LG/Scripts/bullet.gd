extends Area3D

@export var speed: float = 20.0
@export var lifetime: float = 3.0

var direction: Vector3 = Vector3.ZERO

@export var damage: float = 25.0

func _ready() -> void:
	print("Bullet entrou na cena")

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
