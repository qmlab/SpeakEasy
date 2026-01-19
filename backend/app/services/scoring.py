from Levenshtein import ratio


class ScoringService:
    @staticmethod
    def score_pronunciation(target_word: str, spoken_text: str) -> tuple[int, bool, str]:
        target_lower = target_word.lower().strip()
        spoken_lower = spoken_text.lower().strip()
        
        if target_lower == spoken_lower:
            return 100, True, "Perfect! You said it correctly!"
        
        similarity = ratio(target_lower, spoken_lower)
        score = int(similarity * 100)
        
        is_correct = score >= 80
        
        if score >= 90:
            feedback = "Excellent! Very close to perfect!"
        elif score >= 80:
            feedback = "Great job! That's correct!"
        elif score >= 60:
            feedback = f"Good try! The word is '{target_word}'. Try again!"
        elif score >= 40:
            feedback = f"Keep practicing! The word is '{target_word}'."
        else:
            feedback = f"Let's try again! The word is '{target_word}'."
        
        return score, is_correct, feedback

    @staticmethod
    def check_tap_location(
        tap_x: float, tap_y: float,
        box_x: float, box_y: float,
        box_width: float, box_height: float,
        tolerance: float = 0.05
    ) -> tuple[bool, int]:
        expanded_x = max(0, box_x - tolerance)
        expanded_y = max(0, box_y - tolerance)
        expanded_width = min(1 - expanded_x, box_width + 2 * tolerance)
        expanded_height = min(1 - expanded_y, box_height + 2 * tolerance)
        
        is_inside = (
            expanded_x <= tap_x <= expanded_x + expanded_width and
            expanded_y <= tap_y <= expanded_y + expanded_height
        )
        
        if is_inside:
            center_x = box_x + box_width / 2
            center_y = box_y + box_height / 2
            distance = ((tap_x - center_x) ** 2 + (tap_y - center_y) ** 2) ** 0.5
            max_distance = ((box_width / 2) ** 2 + (box_height / 2) ** 2) ** 0.5
            
            if max_distance > 0:
                accuracy = max(0, 1 - (distance / max_distance))
                score = int(70 + accuracy * 30)
            else:
                score = 100
            
            return True, score
        
        return False, 0
