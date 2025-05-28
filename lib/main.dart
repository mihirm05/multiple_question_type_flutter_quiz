import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multiple_question_type_flutter_quiz/config.dart' as config;
import 'package:multiple_question_type_flutter_quiz/question.dart';
import 'package:multiple_question_type_flutter_quiz/quiz_generator.dart';
import 'package:multiple_question_type_flutter_quiz/quiz_provider.dart';
import 'package:provider/provider.dart';
import 'package:multiple_question_type_flutter_quiz/hexa_match.dart' as hexa;
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<List<Question>> loadQuestions() async {
    final String jsonString = await rootBundle.loadString('questions_mapping.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final Map<int, String> indexToUuid =
        jsonMap.map((key, value) => MapEntry(int.parse(key), value as String));

    return generateComprehensionQuestions(indexToUuid);
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
            child: const MaterialApp(
              home: QuizScreen(),
            ),
          );
        }
      },
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _lastPlayedPrompt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quiz = Provider.of<QuizProvider>(context, listen: false);
    //_playAudioIfNeeded(quiz.currentQuestion.audioPrompt);
  }

  @override
  void didUpdateWidget(covariant QuizScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final quiz = Provider.of<QuizProvider>(context, listen: false);
    _playAudioIfNeeded(quiz.currentQuestion.audioPrompt);
  }

  void _playAudioIfNeeded(String audioPrompt) async {
    if (_lastPlayedPrompt == audioPrompt) return;
    _lastPlayedPrompt = audioPrompt;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(audioPrompt));
    } catch (e) {
      debugPrint("Audio playback error: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;

    bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      body: Consumer<QuizProvider>(
        builder: (context, quiz, child) {
          if (quiz.isFinished) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Finished! Score: ${quiz.score}/${quiz.totalQuestions}'),
                  ElevatedButton(
                    onPressed: () {
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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 5,
                  width: 100,
                  child: hexa.HexagonPathWidget(
                    hexaInit: (config.questionCounter == 1),
                    patientAnswer: Provider.of<QuizProvider>(context).lastSelectedAnswer,
                    rivalAnswer: rivalBool[random.nextInt(rivalBool.length)],
                    score: config.questionCounter,
                    buttonPressed: Provider.of<QuizProvider>(context).lastSelectedAnswer != null,
                  ),
                ),
                SizedBox(
                  width: isPortrait ? deviceWidth * 0.10 : deviceHeight * 0.10,
                  height: isPortrait ? deviceHeight * 0.10 : deviceWidth * 0.10,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...question.options.map((option) => Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 10,
                                    minHeight: 10,
                                  ),
                                  onPressed: () {
                                    quiz.answer(option);
                                  },
                                  icon: Image.asset(
                                    option,
                                    width: isPortrait
                                        ? deviceWidth * 0.3
                                        : deviceHeight * 0.3,
                                    height: isPortrait
                                        ? deviceHeight * 0.3
                                        : deviceWidth * 0.3,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ))
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
