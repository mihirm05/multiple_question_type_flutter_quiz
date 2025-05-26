import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multiple_question_type_flutter_quiz/config.dart' as config;
import 'package:multiple_question_type_flutter_quiz/hexa_config.dart' as hexa_config;
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
    print('jsonData: $jsonData');
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
    print('config.questionCounter: ${config.questionCounter}');
    
    return Scaffold(
      //appBar: AppBar(title: const Text('Adaptive Quiz')),
      body: Consumer<QuizProvider>(
        builder: (context, quiz, child) {
          if (quiz.isFinished) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Finished! Score: ${quiz.score}/${quiz.totalQuestions}'),
                  ElevatedButton(
                    onPressed: (){
                      quiz.reset();
                    },
                    child: const Text('Restart'),
                  ),
                  
                ],
              ),
            );
          }

          Random random = Random();

          final question = quiz.currentQuestion;
          config.questionCounter += 1;
          List<bool> rivalBool = [true, false];
          print('questionCounter: ${config.questionCounter}');


          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                
                SizedBox(
                  height: 5,
                  width: 100,
                  child: hexa.HexagonPathWidget(hexaInit: (config.questionCounter == 1) ? true : false,
                                                patientAnswer: Provider.of<QuizProvider>(context).lastSelectedAnswer, 
                                                rivalAnswer: rivalBool[random.nextInt(rivalBool.length)], 
                                                score: config.questionCounter, 
                                                buttonPressed: Provider.of<QuizProvider>(context).lastSelectedAnswer == null ? false : true,
                                                ),
                ),
                                
                SizedBox(height:500, width:500), 

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [...question.options.map((option) => 
                  Column(
                    children:[
                      
                      Row(children:[
                        IconButton(
                        onPressed: (){
                          quiz.answer(option);
                        },
                        icon: Image.asset(option, height: 250, width: 250),
                      ),
                      ]
                  )]
                  )
                    ),]),
                
              ],
            ),
          );
        },
      ),
    );
  }
}
