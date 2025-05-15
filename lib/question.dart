enum QuestionType { multipleChoice, imageBased, trueFalse }
enum Difficulty { easy, medium, hard }

QuestionType parseQuestionType(String value) {
  switch (value.toLowerCase()) {
    case 'multiplechoice':
      return QuestionType.multipleChoice;
    case 'imagebased':
      return QuestionType.imageBased;
    case 'truefalse':
      return QuestionType.trueFalse;
    default:
      return QuestionType.multipleChoice;
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
  final String questionText;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String? imageUrl;
  final Difficulty difficulty;

  Question({
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.imageUrl,
    required this.difficulty,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionText: json['questionText'],
      type: parseQuestionType(json['type']),
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      imageUrl: json['imageUrl'],
      difficulty: parseDifficulty(json['difficulty'] ?? 'easy'),
    );
  }
}
