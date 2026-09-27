class_name BlockDef
extends Resource

## Единый шаблон (класс) описания блока.
## Все 10 видов блоков создаются как экземпляры этого ресурса со своими характеристиками.

enum State { SOLID, LIQUID, BACKGROUND } # твёрдый / жидкий / фоновый (как в Terraria)

@export var id: int = 0                       ## уникальный числовой идентификатор
@export var display_name: String = ""         ## имя блока
@export var texture: Texture2D                ## текстура блока
@export var pickaxe_power_required: int = 0   ## необходимая мощь кирки, чтобы сломать
@export var state: State = State.SOLID        ## текущее состояние (можно менять молотом)
@export var hammer_can_change: bool = true    ## позволяет ли молот менять состояние
@export var default_item: bool = true         ## падает ли как предмет при поломке
