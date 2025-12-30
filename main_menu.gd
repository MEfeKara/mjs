extends Control

# Sahne yollarını buraya ekle (Dosya isimlerinle aynı olmalı)
const STORY_MODE_PATH = "res://scenes/story_mode.tscn"
const FREEPLAY_PATH = "res://scenes/freeplay.tscn"
const OPTIONS_PATH = "res://scenes/options_menu.tscn"
const CREDITS_PATH = "res://scenes/credits.tscn"
const GAME_SCENE_PATH = "res://scenes/main_game.tscn"

func _ready():
	# Butonları bağlıyoruz
	$MenuButtons/Story.pressed.connect(_on_story_pressed)
	$MenuButtons/Freeplay.pressed.connect(_on_freeplay_pressed)
	$MenuButtons/Options.pressed.connect(_on_options_pressed)
	$MenuButtons/Credits.pressed.connect(_on_credits_pressed)
	$MenuButtons/Exit.pressed.connect(_on_exit_pressed)
	
	# Mouse imlecini serbest bırak
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_story_pressed():
	# Şimdilik direkt oyuna atabilir veya hikaye seçimine gidebilirsin
	get_tree().change_scene_to_file(STORY_MODE_PATH)

func _on_freeplay_pressed():
	get_tree().change_scene_to_file(FREEPLAY_PATH)

func _on_options_pressed():
	# Ayarlar menüsünü sahne değiştirmek yerine bir "Popup" olarak da açabilirsin
	get_tree().change_scene_to_file(OPTIONS_PATH)

func _on_credits_pressed():
	get_tree().change_scene_to_file(CREDITS_PATH)

func _on_exit_pressed():
	get_tree().quit()

func _on_button_mouse_entered(button: Button):
	var tw = create_tween()
	# Hafif sağa kaysın ve büyüsün
	tw.parallel().tween_property(button, "position:x", 20.0, 0.1)
	tw.parallel().tween_property(button, "scale", Vector2(1.1, 1.1), 0.1)
	# Butonun parlaması için modulate kullan (Raw Color)
	button.modulate = Color(2, 2, 2) 

func _on_button_mouse_exited(button: Button):
	var tw = create_tween()
	tw.parallel().tween_property(button, "position:x", 0.0, 0.1)
	tw.parallel().tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	button.modulate = Color(1, 1, 1)
