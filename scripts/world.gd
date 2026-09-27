class_name World
extends Node2D

## Тайловый мир: генерация рельефа, руд, воды и деревьев.

const W := 180        # ширина в тайлах
const H := 90         # высота в тайлах
const SURFACE := 34   # примерная высота поверхности
const TILE := 16

var tiles: PackedByteArray = PackedByteArray()
var break_flash := Vector2i(-1, -1) # клетка, которую сейчас копают (подсветка)
var body: StaticBody2D               # тело коллизий (пол/стены мира)

func _ready() -> void:
	body = StaticBody2D.new()
	add_child(body)
	generate()
	# Коллизия: одна форма на каждый твёрдый блок над поверхностью (пещеры и
	# подземная часть мира — сплошной блок-«земля», по нему можно стоять).
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE, TILE)
	for cy in range(0, H):
		for cx in range(W):
			if not BlockDB.is_solid(get_tile(cx, cy)):
				continue
			var above_air := false
			for yy in range(maxi(0, cy - 3), cy):
				if not BlockDB.is_solid(get_tile(cx, yy)):
					above_air = true
					break
			if above_air or cy >= H - 4:
				var cs := CollisionShape2D.new()
				cs.shape = shape
				cs.position = Vector2(cx * TILE + TILE / 2.0, cy * TILE + TILE / 2.0)
				body.add_child(cs)
	set_process(true)

func _process(_delta: float) -> void:
	queue_redraw()

func idx(cx: int, cy: int) -> int:
	return cy * W + cx

func in_bounds(cx: int, cy: int) -> bool:
	return cx >= 0 and cy >= 0 and cx < W and cy < H

func get_tile(cx: int, cy: int) -> int:
	if not in_bounds(cx, cy):
		return 3 # за пределами мира — считаем камнем (стена)
	return tiles[idx(cx, cy)]

func set_tile(cx: int, cy: int, id: int) -> void:
	if in_bounds(cx, cy):
		tiles[idx(cx, cy)] = id

func generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260928

	tiles.resize(W * H)
	tiles.fill(0)

	# Рельеф: сумма синусоид + блуждающий шаг
	var heights: Array[int] = []
	var h := SURFACE
	for x in W:
		h += rng.randi_range(-1, 1)
		var wave := int(sin(x * 0.11) * 4.0 + sin(x * 0.031) * 7.0)
		var surface_y := clampi(h + wave, 12, H - 30)
		heights.append(surface_y)

	for x in W:
		var sy := heights[x]
		for y in range(sy, H):
			var depth := y - sy
			var id := 1 # грязь
			if depth == 0:
				id = 2 # дёрн
			elif depth > 5:
				id = 3 # камень
			elif rng.randf() < 0.4:
				id = 3
			tiles[idx(x, y)] = id

	# Песчаные пятна на поверхности
	for i in 6:
		var px := rng.randi_range(5, W - 15)
		var pw := rng.randi_range(5, 12)
		for x in range(px, min(px + pw, W)):
			for y in range(heights[x], heights[x] + rng.randi_range(2, 4)):
				if y < H and tiles[idx(x, y)] != 0:
					set_tile(x, y, 5)

	# Глиняные карманы в толще земли
	for i in 10:
		var gx := rng.randi_range(3, W - 4)
		var gy := rng.randi_range(SURFACE + 8, H - 10)
		for ox in range(-2, 3):
			for oy in range(-1, 2):
				if rng.randf() < 0.7:
					if get_tile(gx + ox, gy + oy) == 3:
						set_tile(gx + ox, gy + oy, 6)

	# Жилы руд: уголь (мощь 3) и золото (мощь 5)
	_ore_vein(rng, 7, 26, 4, 8)
	_ore_vein(rng, 8, 14, 3, 6)

	# Одиночные блоки адского камня у дна (мощь 7)
	for i in 20:
		var vx := rng.randi_range(2, W - 3)
		var vy := rng.randi_range(H - 8, H - 2)
		if get_tile(vx, vy) == 3:
			set_tile(vx, vy, 9)

	# Деревья на поверхности
	var x := 6
	while x < W - 6:
		if tiles[idx(x, heights[x])] == 2 and rng.randf() < 0.35:
			var th := rng.randi_range(4, 7)
			for t in range(1, th + 1):
				set_tile(x, heights[x] - t, 4)
			x += rng.randi_range(5, 10)
		else:
			x += 2

	# Небольшое озерцо воды
	var lx := rng.randi_range(30, W - 40)
	for ox in range(0, 7):
		var yy := heights[lx + ox]
		if tiles[idx(lx + ox, yy)] == 2:
			set_tile(lx + ox, yy, 0)
			for dy in range(1, 3):
				if yy + dy < H and tiles[idx(lx + ox, yy + dy)] in [1, 3]:
					set_tile(lx + ox, yy + dy, 10)

