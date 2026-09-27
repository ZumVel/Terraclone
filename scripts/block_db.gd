extends Node

## Автозагрузка (синглтон). Хранит все определения блоков, созданные по одному шаблону BlockDef.

const TILE := 16 # размер тайла в пикселях

var defs: Array[BlockDef] = []      # индекс == id блока
var _state_overrides := {}           # id -> состояние, изменённое молотом

func _ready() -> void:
	_build_defs()

func _make(id: int, name: String, tex: Texture2D, power: int, st: BlockDef.State, hammerable := true) -> BlockDef:
	var d := BlockDef.new()
	d.id = id
	d.display_name = name
	d.texture = tex
	d.pickaxe_power_required = power
	d.state = st
	d.hammer_can_change = hammerable
	return d

func _build_defs() -> void:
	defs.clear()
	# 0 — воздух (невидимый, не ломается киркой как блок-цель)
	defs.append(_make(0, "Воздух", TextureGen.solid(Color(0, 0, 0, 0)), -1, BlockDef.State.BACKGROUND, false))
	# 1 — грязь (однотонная)
	defs.append(_make(1, "Грязь", TextureGen.solid(Color(0.45, 0.30, 0.18)), 1, BlockDef.State.SOLID))
	# 2 — дёрн (разноцветный: коричневая база + зелёные крапинки)
	defs.append(_make(2, "Дёрн", TextureGen.speckled(Color(0.45, 0.30, 0.18), Color(0.30, 0.70, 0.25), 0.35, 12), 1, BlockDef.State.SOLID))
	# 3 — камень (разноцветный: серый с вкраплениями)
	defs.append(_make(3, "Камень", TextureGen.rocky(Color(0.50, 0.50, 0.55), Color(0.75, 0.75, 0.80), 34), 2, BlockDef.State.SOLID))
	# 4 — дерево (разноцветное: полосы)
	defs.append(_make(4, "Дерево", TextureGen.striped(Color(0.55, 0.38, 0.20), Color(0.38, 0.25, 0.12), 4, 56), 1, BlockDef.State.SOLID))
	# 5 — песок (однотонный)
	defs.append(_make(5, "Песок", TextureGen.solid(Color(0.85, 0.78, 0.55)), 1, BlockDef.State.SOLID))
	# 6 — глина (однотонная)
	defs.append(_make(6, "Глина", TextureGen.solid(Color(0.62, 0.42, 0.38)), 1, BlockDef.State.SOLID))
	# 7 — уголь (разноцветный: камень + чёрные точки)
	defs.append(_make(7, "Угольная руда", TextureGen.rocky(Color(0.50, 0.50, 0.55), Color(0.12, 0.12, 0.12), 78), 3, BlockDef.State.SOLID))
	# 8 — золото (разноцветный: камень + жёлтые точки)
	defs.append(_make(8, "Золотая руда", TextureGen.rocky(Color(0.50, 0.50, 0.55), Color(0.95, 0.80, 0.20), 90), 5, BlockDef.State.SOLID))
	# 9 — адский камень (однотонный, нужен молот/сильная кирка)
	defs.append(_make(9, "Адский камень", TextureGen.solid(Color(0.55, 0.15, 0.10)), 7, BlockDef.State.SOLID))
	# 10 — вода (жидкость, однотонная полупрозрачная)
	var water_def := _make(10, "Вода", TextureGen.solid(Color(0.20, 0.45, 0.90)), -1, BlockDef.State.LIQUID, false)
	water_def.default_item = false
	defs.append(water_def)

func get_def(id: int) -> BlockDef:
	if id < 0 or id >= defs.size():
		return defs[0]
	return defs[id]

## Текущее состояние блока с учётом изменений молотом
func get_state(id: int) -> BlockDef.State:
	var d := get_def(id)
	if _state_overrides.has(id):
		return _state_overrides[id]
	return d.state

## Молот меняет состояние блока (SOLID <-> BACKGROUND, как в Terraria)
func hammer_state(id: int) -> bool:
	var d := get_def(id)
	if not d.hammer_can_change:
		return false
	var cur := get_state(id)
	match cur:
		BlockDef.State.SOLID:
			_state_overrides[id] = BlockDef.State.BACKGROUND
		BlockDef.State.BACKGROUND:
			_state_overrides[id] = BlockDef.State.SOLID
		_:
			return false
	print("Молот: «%s» -> состояние %s" % [d.display_name, state_name(get_state(id))])
	return true

func state_name(st: BlockDef.State) -> String:
	match st:
		BlockDef.State.SOLID: return "Твёрдое"
		BlockDef.State.LIQUID: return "Жидкое"
		BlockDef.State.BACKGROUND: return "Фоновое"
	return "?"

func is_solid(id: int) -> bool:
	return get_state(id) == BlockDef.State.SOLID
