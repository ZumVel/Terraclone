class_name Inventory
extends RefCounted

## Простой слотовый инвентарь: предметы = id блоков + инструменты (кирка/молот).

const SLOT_COUNT := 10
const MAX_STACK := 99

# Псевдо-id инструментов (не блоки)
const ITEM_PICKAXE := -2
const ITEM_HAMMER := -3

var slots: Array = [] # [{ "id": int, "count": int }]
var selected := 0

func _init() -> void:
	slots.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		slots[i] = null
	# Стартовый набор, как в новой игре Terraria
	add_item(ITEM_PICKAXE, 1)
	add_item(ITEM_HAMMER, 1)
	add_item(1, 50)  # грязь
	add_item(3, 50)  # камень
	add_item(4, 20)  # дерево

func add_item(id: int, count: int = 1) -> int:
	# Сначала докидываем в существующие стопки
	for s in slots:
		if s != null and s.id == id and s.count < MAX_STACK:
			var move := mini(count, MAX_STACK - s.count)
			s.count += move
			count -= move
			if count == 0:
				return 0
	# Потом в пустые слоты
	for i in slots.size():
		if slots[i] == null and count > 0:
			var put := mini(count, MAX_STACK)
			slots[i] = { "id": id, "count": put }
			count -= put
	return count # остаток (0 — всё влезло)

func take_selected(count: int = 1) -> bool:
	if slots[selected] == null or slots[selected].count < count:
		return false
	slots[selected].count -= count
	if slots[selected].count <= 0:
		slots[selected] = null
	return true

func selected_item() -> Dictionary:
	if slots[selected] == null:
		return {}
	return slots[selected].duplicate()

func item_name(id: int) -> String:
	match id:
		ITEM_PICKAXE: return "Кирка"
		ITEM_HAMMER: return "Молот"
		_: return BlockDB.get_def(id).display_name

## Мощь кирки в руках (условная шкала: деревянная 3, каменная 5, адская 10)
func pickaxe_power() -> int:
	return 10 if has_tool_of_level(2) else (5 if has_tool_of_level(1) else 3)

func has_tool_of_level(level: int) -> bool:
	# Уровень растёт со временем: считаем по числу добытых блоков (задаёт игрок)
	return _tool_level >= level

var _tool_level := 0
func upgrade_tools(level: int) -> void:
	_tool_level = maxi(_tool_level, level)
