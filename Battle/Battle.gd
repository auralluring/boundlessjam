extends Node2D

signal letter
export (int) var POTION_DROP_CHANCE = 4 #chance is 1/_
var ATTACK_ANIMATION_RANGE = 15
export (float) var dashtime = 0.3
onready var dashtimer = Timer.new()
onready var lettertimer = Timer.new()
var enemies setget set_enemies
var potions = []
export (bool) var order_required = false
var letter_scene = preload("Letters/Letter.tscn")
var letter = ""
var morse_to_letters = {
	"._":"A",
	"_...":"B",
	"_._.":"C",
	"_..":"D",
	".":"E",
	".._.":"F",
	"__.":"G",
	"....":"H",
	"..":"I",
	".___":"J",
	"_._":"K",
	"._..":"L",
	"__":"M",
	"_.":"N",
	"___":"O",
	".__.":"P",
	"__._":"Q",
	"._.":"R",
	"...":"S",
	"_":"T",
	".._":"U",
	"..._":"V",
	".__":"W",
	"_.._":"x",
	"_.__":"Y",
	"__..":"Z",
}
var letters_to_morse = {}


var enemy_move_damage = {
	"bite": 0.5,
	"claw": 1,
	"pounce": 2,
	"jab": 1.5,
	"chomp": 3,
	"slam": 2.5,
	
}
func _ready():
	Game.MODE = "battle"
	Game.battle = self
	for key in morse_to_letters.keys():
		letters_to_morse[morse_to_letters[key]] = key
	if Game.first_battle: 
		$Tutorial/DoTutorial.visible = true
		get_tree().paused = true
		Game.first_battle = false
	Game.player = $Player
	Game.particles = $Player/CPUParticles2D
	Game.dash_progress_bar = $Player/DashBar
	Game.inventory_node = $Player/Camera2D/Inventory
	Game.inventory_nodes.small_potion.connect("mouse_entered", Game, "on_mouse_entered_item", ["small_potion"])
	Game.inventory_nodes.small_potion.connect("mouse_exited", Game, "on_mouse_exited_item", ["small_potion"])
	Game.inventory_nodes.medium_potion.connect("mouse_entered", Game, "on_mouse_entered_item", ["medium_potion"])
	Game.inventory_nodes.medium_potion.connect("mouse_exited", Game, "on_mouse_exited_item", ["medium_potion"])
	Game.inventory_nodes.large_potion.connect("mouse_entered", Game, "on_mouse_entered_item", ["large_potion"])
	Game.inventory_nodes.large_potion.connect("mouse_exited", Game, "on_mouse_exited_item", ["large_potion"])
	enemies = Game.enemy_battle_data
	$Player/HealthBar.value = $Player.data.hp / $Player.max_hp
	$Player/XPBar.value = Game.xp / 0.7
	if enemies == ["WALRUS"]:
		var enemy = Game.enemy_scenes["WALRUS"].instance()
		$EnemyPosition1.add_child(enemy)
		var attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		enemy.add_child(attack_timer)
		attack_timer.wait_time = rand_range(2, 4)
		attack_timer.connect("timeout", enemy, "on_AttackTimer_timeout")
		attack_timer.start()
		connect("letter", enemy, "letter_recieved")
		enemy.connect("attack", self, "attacked")
		enemy.input_pickable = true
		for j in range(len(enemy.type)):
			var l = enemy.type[j]
			var letter_node = letter_scene.instance()
			letter_node.texture = load("res://Battle/Letters/%s/letters_%s.png" % [l, l])
			letter_node.name = l + str(j)
			enemy.letters[letter_node.name] = false
			enemy.get_node("../Name/MarginContainer/HBoxContainer").add_child(letter_node)
			letter_node.connect("mouse_entered", self, "on_mouse_entered_letter", [letter_node])
			letter_node.connect("mouse_exited", self, "on_mouse_exited_letter", [letter_node])
			letter_node.get_node("PopupPanel/MarginContainer/Label").text = letters_to_morse[l]
			#print(letter_node.get_node("PopupPanel/MarginContainer/Label").text)
			letter_node.get_node("PopupPanel").rect_size = Vector2(len(letters_to_morse[l]) * 5 + 4.5, 9)
			letter_node.get_node("PopupPanel").rect_position = Vector2(-len(letters_to_morse[l]) * 2.5 - 0.5, -12)
		enemy.get_node("../Name").rect_size = Vector2(len(enemy.name) * 7 + 2, 12)
		enemy.get_node("../Name").rect_position = Vector2(-len(enemy.name) * 3 - 0.5, -20)
		enemy.get_node("../Name").visible = true
		$BossBattleTune.play()
	else: 
		for i in range(len(enemies)):
			var enemy = Game.enemy_scenes[enemies[i]].instance()
			enemies[i] = enemy
			get_node("EnemyPosition%s" % i).add_child(enemy)
			var attack_timer = Timer.new()
			attack_timer.name = "AttackTimer"
			enemy.add_child(attack_timer)
			attack_timer.wait_time = rand_range(2, 4)
			attack_timer.connect("timeout", enemy, "on_AttackTimer_timeout")
			attack_timer.start()
			connect("letter", enemy, "letter_recieved")
			enemy.connect("attack", self, "attacked")
			enemy.connect("killed", self, "on_enemy_killed")
			enemy.input_pickable = true
			for j in range(len(enemy.type)):
				var l = enemy.type[j]
				var letter_node = letter_scene.instance()
				letter_node.texture = load("res://Battle/Letters/%s/letters_%s.png" % [l, l])
				letter_node.name = l + str(j)
				enemy.letters[letter_node.name] = false
				enemy.get_node("../Name/MarginContainer/HBoxContainer").add_child(letter_node)
				letter_node.connect("mouse_entered", self, "on_mouse_entered_letter", [letter_node])
				letter_node.connect("mouse_exited", self, "on_mouse_exited_letter", [letter_node])
				letter_node.get_node("PopupPanel/MarginContainer/Label").text = letters_to_morse[l]
				#print(letter_node.get_node("PopupPanel/MarginContainer/Label").text)
				letter_node.get_node("PopupPanel").rect_size = Vector2(len(letters_to_morse[l]) * 5 + 4.5, 9)
				letter_node.get_node("PopupPanel").rect_position = Vector2(-len(letters_to_morse[l]) * 2.5 - 0.5, -12)
			enemy.get_node("../Name").rect_size = Vector2(len(enemy.type) * 7 + 2, 12)
			enemy.get_node("../Name").rect_position = Vector2(-len(enemy.type) * 3 - 0.5, -20)
			enemy.get_node("../Name").visible = true
		$BattleTune.play()
	add_child(dashtimer)
	add_child(lettertimer)
	dashtimer.one_shot = true
	dashtimer.wait_time = dashtime
	lettertimer.one_shot = true
	dashtimer.connect("timeout", self, "on_DashTimer_timeout")
	lettertimer.connect("timeout", self, "on_LetterTimer_timeout")
	
