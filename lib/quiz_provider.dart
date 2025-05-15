import 'package:flutter/material.dart';
import 'question.dart';

class QuizProvider with ChangeNotifier {
  final List<Question> _questions;
  int _currentIndex = 0;
  int _score = 0;

  QuizProvider(this._questions);

  Question get currentQuestion => _questions[_currentIndex];
  int get score => _score;
  int get totalQuestions => _questions.length;
  bool get isFinished => _currentIndex >= _questions.length;

  void answer(String selectedAnswer) {
    if (selectedAnswer == currentQuestion.correctAnswer) {
      _score++;
    }
    _currentIndex++;
    notifyListeners();
  }

  void reset() {
    _currentIndex = 0;
    _score = 0;
    notifyListeners();
  }
}
