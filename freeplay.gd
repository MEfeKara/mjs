extends Control

@onready var song_list_container = $ScrollContainer/SongList
@onready var song_name_label = $SongDetails/SongName
@onready var play_button = $PlayButton

var selected_song_data = null

func _ready():
	# Şarkıları listeye ekle
	setup_song_list()
	
	# Geri butonu
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://MainMenu.tscn"))
	
	# Oyna butonu (başlangıçta kapalı)
	play_button.disabled = true
	play_button.pressed.connect(_on_play_pressed)

func setup_song_list():
	# GameManager.songs içindeki her şarkı için bir buton oluşturuyoruz
	for song in GameManager.songs:
		var btn = Button.new()
		btn.text = song.title + " - " + song.artist
		btn.custom_minimum_size.y = 50
		
		# Butona tıklandığında detayları göster
		btn.pressed.connect(_on_song_selected.bind(song))
		
		song_list_container.add_child(btn)

func _on_song_selected(song_data):
	selected_song_data = song_data
	song_name_label.text = song_data.title
	play_button.disabled = false
	
	# Eğer şarkı önizlemesi eklemek istersen burada çalabilirsin
	# AudioPlayer.stream = song_data.preview_audio
	# AudioPlayer.play()

func _on_play_pressed():
	if selected_song_data:
		GameManager.current_song = selected_song_data
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")
