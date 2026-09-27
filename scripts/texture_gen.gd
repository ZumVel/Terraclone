class_name TextureGen
## Процедурная генерация текстур блоков (однотонных и разноцветных).
## Выполняется один раз при старте — дальше блоки ссылаются на свои ImageTexture.

const TS := 16 # размер текстуры в пикселях

static func _img(base: Color, mult: float) -> Image:
	var img := Image.create(TS, TS, false, Image.FORMAT_RGBA8)
	img.fill(Color(base.r * mult, base.g * mult, base.b * mult, 1.0))
	return img

# Шум из пиксельных крапинок другого цвета (разноцветные блоки)
static func speckled(base: Color, spec: Color, density: float, seed: int) -> Texture2D:
	var img := _img(base, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for y in TS:
		for x in TS:
			if rng.randf() < density:
				var v := rng.randf_range(0.75, 1.25)
				img.set_pixel(x, y, Color(spec.r * v, spec.g * v, spec.b * v, 1.0))
	return ImageTexture.create_from_image(img)

# Горизонтальные полосы (дерево)
static func striped(base: Color, line: Color, period: int, seed: int) -> Texture2D:
	var img := _img(base, 1.0)
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

# Камень: база + светлые вкрапления + минеральные точки
static func rocky(base: Color, ore: Color, seed: int) -> Texture2D:
	var img := _img(base, 1.0)
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

# Простая однотонная текстура с лёгким затемнением по краям
static func solid(c: Color) -> Texture2D:
	var img := _img(c, 1.0)
	for y in TS:
		for x in TS:
			if x == 0 or y == 0 or x == TS - 1 or y == TS - 1:
				img.set_pixel(x, y, c.darkened(0.15))
	return ImageTexture.create_from_image(img)
