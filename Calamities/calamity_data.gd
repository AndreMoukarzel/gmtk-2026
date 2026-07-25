class_name CalamityData
extends Resource

@export var calamity_id: StringName
@export var calamity_name: String
@export_multiline var description: String
@export var icon: Texture2D

# Quanto tempo a calamidade permanece ativa.
@export var duration: float = 10.0
