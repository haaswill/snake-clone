extends Node

@export var snake_tile_scene : PackedScene

@onready var game_over_overlay: CanvasLayer = $GameOver
@onready var timer: Timer = $Timer
@onready var apple: Area2D = $Apple
@onready var score_label: Label = $HUD/Score

const TILE_SIZE : int = 50
const ROW_SIZE : int = 20
const SNAKE_STARTING_POSITION := Vector2(450, 450)
const INITIAL_TIMER_SPEED := 0.5
const MAX_TIMER_SPEED := 0.1
const TIMER_INCREMENT := 0.1
const DIRECTIONS = {
	"up" : Vector2(0, -1),
	"right" : Vector2(1, 0),
	"down" : Vector2(0, 1),
	"left" : Vector2(-1, 0),
}

var score : int
var snake : Array
var current_direction : Vector2
var can_move : bool
var is_new_tile : bool

func _ready() -> void:
	score = 0
	can_move = true
	is_new_tile = false
	current_direction = DIRECTIONS.right
	timer.wait_time = INITIAL_TIMER_SPEED
	timer.start()	
	render_snake(SNAKE_STARTING_POSITION)
	update_score()
	generate_apple()
	game_over_overlay.hide()

func _process(_delta: float) -> void:
	if can_move:
		if Input.is_action_pressed("move_up") and current_direction != DIRECTIONS.down:
			current_direction = DIRECTIONS.up
			can_move = false
		elif Input.is_action_pressed("move_right") and current_direction != DIRECTIONS.left:
			current_direction = DIRECTIONS.right
			can_move = false
		elif Input.is_action_pressed("move_down") and current_direction != DIRECTIONS.up:
			current_direction = DIRECTIONS.down
			can_move = false
		elif Input.is_action_pressed("move_left") and current_direction != DIRECTIONS.right:
			current_direction = DIRECTIONS.left
			can_move = false

func generate_apple() -> void:
	var occupied_positions := snake.map(func(tile): return tile.position)
	var new_position = Vector2((randi() % 19 + 1) * TILE_SIZE, (randi() % 19 + 1) * TILE_SIZE)
	
	while occupied_positions.has(new_position):
		new_position = Vector2((randi() % 19 + 1) * TILE_SIZE, (randi() % 19 + 1) * TILE_SIZE)
		
	apple.position = new_position

func update_score() -> void:
	score_label.text = "SCORE: " + str(score)

func increase_score() -> void:
	score += 1
	timer.stop()
	if "%.1f" % (timer.wait_time) > "%.1f" % (MAX_TIMER_SPEED):
		timer.wait_time -= TIMER_INCREMENT
	update_score()
	generate_apple()
	add_snake_tile()
	timer.start()

func render_snake(pos: Vector2) -> void:
	var snake_tile = snake_tile_scene.instantiate()
	is_new_tile = true
	snake_tile.get_node("SnakeTileArea").area_entered.connect(eat_self)
	snake_tile.position = pos
	call_deferred("add_child", snake_tile)
	snake.append(snake_tile)

func add_snake_tile() -> void:
	render_snake(snake[-1].position)

func game_over() -> void:
	timer.paused = true
	game_over_overlay.show()

func eat_self(area: Area2D) -> void:
	if area.name == "SnakeTileArea" and not is_new_tile:
		game_over()

func _on_timer_timeout() -> void:
	var old_snake_position = snake[0].position
	can_move = true
	for i in range(snake.size()):
		if i > 0:
			var temp_pos = snake[i].position
			snake[i].position = old_snake_position
			old_snake_position = temp_pos
		else:
			snake[0].position += current_direction * TILE_SIZE
	is_new_tile = false

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_apple_area_entered(area: Area2D) -> void:
	if area.name == "SnakeTileArea":
		increase_score()

func _on_killzone_area_entered(_area: Area2D) -> void:
	game_over()
