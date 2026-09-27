extends CanvasLayer

## HUD: хотбар инвентаря, название выбранного предмета, сообщения-подсказки.

@onready var info_label: Label = $InfoLabel
@onready var msg_label: Label = $MsgLabel
@onready var blocks_label: Label = $BlocksLabel

var _player: Player
var _hotbar: Control
var _slots: Array[ColorRect] = []
var _icons: Array[TextureRect] = []
var _counts: Array[Label] = []
var _msg_timer := 0.0
var _blocks_visible := true

func _ready() -> void:
	_build_hotbar()
	show_blocks_list()

## Автосвязь с игроком, если сцена ещё не передала ссылку явно
func bind_player(p: Player) -> void:
	_player = p

func _process(delta: float) -> void:
	if _player == null:
		for n in get_tree().get_nodes_in_group("player"):
			if n is Player and n.inventory != null:
				_player = n
				break
	if _msg_timer > 0.0:
		_msg_timer -= delta
		if _msg_timer <= 0.0:
			msg_label.text = ""
	if _player != null:
		_refresh_hotbar(_player.inventory)
		info_label.text = "Слот %d: %s | Мощь кирки: %d | Добыто: %d" % [
			_player.inventory.selected + 1,
			_selected_name(),
			_player.inventory.pickaxe_power(),
			_player.mined_count,
		]

func set_message(text: String) -> void:
	msg_label.text = text
	_msg_timer = 3.0

func show_blocks_list() -> void:
	var lines: Array[String] = ["Блоки (по одному шаблону BlockDef):"]
	for d in BlockDB.defs:
		if d.id == 0 or d.id == 10:
			continue
		lines.append("%s — мощь кирки: %d, состояние: %s" % [
			d.display_name, d.pickaxe_power_required, BlockDB.state_name(BlockDB.get_state(d.id))])
	blocks_label.text = "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_blocks_visible = not _blocks_visible
		blocks_label.visible = _blocks_visible

func _selected_name() -> String:
	var it := _player.inventory.selected_item()
	if it.is_empty():
		return "Пусто"
	return _player.inventory.item_name(int(it.id))

func _build_hotbar() -> void:
	_hotbar = Control.new()
	_hotbar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hotbar.position = Vector2(8, -46)
	add_child(_hotbar)
	for i in Inventory.SLOT_COUNT:
		var bg := ColorRect.new()
		bg.color = Color(0, 0, 0, 0.45)
		bg.position = Vector2(i * 42, 0)
		bg.size = Vector2(40, 40)
		_hotbar.add_child(bg)

		var border := ColorRect.new()
		border.color = Color(0.6, 0.6, 0.7, 0.6)
		border.position = Vector2(i * 42 + 1, 1)
		border.size = Vector2(38, 38)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(border)

		var icon := TextureRect.new()
		icon.position = Vector2(4, 4)
		icon.size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(icon)

		var cnt := Label.new()
		cnt.position = Vector2(26, 24)
		cnt.add_theme_font_size_override("font_size", 10)
		cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(cnt)

		_slots.append(bg)
		_icons.append(icon)
		_counts.append(cnt)

func _refresh_hotbar(inv: Inventory) -> void:
	for i in inv.SLOT_COUNT:
		var s = inv.slots[i]
		if s == null:
			_icons[i].texture = null
			_counts[i].text = ""
		else:
			var id := int(s.id)
			_icons[i].texture = _item_icon(id)
			_counts[i].text = str(s.count) if s.count > 1 else ""
		_slots[i].color = Color(1, 0.9, 0.3, 0.7) if i == inv.selected else Color(0, 0, 0, 0.45)

# Иконки инструментов рисуем процедурно (маленькие картинки)
static var _tool_icons := {}

func _item_icon(id: int) -> Texture2D:
	match id:
		Inventory.ITEM_PICKAXE:
			if not _tool_icons.has(id):
				_tool_icons[id] = _make_tool_icon(false)
			return _tool_icons[id]
		Inventory.ITEM_HAMMER:
			if not _tool_icons.has(id):
				_tool_icons[id] = _make_tool_icon(true)
			return _tool_icons[id]
		_:
			return BlockDB.get_def(id).texture

func _make_tool_icon(hammer: bool) -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var wood := Color(0.55, 0.38, 0.2)
	var metal := Color(0.75, 0.75, 0.8)
	# рукоять — диагональ снизу-слева вверх-вправо
	for i in range(4, 15):
		var y := 18 - i
		if y < 16:
			img.set_pixel(i, y, wood)
	if hammer:
		# головка молота — прямоугольник сверху
		for x in range(4, 13):
			for y in range(2, 6):
				img.set_pixel(x, y, metal)
	else:
		# наконечник кирки — изогнутая дуга
		for x in range(3, 14):
			var dy := int(absf(x - 8.0) * 0.5)
			img.set_pixel(x, 5 - dy, metal)
			img.set_pixel(x, 6 - dy, metal)
	return ImageTexture.create_from_image(img)
