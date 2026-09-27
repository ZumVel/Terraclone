class_name Player
extends CharacterBody2D

## Игрок: движение (A/D + прыжок), гравитация, добыча/установка блоков мышью.

const SPEED := 150.0
const JUMP_VELOCITY := -260.0
const REACH := 5.0 * 16.0 # дистанция взаимодействия в пикселях (5 тайлов)

var inventory: Inventory
var mined_count := 0
var _break_progress := 0.0
var _breaking_cell := Vector2i(-1, -1)

## Ссылки на соседей — через группы (компонентная связность: player.tscn можно
## вставить в любую сцену, где есть узел в группе "world" и CanvasLayer-UI)
var world: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")
	inventory = Inventory.new()
	for n in get_tree().get_nodes_in_group("world"):
		if n.has_method("set_camera"):
			world = n as Node2D
			n.set_camera(camera)
			break
	if world == null:
		push_error("Player: не найден узел мира в группе 'world' — движение/добыча недоступны")
	else:
		position = world.spawn_point() + Vector2(0, -16)
	_setup_animated_sprite()
	for n in get_tree().get_nodes_in_group("ui"):
		if n.has_method("bind_player"):
			n.bind_player(self)
			break

## Сборка кадров анимации из Image (без внешних файлов).
## Важно: у SpriteFrames кадры добавляются напрямую — типа "SpriteFramesAnimation" в Godot нет.
func _setup_animated_sprite() -> void:
	var data := PlayerSprites.build_frames()
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for anim_name: String in data:
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, anim_name == "run")
		for im in data[anim_name]:
			frames.add_frame(anim_name, ImageTexture.create_from_image(im), 0.12)
	sprite.sprite_frames = frames
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if world == null:
		return
	# Гравитация и плавание в воде
	var cx := int(global_position.x / World.TILE)
	var in_water := world.get_tile(cx, int((global_position.y + 6) / World.TILE)) == 10 \
		or world.get_tile(cx, int((global_position.y - 6) / World.TILE)) == 10

	if not is_on_floor():
		velocity.y += (420.0 if in_water else 700.0) * delta
	if in_water:
		velocity.x = move_toward(velocity.x, dir_now() * SPEED * 0.6, 300.0 * delta)
		velocity.y = minf(velocity.y, 90.0)
		if Input.is_action_pressed("jump"):
			velocity.y = -120.0
	else:
		velocity.x = dir_now() * SPEED

	# Прыжок
	if Input.is_action_just_pressed("jump") and (is_on_floor() or in_water):
		velocity.y = JUMP_VELOCITY

	var dir := dir_now()
	if dir != 0.0:
		sprite.flip_h = dir > 0.0
		if in_water:
			sprite.play("jump")
		elif is_on_floor():
			sprite.play("run")
		else:
			sprite.play("jump")
	elif is_on_floor():
		sprite.play("idle")
	else:
		sprite.play("jump")

	move_and_slide()
	_handle_mining(delta)

func dir_now() -> float:
	return Input.get_axis("move_left", "move_right")

func _handle_mining(delta: float) -> void:
	if world == null:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_break_progress = 0.0
		_breaking_cell = Vector2i(-1, -1)
		return

	var item := inventory.selected_item()
	if item.get("id", 0) != Inventory.ITEM_PICKAXE:
		return # не кирка — не копаем

	var cell := _mouse_cell()
	if not world.in_bounds(cell.x, cell.y):
		return
	var id := world.get_tile(cell.x, cell.y)
	var def := BlockDB.get_def(id)
	if id == 0 or def.pickaxe_power_required < 0:
		return
	if (Vector2(cell * World.TILE) + Vector2(8, 8) - global_position).length() > REACH:
		return

	if BlockDB.get_state(id) != BlockDef.State.SOLID:
		return

	if def.pickaxe_power_required > inventory.pickaxe_power():
		_toast("Нужна кирка мощнее! «%s» требует мощь %d, у тебя %d" % [
			def.display_name, def.pickaxe_power_required, inventory.pickaxe_power()])
		_break_progress = 0.0
		return

	if cell != _breaking_cell:
		_breaking_cell = cell
		_break_progress = 0.0

	# Скорость ломания зависит от требуемой мощи
	_break_progress += delta * (4.0 / maxf(1.0, float(def.pickaxe_power_required)))
	world.break_flash = cell
	world.queue_redraw()

	if _break_progress >= 1.0:
		world.set_tile(cell.x, cell.y, 0)
		world.break_flash = Vector2i(-1, -1)
		_break_progress = 0.0
		_breaking_cell = Vector2i(-1, -1)
		if def.default_item:
			inventory.add_item(id, 1)
		mined_count += 1
		# Прокачка инструментов по мере добычи (как прогрессия в Terraria)
		if mined_count >= 60:
			inventory.upgrade_tools(2)
		elif mined_count >= 25:
			inventory.upgrade_tools(1)
		_toast("Добыто: %s (всего %d)" % [def.display_name, mined_count])

func _try_place() -> void:
	if world == null:
		return
	var item := inventory.selected_item()
	var id := int(item.get("id", 0))
	if id <= 0:
		return # инструмент, а не блок
	var cell := _mouse_cell()
	if not world.in_bounds(cell.x, cell.y):
		return
	if world.get_tile(cell.x, cell.y) != 0:
		return
	if (Vector2(cell * World.TILE) + Vector2(8, 8) - global_position).length() > REACH:
		return
	# Не ставить блок в себя
	var rect := Rect2(global_position - Vector2(6, 13), Vector2(12, 26))
	if rect.intersects(Rect2(cell * World.TILE, Vector2(16, 16))):
		return
	if inventory.take_selected(1):
		world.set_tile(cell.x, cell.y, id)
		_toast("Установлено: %s" % BlockDB.get_def(id).display_name)

func _try_hammer() -> void:
	if world == null:
		return
	var item := inventory.selected_item()
	if item.get("id", 0) != Inventory.ITEM_HAMMER:
		return
	var cell := _mouse_cell()
	if not world.in_bounds(cell.x, cell.y):
		return
	var id := world.get_tile(cell.x, cell.y)
	if id == 0:
		return
	if (Vector2(cell * World.TILE) + Vector2(8, 8) - global_position).length() > REACH:
		return
	BlockDB.hammer_state(id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				_try_place()
			MOUSE_BUTTON_MIDDLE:
				_try_hammer()
		# Колёсико — выбор слота
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			inventory.selected = (inventory.selected - 1) % Inventory.SLOT_COUNT
			if inventory.selected < 0:
				inventory.selected += Inventory.SLOT_COUNT
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			inventory.selected = (inventory.selected + 1) % Inventory.SLOT_COUNT
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			inventory.selected = event.keycode - KEY_1
		elif event.keycode == KEY_0:
			inventory.selected = 9

func _mouse_cell() -> Vector2i:
	var gp := get_global_mouse_position()
	return Vector2i(floori(gp.x / World.TILE), floori(gp.y / World.TILE))

func _toast(text: String) -> void:
	var sent := false
	for n in get_tree().get_nodes_in_group("ui"):
		if n.has_method("set_message"):
			n.set_message(text)
			sent = true
			break
	if not sent:
		print("[HUD] ", text)
