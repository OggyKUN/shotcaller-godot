tool
extends YSort

signal spawn_creep

export(Units.TeamID) var team = Units.TeamID.Blue setget set_team
export(bool) var mirror_mode = false

var _is_ready: bool = false
var creep_spawner_position: Vector2 = Vector2.ZERO
var buildings: Array = []

onready var building_container: YSort = $BuildingContainer


func set_team(value: int) -> void:
	team = value
	if _is_ready:
		setup_team()
		if team == Units.TeamID.Red:
			scale.x = -1
			return
		scale.x = 1


func _ready() -> void:
	if not Engine.editor_hint:
		_is_ready = true
		creep_spawner_position = $CreepSpawnerPosition.global_position
		buildings = $BuildingContainer.get_children()
		
		Game.connect("playing", self, "_on_Game_playing")
		connect("spawn_creep", self, "_on_TeamArea_spawn_creep")
		set_team(team)
		


func setup_team() -> void:
	for b in $BuildingContainer.get_children():
		b.set_team(team)


func _on_Game_playing() -> void:
	pass


func _on_TeamArea_spawn_creep() -> void:
	pass