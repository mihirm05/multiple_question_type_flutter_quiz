import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:multiple_question_type_flutter_quiz/question.dart';
import 'package:multiple_question_type_flutter_quiz/quiz_provider.dart';
import 'package:provider/provider.dart';
import 'package:multiple_question_type_flutter_quiz/hexa_match.dart' as hexa;


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
    int questionCounter = 0;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Quiz')),
      body: Consumer<QuizProvider>(
        builder: (context, quiz, child) {
          if (quiz.isFinished) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Finished! Score: ${quiz.score}/${quiz.totalQuestions}'),
                  ElevatedButton(
                    onPressed: () => quiz.reset(),
                    child: const Text('Restart'),
                  ),
                ],
              ),
            );
          }

          final question = quiz.currentQuestion;
          questionCounter += 1;
          print('questionCounter: $questionCounter');

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                /*
                hexa.HexagonPathWidget(hexaInit: questionCounter == 1 ? true : false, 
                                       patientAnswer: true, 
                                       rivalAnswer: true, 
                                       score: questionCounter, 
                                       nextPage: '',
                                       buttonPressed: true
                                       ),
                */
                  
                question.imageUrl != null
                  ? Image.network(question.imageUrl!, height: 200)
                  : SizedBox(),
                const SizedBox(height: 20),
                Text(
                  question.questionText,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                ...question.options.map((option) => ElevatedButton(
                      onPressed: () => quiz.answer(option),
                      child: Text(option),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
