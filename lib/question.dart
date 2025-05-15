enum QuestionType { multipleChoice, imageBased, trueFalse }

QuestionType parseQuestionType(String value) {
  switch (value) {
    case 'multipleChoice':
      return QuestionType.multipleChoice;
    case 'imageBased':
      return QuestionType.imageBased;
    case 'trueFalse':
      return QuestionType.trueFalse;
    default:
      throw Exception('Unknown question type: $value');
  }
}

class Question {
  final String questionText;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String? imageUrl;

  Question({
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.imageUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionText: json['questionText'],
      type: parseQuestionType(json['type']),
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      imageUrl: json['imageUrl'],
    );
  }
}
