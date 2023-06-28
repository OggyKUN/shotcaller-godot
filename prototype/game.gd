extends Control

# self = game

signal game_started
signal game_map_loaded
signal game_resumed
signal game_one_sec_cycle
signal game_paused
signal game_ended

var built:bool = false
var ended:bool = false
var paused:bool = true
var victory:bool

var player_kills:int = 0
var player_deaths:int = 0
var enemy_kills:int = 0
var enemy_deaths:int = 0

var player_choose_leaders:Array = []
var player_leaders:Array = []
var player_units:Array = []
var player_buildings:Array = []
var enemy_choose_leaders:Array = []
var enemy_leaders:Array = []
var enemy_units:Array = []
var enemy_buildings:Array = []
var selectable_units:Array = []
var neutral_buildings:Array = []
var all_buildings:Array = []

var map:Node2D
var selected_leader:Node2D

var player_team:String = "blue"
var enemy_team:String = "red"
var mode:String = "match" # campaign
var control_state:String = "selection"

@onready var background := $"%waterfall_background"
@onready var maps := $"%maps"
@onready var hud := $"%hud"
@onready var ui := $"%ui"
@onready var collision := $"%collision"
@onready var selection := $"%selection"
@onready var test := $"%test"
@onready var transitions := $"%transitions"

var rng = RandomNumberGenerator.new()


func _ready():
#	Engine.time_scale = 2
	WorldState.set_state("is_game_active", false)
	WorldState.set_state("all_units", [])
	setup_one_sec_timer()
	if test.debug: test.start()
	else: ui.show_main_menu()


func start():
	maps.load_map(maps.current_map)
	ui.hide_version()
	transitions.start()
	transitions.transition_completed.connect(get_map_texture)


func get_map_texture():
	ui.minimap.update_map_texture = true


func _input(event):
	var over_minimap = ui.minimap.over_minimap(event) 
	WorldState.set_state("over_minimap", over_minimap)

	if over_minimap:
		ui.minimap.input(event)
	else:
		selection.input(event)

	Crafty_camera.input(event)


func map_loaded():
	if not WorldState.get_state("game_started"):
		WorldState.set_state("game_started", true)
		resume()
		emit_signal("game_map_loaded")
		
		WorldState.set_state("is_game_active", true)
		rng.randomize()
		WorldState.one_sec_timer.start()
		maps.spawn.start()
		
		emit_signal("game_started")


func resume():
	paused = false
	get_tree().paused = false
	WorldState.one_sec_timer.paused = false
	maps.spawn.timer.paused = false
	ui.show_all()
	ui.hide_menus()
	ui.show_minimap()
	ui.control_panel.show()
	ui.scoreboard.hide()
	emit_signal("game_resumed")


func pause():
	paused = true
	get_tree().paused = true
	WorldState.one_sec_timer.paused = true
	maps.spawn.timer.paused = true
	ui.show_pause_menu()
	emit_signal("game_paused")


func setup_one_sec_timer():
	WorldState.one_sec_timer.wait_time = 1
	WorldState.one_sec_timer.name = "one_sec_timer"
	WorldState.one_sec_timer.timeout.connect(one_sec_cycle)
	add_child(WorldState.one_sec_timer)


func one_sec_cycle(): # called every second 
	if not paused:
		WorldState.time += 1
		
		if not ended:
			var array = [player_kills, player_deaths, WorldState.time, enemy_kills, enemy_deaths]
			ui.top_label.text = "player: %s/%s - time: %s - enemy: %s/%s" % array
			ui.scoreboard.update()
		else:
			ui.top_label.hide()
			
		for unit1 in WorldState.get_state("all_units"):
			var has_regen = (unit1.regen > 0)
			var is_building = (unit1.type == "building")
			var is_neutral = (unit1.team == "neutral")
			if unit1.type == "leader" and not test.debug:
				ui.inventories.update_consumables(unit1)
			if can_control(unit1): unit1.set_delay()
			if ( has_regen and (!is_building or ( is_building and is_neutral )) ):
				unit1.set_regen()
				unit1.set_dot()
		
		emit_signal("game_one_sec_cycle")


func _process(_delta: float) -> void:
	Crafty_camera.process()
	ui.process()


func _physics_process(delta: float) -> void:
	if WorldState.get_state("game_started"):
		collision.process(delta)
		Behavior.path.draw(WorldState.get_state("selected_unit"))
		Goap.process(WorldState.get_state("all_units"), delta)


func can_control(unit1):
	return (unit1 
		and unit1.team == player_team 
		and not unit1.dead
		and (test.debug or unit1.type == "leader")
	) 


func end(winner: bool):
	paused = true
	get_tree().paused = true
	WorldState.one_sec_timer.paused = true
	maps.spawn.timer.paused = true
	ended = true
	victory = winner
	ui.scoreboard.handle_game_end(winner)
	emit_signal("game_ended")


func reload():
	get_tree().reload_current_scene()


func exit():
	get_tree().quit(0)


func apply_cheat_code(code):
	match code:
		"SHADOW":
			for unit1 in WorldState.get_state("all_units"):
				if unit1.has_node("light"): unit1.get_node("light").shadow_enabled = false
		"WIN":
			end(true)
		"LOSE":
			end(false)

