class_name PlayerSprites
## Генерация спрайтов игрока (кадры idle/run/jump) из Image — без внешних файлов.

const W := 12
const H := 26

static func build_frames() -> Dictionary:
	# Возвращает { "idle": [Image...], "run": [...], "jump": [...] }
	return {
		"idle": [_body(0.0, false)],
		"run": [_body(0.0, true), _body(1.0, false), _body(0.0, false), _body(-1.0, false)],
		"jump": [_body(0.0, true)],
	}

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, c)

# Рисуем человечка 12x26 пикселей; phase — фаза шага, legs_spread — ноги врозь
static func _body(phase: float, legs_spread: bool) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var skin := Color(0.95, 0.78, 0.6)
	var shirt := Color(0.2, 0.5, 0.85)
	var pants := Color(0.25, 0.25, 0.35)
	var hair := Color(0.35, 0.2, 0.1)
	var shoe := Color(0.4, 0.25, 0.15)

	# Голова
	for y in range(1, 8):
		for x in range(3, 9):
			_px(img, x, y, skin)
	for x in range(3, 9):
		_px(img, x, 1, hair)
	_px(img, 4, 4, Color(0, 0, 0)) # глаза
	_px(img, 7, 4, Color(0, 0, 0))

	# Торс
	for y in range(8, 17):
		for x in range(3, 9):
			_px(img, x, y, shirt)

	# Руки (слегка качаются при беге)
	var arm_swing := int(round(phase))
	for y in range(9, 15):
		_px(img, 2, clampi(y + arm_swing, 0, H - 1), shirt.darkened(0.15))
		_px(img, 9, clampi(y - arm_swing, 0, H - 1), shirt.darkened(0.15))

	# Ноги
	for y in range(17, 24):
		_px(img, 4, y, pants)
		_px(img, 7, y, pants)
	if legs_spread:
		_px(img, 3, 24, shoe)
		_px(img, 8, 24, shoe)
	else:
		_px(img, 4, 24, shoe)
		_px(img, 7, 24, shoe)
	if absf(phase) > 0.5:
		_px(img, 4 + int(signf(phase)), 25, shoe.darkened(0.2))

	return img
