import 'package:flutter/material.dart';
import 'question.dart';

class QuizProvider extends ChangeNotifier {
  final List<Question> allQuestions;
  final List<Question> askedQuestions = [];
  int score = 0;

  Question? _currentQuestion;

  Question get currentQuestion => _currentQuestion!;
  bool get isFinished => _currentQuestion == null && askedQuestions.length == allQuestions.length;

  QuizProvider(this.allQuestions) {
    _pickNextQuestion();
  }

  void answer(String selected) {
    if (_currentQuestion == null) return;

    if (selected == _currentQuestion!.correctAnswer) {
      score++;
    }

    askedQuestions.add(_currentQuestion!);
    _pickNextQuestion();
    notifyListeners();
  }

  void _pickNextQuestion() {
    List<Question> remaining = allQuestions.toSet().difference(askedQuestions.toSet()).toList();

    if (remaining.isEmpty) {
      _currentQuestion = null;
      return;
    }

    // Adaptive logic based on performance
    Difficulty nextLevel;
    double accuracy = askedQuestions.isEmpty ? 0 : score / askedQuestions.length;

    if (accuracy >= 0.8) {
      nextLevel = Difficulty.hard;
    } else if (accuracy >= 0.5) {
      nextLevel = Difficulty.medium;
    } else {
      nextLevel = Difficulty.easy;
    }

    List<Question> filtered = remaining.where((q) => q.difficulty == nextLevel).toList();
    _currentQuestion = (filtered.isNotEmpty ? filtered : remaining).first;
  }

  void reset() {
    score = 0;
    askedQuestions.clear();
    _pickNextQuestion();
    notifyListeners();
  }

  int get totalQuestions => allQuestions.length;
}
