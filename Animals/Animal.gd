extends KinematicBody2D

export (int) var SPAWNING_RANGE = 30
export (int) var attack_power = 5
export (int) var speed = 75
signal attack
var STATE = "idle"
var moves = []
var letters = {}
var type
var target_position = global_position
var start_position = global_position
var nearby_animals = []
var switch_animation

func _ready():
	add_to_group("animals")
	$AnimatedSprite.connect("animation_finished", self, "on_animation_finished")
	$FightZone.connect("body_entered", self, "FightZone_on_body_entered")
	$FightZone.connect("body_exited", self, "FightZone_on_body_exited")
	$ChaseZone.connect("body_entered", self, "ChaseZone_on_body_entered")
	$ChaseZone.connect("body_exited", self, "ChaseZone_on_body_exited")
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")
	for letter in name.to_upper():
		letters[letter] = false

func pick_new_target_position():
	target_position = start_position + Vector2(rand_range(-50, 50), rand_range(-50, 50))

func FightZone_on_body_entered(body):
	if body.name == "Player": 
		Game.MODE = "battle"
		Game.switch_scene_battle(self)

func FightZone_on_body_exited(body):
	#if body.is_in_group("animals"): nearby_animals.erase(body)
	pass

func ChaseZone_on_body_entered(body):
	if body.name == "Player":
		STATE = "chase"
	elif body.is_in_group("animals"):
		nearby_animals.append(body)

func ChaseZone_on_body_exited(body):
	if body.name == "Player":
		STATE = pick_new_state(["idle", "wander"])
	elif body.is_in_group("animals"):
		nearby_animals.erase(body)

func set_positions(current_position):
	start_position = current_position
	target_position = current_position

func letter_recieved(letter):
	if letter in name.to_upper() and Game.mouse_hovering == self:
		letters[letter] = true
		get_node("../Name/MarginContainer/HBoxContainer/%s" % letter).hide()
		if all(letters.values()): 
			get_node("../Name").hide()
			Game.battle.enemies.erase(self)
			queue_free()
		 
func all(list):
	for item in list:
		if item == false:
			return false
	return true

func pick_new_state(states):
	states.shuffle()
	return states[0]

func on_mouse_entered():
	Game.mouse_hovering = self
	
func on_mouse_exited():
	#Game.mouse_hovering = null
	pass

func attack(move):
	emit_signal("attack", move)
	$AnimatedSprite.play(move)
	switch_animation = "idle"

func on_AttackTimer_timeout():
	attack(moves[0])
	$AttackTimer.start()
	
func on_animation_finished():
	if switch_animation: 
		$AnimatedSprite.play(switch_animation)
		switch_animation = null
