extends Resource
class_name SongData

@export_group("Genel Bilgiler")
@export var song_name: String = "Yeni Rock Parçası"
@export var artist: String = "Grup Adı"

@export_group("Dosyalar")
@export var audio_file: AudioStream
@export var chart_file: String = "res://charts/song.json"
@export var stage_scene: PackedScene # Modellediğin 3D sahne buraya!

@export_group("Oyun Ayarları")
@export var bpm: float = 120.0
@export var scroll_speed: float = 800.0 # Rock için 800 idealdir

@export_group("Renkler")
@export var theme_color: Color = Color("ffff00") # PERFECT/Arayüz rengi
