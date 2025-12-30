extends Node

# Seçilen şarkıyı tutan değişken
var current_song = null

# Şarkı Listesi
var songs = [
	{
		"title": "Metal Storm",
		"artist": "The Coder",
		"chart_file": "res://chart.json",
		"audio_file": preload("res://music/rockstar.mp3"),
		"stage_scene": preload("res://ConcertHall.tscn"),
		"scroll_speed": 850.0
	},
	{
		"title": "Yeah",
		"artist": "The Coder",
		"chart_file": "res://new.json",
		"audio_file": preload("res://music/yeah.mp3"),
		"stage_scene": preload("res://ConcertHall.tscn"),
		"scroll_speed": 1000.0
	}
]

# Şarkı seçmek için bu fonksiyonu kullan kanka, karışıklığı bu önler
func select_song(index: int):
	if index >= 0 and index < songs.size():
		# .duplicate(true) yaparak verinin kopyasını alıyoruz. 
		# Böylece bir şarkıyı oynarken verisi değişirse orijinali bozulmaz.
		current_song = songs[index].duplicate(true)
		print("Şarkı Seçildi: ", current_song.title)
	else:
		print("Hata: Geçersiz şarkı indeksi!")

# Oyunu resetlemek gerekirse
func reset_game_state():
	current_song = null
