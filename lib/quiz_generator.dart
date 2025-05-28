import 'package:multiple_question_type_flutter_quiz/question.dart';
import 'dart:convert';
import 'package:flutter/services.dart';


Future<Map<int, String>> loadIndexToUuidMap() async {
  final String jsonString = await rootBundle.loadString('questions_mapping.json');
  final Map<String, dynamic> jsonMap = json.decode(jsonString);

  // Convert keys to int
  return jsonMap.map((key, value) => MapEntry(int.parse(key), value as String));
}

Future<List<Question>> generateComprehensionQuestions(Map<int, String> indexToUuid) async {
  List<Question> questions = [];

  for (int i = 1; i <= 8; i++) {
    int contrast;
    if (i <= 5) {
      List<int> candidates = List.generate(5, (j) => i + j + 1).where((x) => x <= 10).toList();
      contrast = (candidates..shuffle()).first;
    } else {
      List<int> candidates = List.generate(5, (j) => i - j - 1).where((x) => x >= 1).toList();
      contrast = (candidates..shuffle()).first;
    }

    String mainId = indexToUuid[i]!;
    String contrastId = indexToUuid[contrast]!;

    String audioPath = 'audioObjects/$mainId.mp3';
    String correctImage = 'objects/$mainId.png';
    String contrastImage = 'objects/$contrastId.png';

    List<String> opts = [correctImage, contrastImage]..shuffle();

    questions.add(
      Question(
        audioPrompt: audioPath,
        correctAnswer: correctImage,
        options: opts,
        type: parseQuestionType("comprehension"),
        difficulty: parseDifficulty("easy")
      ),
    );
  }

  return questions;
}