func _ore_vein(rng: RandomNumberGenerator, ore_id: int, count: int, min_len: int, max_len: int) -> void:
	for v in count:
		var cx := rng.randi_range(4, W - 5)
		var cy := rng.randi_range(SURFACE + 6, H - 4)
		var length := rng.randi_range(min_len, max_len)
		for s in length:
			if get_tile(cx, cy) == 3:
				set_tile(cx, cy, ore_id)
			cx += rng.randi_range(-1, 1)
			cy += rng.randi_range(0, 1)

func spawn_point() -> Vector2:
	var cx := W / 2
	var cy := heights_surface_at(cx)
	return Vector2(cx * TILE + TILE / 2.0, cy * TILE - TILE)

func heights_surface_at(cx: int) -> int:
	for y in H:
		if BlockDB.is_solid(get_tile(cx, y)):
			return y
	return SURFACE

func _draw() -> void:
	var cam_pos := Vector2.ZERO
	if camera:
		cam_pos = camera.position
	# Рисуем только видимую область
	var x0 := clampi(int((cam_pos.x - 700.0) / TILE), 0, W - 1)
	var x1 := clampi(int((cam_pos.x + 700.0) / TILE), 0, W - 1)
	var y0 := clampi(int((cam_pos.y - 420.0) / TILE), 0, H - 1)
	var y1 := clampi(int((cam_pos.y + 420.0) / TILE), 0, H - 1)
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			var id := get_tile(cx, cy)
			if id == 0:
				continue
			var def := BlockDB.get_def(id)
			var st := BlockDB.get_state(id)
			var pos := Vector2(cx * TILE, cy * TILE)
			match st:
				BlockDef.State.BACKGROUND:
					draw_rect(Rect2(pos, Vector2(TILE, TILE)), Color(0.5, 0.5, 0.5, 0.25))
				BlockDef.State.LIQUID:
					draw_rect(Rect2(pos, Vector2(TILE, TILE)), Color(0.2, 0.45, 0.9, 0.6))
				_:
					draw_texture_rect(def.texture, Rect2(pos, Vector2(TILE, TILE)), false)
	# Подсветка копания и курсора
	if break_flash.x >= 0:
		var bp := Vector2(break_flash) * TILE
		draw_rect(Rect2(bp, Vector2(TILE, TILE)), Color(1, 1, 0, 0.35))
		draw_rect(Rect2(bp, Vector2(TILE, TILE)), Color(1, 1, 0, 0.8), false, 1.0)
	if camera:
		var gp := camera.get_global_mouse_position()
		var gc := Vector2i(floori(gp.x / TILE), floori(gp.y / TILE))
		var gpos := Vector2(gc) * TILE
		var dist := (gpos + Vector2(8, 8) - camera.position).length()
		var col := Color(1, 1, 1, 0.7) if dist <= 5.0 * TILE else Color(1, 0.3, 0.3, 0.5)
		draw_rect(Rect2(gpos, Vector2(TILE, TILE)), col, false, 1.0)

var camera: Camera2D
