extends Node

## Автозагрузка (синглтон-реестр). Реестр определений блоков.
## ШАБЛОН блока: scenes/block_template.tscn + ресурс BlockDef (resources/blocks/*.tres) + PNG (assets/blocks/).
## Чтобы добавить блок: 1) скопируйте любой .tres из resources/blocks, поменяйте id/имя/мощь/текстуру,
## 2) добавьте путь в BLOCK_RES_PATHS — всё остальное (мир, инвентарь, UI) подхватится само.

const TILE := 16 # размер тайла в пикселях

## Пути к ресурсам-определениям. Индекс массива == id блока!
const BLOCK_RES_PATHS: Array[String] = [
	"res://resources/blocks/air.tres",        # 0
	"res://resources/blocks/dirt.tres",       # 1
	"res://resources/blocks/grass.tres",      # 2
	"res://resources/blocks/stone.tres",      # 3
	"res://resources/blocks/wood.tres",       # 4
	"res://resources/blocks/sand.tres",       # 5
	"res://resources/blocks/clay.tres",       # 6
	"res://resources/blocks/coal_ore.tres",   # 7
	"res://resources/blocks/gold_ore.tres",   # 8
	"res://resources/blocks/hellstone.tres",  # 9
	"res://resources/blocks/water.tres",      # 10
]

var defs: Array[BlockDef] = []   # индекс == id блока
var _state_overrides := {}       # id -> состояние, изменённое молотом


func _ready() -> void:
	_load_defs()


## Загрузка всех определений из ресурсов; при ошибке — понятный лог (лёгкая отладка компонентов)
func _load_defs() -> void:
	defs.clear()
	for path in BLOCK_RES_PATHS:
		var res := load(path)
		if res == null or not (res is BlockDef):
			push_error("BlockDB: не удалось загрузить определение блока: %s" % path)
			continue
		var d := res as BlockDef
		if d.texture == null:
			push_warning("BlockDB: у блока «%s» (id=%d) нет текстуры — положите PNG в assets/blocks" % [d.display_name, d.id])
		defs.append(d)
	print("BlockDB: загружено определений блоков: %d" % defs.size())


func get_def(id: int) -> BlockDef:
	if id < 0 or id >= defs.size():
		if not defs.is_empty():
			return defs[0]
		return BlockDef.new()
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
