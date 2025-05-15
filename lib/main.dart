import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:multiple_question_type_flutter_quiz/question.dart';
import 'package:multiple_question_type_flutter_quiz/quiz_provider.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<List<Question>> loadQuestions() async {
    final String jsonString = await rootBundle.loadString('questions.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((e) => Question.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Question>>(
      future: loadQuestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        } else if (snapshot.hasError) {
          return MaterialApp(
              home: Scaffold(body: Center(child: Text('Error: ${snapshot.error}'))));
        } else {
          return ChangeNotifierProvider(
            create: (_) => QuizProvider(snapshot.data!),
            child: MaterialApp(
              home: QuizScreen(),
            ),
          );
        }
      },
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
  
    if (question.type == QuestionType.trueFalse) {
      return ['True', 'False'].map((option) {
        return ElevatedButton(
          onPressed: () => quiz.answer(option),
          child: Text(option),
        );
      }).toList();
    }


    return question.options.map((option) {
      return ElevatedButton(
        onPressed: () => quiz.answer(option),
        child: Text(option),
      );
    }).toList();
  }
}