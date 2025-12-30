extends Control

func _ready():
	# GameManager'dan veriyi çek
	var d = GameManager.last_run_data
	
	# Veri gelmiş mi kontrol et (Hata almamak için)
	if d.is_empty():
		print("HATA: GameManager'dan veri gelmedi!")
		return

	# Düğümler sahnede var mı diye kontrol ederek metinleri bas
	if has_node("RankLabel"):
		$RankLabel.text = str(d.rank)
		# Renge göre süsleyelim
		if d.rank == "SS" or d.rank == "S": $RankLabel.modulate = Color("ffff00")
		elif d.rank == "A": $RankLabel.modulate = Color("00ff00")

	if has_node("ScoreLabel"):
		$ScoreLabel.text = "TOPLAM SKOR: " + str(d.score)

	if has_node("AccLabel"):
		# snapped ile küsuratı temizleyelim (98.55 gibi)
		$AccLabel.text = "DOĞRULUK: %" + str(snapped(d.accuracy, 0.01))

	if has_node("DetailsLabel"):
		$DetailsLabel.text = "PERFECT: %d\nGREAT: %d\nGOOD: %d\nMISS: %d" % [d.perfects, d.greats, d.goods, d.misses]

# Buton Fonksiyonları (Sinyalleri bağlamayı unutma!)
func _on_retry_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/freeplay.tscn")
