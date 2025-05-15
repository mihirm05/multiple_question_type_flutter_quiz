enum QuestionType { multipleChoice, imageBased, trueFalse }

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

  // Factory constructor to create True/False question easily
  factory Question.trueFalse({
    required String questionText,
    required bool isTrue,
  }) {
    return Question(
      questionText: questionText,
      type: QuestionType.trueFalse,
      options: ['True', 'False'],
      correctAnswer: isTrue ? 'True' : 'False',
    );
  }
}
