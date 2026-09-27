class_name BlockTextureGen
extends RefCounted

## Сервис генерации PNG-текстур блоков (однотонных и разноцветных).
## Вызывается из редактора: Меню проекта -> Инструменты -> Сгенерировать текстуры блоков.
## Текстуры — обычные .png-файлы, их можно заменить своими картинками в /assets/blocks.

const OUT_DIR := "res://assets/blocks"
const TS := 16 # размер текстуры в пикселях


static func _img(base: Color) -> Image:
	var img := Image.create(TS, TS, false, Image.FORMAT_RGBA8)
	img.fill(Color(base.r, base.g, base.b, 1.0))
	return img


## Однотонная текстура с лёгким затемнением по краям
static func solid(c: Color) -> Texture2D:
	var img := _img(c)
	for y in TS:
		for x in TS:
			if x == 0 or y == 0 or x == TS - 1 or y == TS - 1:
				img.set_pixel(x, y, c.darkened(0.15))
	return ImageTexture.create_from_image(img)


## Разноцветная: база + крапинки другого цвета
static func speckled(base: Color, spec: Color, density: float, seed: int) -> Texture2D:
	var img := _img(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for y in TS:
		for x in TS:
			if rng.randf() < density:
				var v := rng.randf_range(0.75, 1.25)
				img.set_pixel(x, y, Color(spec.r * v, spec.g * v, spec.b * v, 1.0))
	return ImageTexture.create_from_image(img)


## Разноцветная: полосы (дерево)
static func striped(base: Color, line: Color, period: int, seed: int) -> Texture2D:
	var img := _img(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for y in TS:
		if y % period == 0 or y % period == period / 2:
			for x in TS:
				if rng.randf() < 0.85:
					img.set_pixel(x, y, line)
		elif rng.randf() < 0.2:
			for x in TS:
				if rng.randf() < 0.3:
					img.set_pixel(x, y, Color(line.r, line.g, line.b, 0.5))
	return ImageTexture.create_from_image(img)


## Разноцветная: камень + минеральные вкрапления (руда)
static func rocky(base: Color, ore: Color, seed: int) -> Texture2D:
	var img := _img(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in 26:
		img.set_pixel(rng.randi_range(0, TS - 1), rng.randi_range(0, TS - 1),
				base.lerp(Color.WHITE, rng.randf() * 0.25))
	for i in 6:
		var x := rng.randi_range(1, TS - 2)
		var y := rng.randi_range(1, TS - 2)
		img.set_pixel(x, y, ore.lightened(0.2))
		img.set_pixel(x + 1, y, ore)
		img.set_pixel(x, y + 1, ore.darkened(0.15))
	return ImageTexture.create_from_image(img)


## Сохранить все PNG-текстуры в assets/blocks (идемпотентно — перетирает свои же файлы)
static func save_all_pngs() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var entries := {
		"dirt.png": solid(Color(0.45, 0.30, 0.18)),
		"grass.png": speckled(Color(0.45, 0.30, 0.18), Color(0.30, 0.70, 0.25), 0.35, 12),
		"stone.png": rocky(Color(0.50, 0.50, 0.55), Color(0.75, 0.75, 0.80), 34),
		"wood.png": striped(Color(0.55, 0.38, 0.20), Color(0.38, 0.25, 0.12), 4, 56),
		"sand.png": solid(Color(0.85, 0.78, 0.55)),
		"clay.png": solid(Color(0.62, 0.42, 0.38)),
		"coal_ore.png": rocky(Color(0.50, 0.50, 0.55), Color(0.12, 0.12, 0.12), 78),
		"gold_ore.png": rocky(Color(0.50, 0.50, 0.55), Color(0.95, 0.80, 0.20), 90),
		"hellstone.png": solid(Color(0.55, 0.15, 0.10)),
		"water.png": solid(Color(0.20, 0.45, 0.90)),
	}
	for fname: String in entries:
		var tex: ImageTexture = entries[fname] as ImageTexture
		var err := tex.get_image().save_png(OUT_DIR.path_join(fname))
		print("Текстура %s: %s" % [fname, "OK" if err == OK else "ОШИБКА %s" % err])
