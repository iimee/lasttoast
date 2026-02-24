# res://db/ItemDB.gd
extends Resource
class_name ItemDB
# Простой реестр ID предметов. Имя файла и class_name — не обязаны совпадать.

# --- Базовые ID (ИСПОЛЬЗУЮТСЯ В КОДЕ) ---
const FULL_BOTTLE  := "full_bottle"   # полная бутылка (расходник: выпиваешь -> даёт опьянение + даёт EMPTY_BOTTLE)
const EMPTY_BOTTLE := "empty_bottle"  # пустая бутылка (валюта + боеприпас для броска/молотова)
const CIG_PACK     := "cig_pack"      # пачка сигарет (расходник: использовал -> даёт накуренность)

# --- (Опционально) человекочитаемые имена для UI ---
const DISPLAY_NAME := {
	FULL_BOTTLE:  "Full Bottle",
	EMPTY_BOTTLE: "Empty Bottle",
	CIG_PACK:     "Cigarette Pack",
}

# --- (Опционально) тип предмета для логики/фильтров ---
# "consumable" — расходники; "currency" — валюта/боеприпасы
const ITEM_TYPE := {
	FULL_BOTTLE:  "consumable",
	EMPTY_BOTTLE: "currency",
	CIG_PACK:     "consumable",
}

# --- Утилиты (не обязательно использовать, но удобно) ---
static func is_known(id: String) -> bool:
	return id in DISPLAY_NAME

static func get_display_name(id: String) -> String:
	return DISPLAY_NAME.get(id, id)

static func get_type(id: String) -> String:
	return ITEM_TYPE.get(id, "")