func _physics_process(delta): 
	if not Game.selected_item and not Game.tutorial: interpret_morse()
	elif Game.selected_item and not Game.tutorial and Input.is_action_just_pressed("button"): Game.use_item()
	if not len(enemies) and not len(potions): Game.switch_scene_world()
	if dashtimer.time_left: $Player/DashBar.value = -dashtimer.time_left / dashtime
	else: $Player/DashBar.value = -1.0
	

func on_DashTimer_timeout():
	letter += "_"

func on_LetterTimer_timeout():
	if letter in morse_to_letters.keys():
		print(morse_to_letters[letter])
		$Player/CPUParticles2D.texture = load("res://Battle/Letters/%s/letters_%s.png" % [morse_to_letters[letter], morse_to_letters[letter]])
		$Player/CPUParticles2D.emitting = true
		$Player/AnimatedSprite.play("attack")
		$Player.switch_animation = "idle"
		emit_signal("letter", morse_to_letters[letter])
	else: print(letter)
	letter = ""

func interpret_morse():
	if Input.is_action_just_released("button") and not dashtimer.is_stopped():
		dashtimer.stop()
		lettertimer.start()
		letter += "."
		$Morse.stop()
	elif Input.is_action_just_released("button"):
		lettertimer.start()
		$Morse.stop()
	elif Input.is_action_just_pressed("button"):
		dashtimer.start()
		$Morse.play()
		if not lettertimer.is_stopped(): lettertimer.stop()

func on_mouse_entered_letter(letter_node):
	letter_node.get_node("PopupPanel").visible = true
	
func on_mouse_exited_letter(letter_node):
	letter_node.get_node("PopupPanel").visible = false
	if Game.tutorial and Game.tutorial.part == "EnemyNameHint": Game.tutorial.on_EnemyNameHint_passed()

func attacked(move, enemy): #player has been attacked by a monster
	$Player.data.hp -= enemy_move_damage[move] * enemy.strength * (1 - Game.xp)
	$Player/AnimatedSprite/AnimationPlayer.global_position = $Player.position + Vector2(rand_range(-ATTACK_ANIMATION_RANGE, ATTACK_ANIMATION_RANGE), rand_range(-ATTACK_ANIMATION_RANGE, ATTACK_ANIMATION_RANGE))
	$Player/AnimatedSprite/AnimationPlayer.frame = 0
	$Player/AnimatedSprite/AnimationPlayer.flip_h = randi() % 2 
	$Player/AnimatedSprite/AnimationPlayer.play(move)
	if $Player.data.hp > 0: $Player/HealthBar.value = $Player.data.hp / $Player.max_hp
	else: get_tree().change_scene("res://UI/GameOver.tscn") 

func on_enemy_killed(type, parent):
	if randi() % POTION_DROP_CHANCE: return
	var potion = TextureRect.new()
	match type:
		"BAT", "CAT", "DOG", "RAT":
			potion.texture = load("Items/potion_1.png")
			potion.connect("mouse_entered", Game, "pick_up_potion", ["small", potion])
			if Game.xp < 0.7: Game.xp += 0.01
		"FISH", "HARE", "SWAN", "TOAD":
			potion.texture = load("Items/potion_2.png")
			potion.connect("mouse_entered", Game, "pick_up_potion", ["medium", potion])
			if Game.xp < 0.7: Game.xp += 0.02
		"CAMEL", "EAGLE", "HYENA", "SNAKE":
			potion.texture = load("Items/potion_3.png")
			potion.connect("mouse_entered", Game, "pick_up_potion", ["large", potion])
			if Game.xp < 0.7: Game.xp += 0.03
		_:
			print("super rare")
	parent.add_child(potion)
	potions.append(potion)
	$Player/XPBar.value = Game.xp / 0.7

func set_enemies(enemies_):
	if len(enemies_): enemies = enemies_
	else: Game.switch_scene_world()
