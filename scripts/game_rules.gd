extends RefCounted
class_name GameRules

static func clean_text(value: String) -> String:
	return " ".join(value.replace("\n", " ").split(" ", false)).strip_edges()

static func levenshtein(a: String, b: String) -> int:
	var previous: Array = []
	for i in range(b.length() + 1):
		previous.append(i)
	for i in range(1, a.length() + 1):
		var current: Array = [i]
		for j in range(1, b.length() + 1):
			var cost := 0 if a.substr(i - 1, 1) == b.substr(j - 1, 1) else 1
			current.append(mini(mini(int(current[j - 1]) + 1, int(previous[j]) + 1), int(previous[j - 1]) + cost))
			previous = current
	return int(previous[b.length()])

static func confidence_correct_points(base_points: int, confidence: int) -> int:
	# Jeder Prozentpunkt verändert die lineare Gewinnkurve.
	var normalized := clampf(float(confidence), 0.0, 100.0) / 100.0
	return maxi(0, int(round(float(base_points) * (0.5 + normalized))))

static func confidence_wrong_penalty(base_points: int, confidence: int) -> int:
	# Bis einschließlich 50 % ist eine falsche Wahl kostenlos; danach steigt
	# der Abzug linear bis zur vollen Basisstrafe bei 100 %.
	var risk := maxf(0.0, (clampf(float(confidence), 0.0, 100.0) - 50.0) / 50.0)
	return maxi(0, int(round(float(base_points) * risk)))

static func estimate_confidence_factor(confidence: int) -> float:
	# Schätzfragen reagieren bewusst abgeschwächt: 50 % bleibt neutral.
	return 0.75 + 0.5 * clampf(float(confidence), 0.0, 100.0) / 100.0

static func estimate_confidence_penalty(base_points: int, confidence: int, distance_ratio: float) -> int:
	var risk := maxf(0.0, (clampf(float(confidence), 0.0, 100.0) - 50.0) / 50.0)
	var distance := clampf(distance_ratio, 0.0, 1.0)
	return maxi(0, int(round(float(base_points) * 0.6 * risk * distance)))
