@tool
extends EditorScript

## Пункт меню: Проект -> Инструменты -> Генерация текстур блоков
## (Godot сам добавляет этот пункт, т.к. скрипт — EditorScript с @tool)
## Результат: PNG-файлы в res://assets/blocks — их можно заменить своими картинками.

func _run() -> void:
	BlockTextureGen.save_all_pngs()
	print("Генерация текстур завершена: res://assets/blocks")
