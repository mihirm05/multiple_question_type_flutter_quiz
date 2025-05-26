import 'package:flutter/material.dart';
import 'package:multiple_question_type_flutter_quiz/config.dart' as config;
import 'question.dart';
import 'package:multiple_question_type_flutter_quiz/hexa_match.dart' as hexa_match;
import 'package:multiple_question_type_flutter_quiz/hexa_config.dart' as hexa_config;
import 'dart:math';


final Random _random = Random();


class QuizProvider extends ChangeNotifier {
  final List<Question> allQuestions;
  //final List<Question> askedQuestions = [];
  final Map<Question, int> askedCounts = {};

  int score = 0;

  bool? _lastSelectedAnswer;
  bool? get lastSelectedAnswer => _lastSelectedAnswer;

  Question? _currentQuestion;

  Question get currentQuestion => _currentQuestion!;
  //bool get isFinished => _currentQuestion == null && askedQuestions.length == allQuestions.length;
  bool get isFinished => allQuestions.every((q) => (askedCounts[q] ?? 0) >= config.repeatCount);

  QuizProvider(this.allQuestions) {
    _pickNextQuestion();
  }

  void answer(String selected) async{
  if (_currentQuestion == null) return;

  
  if (selected == _currentQuestion!.correctAnswer) {
    score++;
    _lastSelectedAnswer = true;
  }

  else{
    _lastSelectedAnswer = false;
  }

  //askedQuestions.add(_currentQuestion!);
  askedCounts[_currentQuestion!] = (askedCounts[_currentQuestion!] ?? 0) + 1;

  notifyListeners();

  await Future.delayed(Duration.zero); // lets UI update immediately
  await Future.delayed(const Duration(milliseconds: 1500)); // pause after visual update

  _pickNextQuestion();
  _lastSelectedAnswer = null; // Reset state if needed
  notifyListeners();
}

  void _pickNextQuestion() async {

    //List<Question> remaining = allQuestions.toSet().difference(askedQuestions.toSet()).toList();

    // Filter out questions asked fewer than `repeatCount` times
    List<Question> remaining = allQuestions.where((q) {
      return (askedCounts[q] ?? 0) < config.repeatCount;
    }).toList();


    if (remaining.isEmpty) {
      _currentQuestion = null;
      return;
    }

    // Adaptive logic based on performance
    Difficulty nextLevel;
    //int totalAsked = askedCounts.values.fold(0, (sum, val) => sum + val);
    int totalAsked = config.repeatCount * allQuestions.length;

    //double accuracy = askedQuestions.isEmpty ? 0 : score / askedQuestions.length;
    double accuracy = totalAsked == 0 ? 0 : score / totalAsked;


    if (accuracy >= 0.8) {
      nextLevel = Difficulty.hard;
    } else if (accuracy >= 0.5) {
      nextLevel = Difficulty.medium;
    } else {
      nextLevel = Difficulty.easy;
    }

    List<Question> filtered = remaining.where((q) => q.difficulty == nextLevel).toList();
    List<Question> pool = filtered.isNotEmpty ? filtered : remaining; 

    //_currentQuestion = (filtered.isNotEmpty ? filtered : remaining).first;
    _currentQuestion = pool[_random.nextInt(pool.length)];
    
  }

  void reset() {
    
    score = 0;
    //askedQuestions.clear();
    askedCounts.clear();
    config.questionCounter = 0;
    hexa_config.rivalMoveHistory.clear();
    hexa_config.playerMoveHistory.clear();
    _lastSelectedAnswer = null;
    _pickNextQuestion();
    notifyListeners();
  }

  int get totalQuestions => config.repeatCount * allQuestions.length;
}
