extends Node2D

## ШАБЛОН (префаб) блока — единая сцена для всех видов блоков.
## Не создавайте отдельные сцены для каждого блока: дублируйте эту сцену
## и меняйте ТОЛЬКО параметр "def" в инспекторе (а сам ресурс .tres редактируется
## по одному шаблону BlockDef: текстура, мощь кирки, имя, состояние...).
## Используется как: 1) визуальный эталон в редакторе, 2) инстанс для спавна блоков
## из кода: var b := preload("res://scenes/block_template.tscn").instantiate().

@export var def: BlockDef:            ## определение блока (те же данные, что в реестре BlockDB)
	set(value):
		def = value
		_refresh()

@onready var sprite: Sprite2D = $Sprite2D         ## визуальный компонент (текстура)
@onready var collider: CollisionShape2D = $Collider  ## физический компонент (твёрдость)


func _ready() -> void:
	_refresh()


## Компонентный паттерн: каждый дочерний узел настраивается из def независимо
func _refresh() -> void:
	if not is_node_ready():
		return # ждём @onready-узлы (экспортер мог задать def до _ready)
	if def == null:
		return
	sprite.texture = def.texture
	var solid_now := def.state == BlockDef.State.SOLID
	collider.disabled = not solid_now
	if collider.shape == null:
		var sh := RectangleShape2D.new()
		sh.size = Vector2(BlockDB.TILE, BlockDB.TILE)
		collider.shape = sh


## Спавн блока этим шаблоном из кода (пример использования префаба)
static func spawn_at(scene: PackedScene, parent: Node, cell: Vector2i, block_def: BlockDef) -> Node2D:
	var inst := scene.instantiate() as Node2D
	inst.def = block_def
	inst.position = Vector2(cell) * BlockDB.TILE + Vector2(BlockDB.TILE, BlockDB.TILE) / 2.0
	parent.add_child(inst)
	return inst
