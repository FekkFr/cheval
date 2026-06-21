# Résout une course et retourne le classement
class_name RaceResolver
extends RefCounted

func resolve(horses: Array) -> Array:
	for horse in horses:
		horse.final_score = horse.calculate_score()

	var sorted = horses.duplicate()
	sorted.sort_custom(func(a, b):
		# Si scores égaux → départage aléatoire
		if a.final_score == b.final_score:
			return randi() % 2 == 0
		return a.final_score > b.final_score
	)

	print("=== RÉSULTAT DE COURSE ===")
	for i in sorted.size():
		print(i+1, ". ", sorted[i].horse_name, " (score: ", sorted[i].final_score, ")")

	return sorted
# Générer 4 chevaux aléatoires pour une course
static func generate_field() -> Array:
	var names = [
		"Midnight Prince", "Black Friday", "Iron Duke", "Lucky Streak",
		"Dark Omen", "Silver Ghost", "Last Chance", "Dead Heat"
	]
	names.shuffle()
	var field = []
	for i in 4:
		field.append(Horse.generate_random(names[i]))
	return field
