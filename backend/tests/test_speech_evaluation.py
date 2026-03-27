"""Tests for speech evaluation service."""

from app.services.speech_evaluation import evaluate_speech


class TestEvaluateSpeech:
    """Test evaluate_speech function."""

    def test_exact_match(self):
        result = evaluate_speech("apple", "apple")
        assert result["similarity_score"] == 1.0
        assert result["is_accepted"] is True
        assert result["feedback"] == "perfect"

    def test_case_insensitive_match(self):
        result = evaluate_speech("Apple", "apple")
        assert result["similarity_score"] == 1.0
        assert result["is_accepted"] is True
        assert result["feedback"] == "perfect"

    def test_case_insensitive_reverse(self):
        result = evaluate_speech("apple", "APPLE")
        assert result["similarity_score"] == 1.0
        assert result["feedback"] == "perfect"

    def test_whitespace_trimmed(self):
        result = evaluate_speech("  apple  ", " apple ")
        assert result["similarity_score"] == 1.0
        assert result["feedback"] == "perfect"

    def test_empty_spoken(self):
        result = evaluate_speech("apple", "")
        assert result["similarity_score"] == 0.0
        assert result["is_accepted"] is False
        assert result["feedback"] == "no_response"

    def test_empty_target(self):
        result = evaluate_speech("", "apple")
        assert result["similarity_score"] == 0.0
        assert result["is_accepted"] is False
        assert result["feedback"] == "no_response"

    def test_both_empty(self):
        result = evaluate_speech("", "")
        assert result["similarity_score"] == 0.0
        assert result["feedback"] == "no_response"

    def test_none_spoken(self):
        result = evaluate_speech("apple", None)
        assert result["similarity_score"] == 0.0
        assert result["feedback"] == "no_response"

    def test_none_target(self):
        result = evaluate_speech(None, "apple")
        assert result["similarity_score"] == 0.0
        assert result["feedback"] == "no_response"

    def test_close_similarity_excellent(self):
        # "aple" vs "apple" should be very similar
        result = evaluate_speech("apple", "aple")
        assert result["similarity_score"] >= 0.8
        assert result["is_accepted"] is True
        assert result["feedback"] in ("excellent", "good_try")

    def test_moderate_similarity_good_try(self):
        result = evaluate_speech("apple", "apl")
        assert result["is_accepted"] is True or result["similarity_score"] >= 0.6

    def test_low_similarity_rejected(self):
        result = evaluate_speech("apple", "xyz")
        assert result["similarity_score"] < 0.6
        assert result["is_accepted"] is False
        assert result["feedback"] in ("keep_trying", "try_again")

    def test_completely_different(self):
        result = evaluate_speech("apple", "elephant")
        assert result["is_accepted"] is False
        assert result["feedback"] in ("keep_trying", "try_again")

    def test_custom_threshold(self):
        # With higher threshold, borderline cases should fail
        result = evaluate_speech("apple", "aple", accept_threshold=0.95)
        assert result["is_accepted"] is False

    def test_custom_low_threshold(self):
        # With lower threshold, more cases should pass
        result = evaluate_speech("apple", "apl", accept_threshold=0.3)
        assert result["is_accepted"] is True

    def test_result_keys(self):
        result = evaluate_speech("apple", "apple")
        assert "similarity_score" in result
        assert "is_accepted" in result
        assert "feedback" in result

    def test_score_bounded_zero_one(self):
        result = evaluate_speech("apple", "aple")
        assert 0.0 <= result["similarity_score"] <= 1.0

    def test_feedback_tiers_excellent(self):
        # Find a pair that gives ~0.9+ similarity
        result = evaluate_speech("elephant", "elephan")
        if result["similarity_score"] >= 0.9:
            assert result["feedback"] == "excellent"
