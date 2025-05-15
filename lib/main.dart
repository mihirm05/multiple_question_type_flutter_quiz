import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'quiz_provider.dart';
import 'question.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => QuizProvider([
        Question(
          questionText: 'What is the capital of France?',
          type: QuestionType.multipleChoice,
          options: ['Paris', 'London', 'Berlin'],
          correctAnswer: 'Paris',
        ),
        Question(
          questionText: 'Which animal is shown?',
          type: QuestionType.imageBased,
          imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg',
          options: ['Dog', 'Cat', 'Rabbit'],
          correctAnswer: 'Cat',
        ),
        Question.trueFalse(
          questionText: 'The Earth is flat.',
          isTrue: false,
  ),
      ]),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Quiz App',
      home: QuizScreen(),
    );
  }
}

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = Provider.of<QuizProvider>(context);

    if (quiz.isFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Finished')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Your score: ${quiz.score}/${quiz.totalQuestions}',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: quiz.reset,
                child: const Text('Restart Quiz'),
              ),
            ],
          ),
        ),
      );
    }

    final question = quiz.currentQuestion;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (question.type == QuestionType.imageBased &&
                question.imageUrl != null)
              Image.network(question.imageUrl!, height: 200),
            const SizedBox(height: 16),
            Text(
              question.questionText,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            ..._buildOptions(question, quiz),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptions(Question question, QuizProvider quiz) {
    // True/False questions
    if (question.type == QuestionType.trueFalse) {
      return ['True', 'False'].map((option) {
        return ElevatedButton(
          onPressed: () => quiz.answer(option),
          child: Text(option),
        );
      }).toList();
    }

    // Multiple choice or image-based
    return question.options.map((option) {
      return ElevatedButton(
        onPressed: () => quiz.answer(option),
        child: Text(option),
      );
    }).toList();
  }
}

