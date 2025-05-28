enum QuestionType { comprehension, repetitionOrNaming }
enum Difficulty { easy, medium, hard }

QuestionType parseQuestionType(String value) {
  switch (value.toLowerCase()) {
    case 'comprehension':
      return QuestionType.comprehension;
    case 'repetitionOrNaming':
    return QuestionType.repetitionOrNaming;
    default:
      return QuestionType.comprehension;
  }
}

Difficulty parseDifficulty(String value) {
  switch (value.toLowerCase()) {
    case 'easy':
      return Difficulty.easy;
    case 'medium':
      return Difficulty.medium;
    case 'hard':
      return Difficulty.hard;
    default:
      return Difficulty.easy;
  }
}

class Question {
  final String audioPrompt;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String? imagePath;
  final Difficulty difficulty;

  Question({
    required this.audioPrompt,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.imagePath,
    required this.difficulty,
  });

  /*
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      type: parseQuestionType(json['type']),
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      imagePath: json['imagePath'],
      difficulty: parseDifficulty(json['difficulty'] ?? 'easy'),
    );
  }
  */
}
