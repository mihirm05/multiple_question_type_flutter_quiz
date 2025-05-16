// Importiert das grundlegende Material-Design-Paket für Flutter, das UI-Komponenten und Themes bietet.
import 'package:flutter/material.dart';

// Importiert das Dart-Mathematikpaket, das Funktionen und Konstanten (wie Random()) zur Verfügung stellt.
import 'dart:math';
import 'package:multiple_question_type_flutter_quiz/config.dart' as config;
import 'package:multiple_question_type_flutter_quiz/hexa_config.dart';

// -------------------------------------------------------------------
// Klasse HexagonPathWidget (StatefulWidget)
// -------------------------------------------------------------------
// HexagonPathWidget verwaltet den Zustand, der während des Spiels
// (z. B. Spielerpositionen, Zustände) geändert wird.
class HexagonPathWidget extends StatefulWidget {
  HexagonPathWidget({super.key,
                    required this.hexaInit,
                    required this.patientAnswer,
                    required this.rivalAnswer,
                    required this.score,
                    required this.nextPage,
                    required this.buttonPressed
                   });

  @override
  _HexagonPathWidgetState createState() => _HexagonPathWidgetState();
  bool? patientAnswer;
  bool? rivalAnswer;
  String nextPage;
  int score;
  bool buttonPressed;
  
  bool hexaInit;
}

// -------------------------------------------------------------------
// Klasse _HexagonPathWidgetState
// -------------------------------------------------------------------
// Der State speichert alle Spielfeldvariablen, wie z. B. die Pfade der Spieler,
// Zustände, Spielfeldgrenzen und die Logik der Spielzüge.
class _HexagonPathWidgetState extends State<HexagonPathWidget> {

  // Spielfeldgrenzen (lokales Koordinatensystem des Widgets):
  late double boundaryLeft; // Linke Grenze; hier im Widget 0.
  late double boundaryRight; // Rechte Grenze; entspricht fieldWidth.
  late double boundaryTop; // Obere Grenze.
  late double boundaryBottom; // Untere Grenze.

  // Breite des Spielfelds (entspricht 90 % der Gesamtbreite, da dieses Widget im rechten Container liegt).
  late double fieldWidth;

  // gridStep: Die horizontale Schrittweite (in Pixel), berechnet als: fieldWidth / (minimalSteps * rasterPerStep).
  late double gridStep;

  // Vertikale Spielfeldhöhe; soll ein ganzzahliges Vielfaches von gridStep sein.
  late double fieldHeight;

  // finishLine: Die x-Koordinate, ab der ein Token als Gewinner gilt.
  late double finishLine;

  String?
  wonBy; // Gewinnerstatus; wird als "player" oder "rival" gesetzt, oder ist null, wenn noch kein Gewinner feststeht.

  // Random-Objekt für zufällige Berechnungen (z. B. für Verzögerungen oder Wahrscheinlichkeiten).
  final Random _random = Random();

  // Konfiguration: Minimale Anzahl an Spielschritten und Rasterfenstern pro Schritt.
  final int minimalSteps = 60;
  final int rasterPerStep = 3;

  // Übergangstabelle (_transitions):
  // Diese Map definiert, welche nächsten Zustände möglich sind,
  // abhängig vom aktuellen HexState und ob die Antwort richtig (true) oder falsch (false) war.
  final Map<HexState, Map<bool, List<HexState>>> _transitions = {
    HexState.Start: {
      true: [HexState.RightDown],
      false: [HexState.Up],
    },
    HexState.RightDown: {
      true: [HexState.RightUp],
      false: [HexState.Down, HexState.LeftUp],
    },
    HexState.Up: {
      true: [HexState.RightUp, HexState.Down],
      false: [HexState.LeftUp, HexState.Down],
    },
    HexState.RightUp: {
      true: [HexState.RightDown],
      false: [HexState.Up, HexState.LeftDown],
    },
    HexState.LeftUp: {
      true: [HexState.Up, HexState.RightDown],
      false: [HexState.LeftDown, HexState.Up],
    },
    HexState.Down: {
      true: [HexState.RightDown, HexState.Up],
      false: [HexState.LeftDown, HexState.Up],
    },
    HexState.LeftDown: {
      true: [HexState.Down, HexState.RightUp],
      false: [HexState.LeftUp, HexState.Down],
    },
  };

  // _stateOffsets:
  // Diese Map weist jedem HexState einen Offset-Vektor zu (dx, dy) in "Hex-Einheiten".
  // Die tatsächliche Pixelverschiebung wird später durch Multiplikation mit gridStep berechnet.
  final Map<HexState, Offset> _stateOffsets = {
    HexState.Start: Offset(0, 0),
    HexState.RightDown: Offset(3, -2),
    HexState.Up: Offset(0, 4),
    HexState.RightUp: Offset(3, 2),
    HexState.LeftUp: Offset(-3, 2),
    HexState.Down: Offset(0, -4),
    HexState.LeftDown: Offset(-3, -2),
  };

  @override
  void initState() {
  super.initState();

  // Move only once, right after first frame
  //WidgetsBinding.instance.addPostFrameCallback((_) {
  //  makeMove(widget.patientAnswer);
  //}
  //);

  // Delayed navigation after animation
  //Future.delayed(Duration(seconds: 5), () {
  //  if (mounted) {
  //    Navigator.pushNamed(context, widget.nextPage);
  //  }
  //});

  // Reset win state
  wonBy = null;
}
  // Überprüft, ob ein gegebener Offset (pos) außerhalb des Spielfeldes liegt.
  bool isOutOfBounds(Offset pos) {
    return pos.dx < boundaryLeft ||
        pos.dx > boundaryRight ||
        pos.dy < boundaryTop ||
        pos.dy > boundaryBottom;
  }

  // Berechnet den nächsten Spielzug, basierend auf der aktuellen Position, Zustand und ob die Antwort richtig war.
  MoveResult calculateMove(
    Offset currentPos,
    HexState currentState,
    bool? correct,
  ) {
    final List<HexState>? candidateStates =
        _transitions[currentState]?[correct];
    if (candidateStates == null || candidateStates.isEmpty) {
      return MoveResult(currentPos, currentState);
    }
    // Wähle den ersten Kandidaten als Standard.
    HexState chosenState = candidateStates.first;
    Offset offsetPrimary = _stateOffsets[chosenState]! * gridStep;
    Offset newPosPrimary = currentPos + offsetPrimary;
    // Falls die berechnete neue Position außerhalb liegt und Alternativen existieren, prüfe diese.
    if (isOutOfBounds(newPosPrimary) && candidateStates.length > 1) {
      List<HexState> alternatives = candidateStates.sublist(1);
      HexState? alternativeState;
      for (var stateCandidate in alternatives) {
        Offset altPos =
            currentPos + (_stateOffsets[stateCandidate]! * gridStep);
        if (!isOutOfBounds(altPos)) {
          alternativeState = stateCandidate;
          break;
        }
      }
      if (alternativeState != null) {
        chosenState = alternativeState;
        newPosPrimary = currentPos + (_stateOffsets[chosenState]! * gridStep);
      }
    }
    return MoveResult(newPosPrimary, chosenState);
  }

  // Ermittelt die emotionale Stimmung des Rivalen anhand seiner relativen horizontalen Position zum Spieler.
  // Logik:
  // - Falls bereits ein Gewinner existiert, werden feste Emotionen ("bloating" bei Rivale, "angry" bei Spieler) zurückgegeben.
  // - Ansonsten wird die Differenz (diff) der x-Koordinaten berechnet.
  //   Wird dieser Unterschied (Betrag) verglichen mit einem Schwellenwert (hier 4 * 3 * gridStep).
  //   Je nachdem, ob diff kleiner, größer oder kleiner als minus Schwellenwert ist, wird "expecting", "content" oder "dissatisfied" zurückgegeben.
  String getRivalEmotion() {
    if (wonBy != null) {
      if (wonBy == 'rival') return "bloating";
      if (wonBy == 'player') return "angry";
    }
    double diff = rivalPath.last.dx - playerPath.last.dx;
    double threshold = 4 * 3 * gridStep; // Schwellenwert = 12 * gridStep.
    if (diff.abs() < threshold) {
      return config.r1Expecting1;
    } else if (diff <= -threshold) {
      // Rivale liegt hinter dem Spieler.
      return config.r1Dissatisfied1;
    } else if (diff >= threshold) {
      // Rivale liegt vor dem Spieler.
      return config.r1Content1;
    }
    return config.r1Expecting1; // Fallback (sollte eigentlich nie erreicht werden).
  }

  // Führt einen vollständigen Spielzug aus: zuerst den Zug des Spielers, danach den des Rivalen.
  void makeMove(bool? playerCorrect) async {
    if (wonBy != null) return;

    // Berechne und führe den Spielerzug aus.
    final playerMove = calculateMove(
      playerPath.last,
      playerState,
      playerCorrect!,
    );
    if (isOutOfBounds(playerMove.newPosition)) return;
    setState(() {
      playerPath.add(playerMove.newPosition);
      playerState = playerMove.newState;
      playerMoveHistory.add(playerCorrect);
      rivalMoveHistory.add(widget.rivalAnswer);
    });
    _checkWinCondition(playerMove.newPosition, 'player');
    if (wonBy != null) return;

    // Warte eine variable Verzögerung (zwischen 20 und 39 Millisekunden) vor dem Rivalenzug.
    //await Future.delayed(Duration(milliseconds: 20 + _random.nextInt(20)));
    if (!mounted || wonBy != null) return;

    int moves = playerMoveHistory.length;
    double rivalProbability;
    // Lokale Variable baseRivalProbability: zufällig zwischen 0,4 und 0,6.
    double baseRivalProbability = 0.4 + _random.nextDouble() * 0.2;
    if (moves <= 10) {
      rivalProbability = baseRivalProbability;
    } else if (moves <= 20) {
      List<bool> first10 = playerMoveHistory.sublist(0, 10);
      double avgFirst =
          first10.fold(0.0, (sum, e) => sum + (e ? 1.0 : 0.0)) / 10.0;
      rivalProbability = 2 * avgFirst - baseRivalProbability;
      rivalProbability = rivalProbability.clamp(0.0, 1.0);
    } else {
      List<bool> recentHistory = playerMoveHistory.sublist(moves - 10);
      double avgRecent =
          recentHistory.fold(0.0, (sum, e) => sum + (e ? 1.0 : 0.0)) / 10.0;
      rivalProbability = avgRecent;
    }
    bool? rivalCorrect = widget.rivalAnswer;
    final rivalMove = calculateMove(rivalPath.last, rivalState, rivalCorrect);
    if (isOutOfBounds(rivalMove.newPosition)) return;
    setState(() {
      rivalPath.add(rivalMove.newPosition);
      rivalState = rivalMove.newState;
    });
    _checkWinCondition(rivalMove.newPosition, 'rival');
    // navigate to a new page right at the end of makeMove
    if(widget.buttonPressed){
      await Future.delayed(Duration(milliseconds: 900)); 
      Navigator.pushNamed(context, widget.nextPage);
    }
  }

  // Prüft, ob ein gegebener Token die Ziellinie überschritten hat.
  void _checkWinCondition(Offset pos, String competitor) {
    if (pos.dx > finishLine &&
        pos.dy >= boundaryTop &&
        pos.dy <= boundaryBottom) {
      setState(() {
        wonBy = competitor;
      });
    }
  }

  // -------------------------------------------------------------------
  // build()-Methode: Aufbau des UI für das HexagonPathWidget.
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Der Aufbau erfolgt mit einem LayoutBuilder, um die Gesamtbreite zu ermitteln.
    // Das Widget wird in einer Row dargestellt:
    // - Linker Bereich (10 %): Enthält Platzhalter für Gesichter.
    // - Rechter Bereich (90 %): Enthält das Spielfeld (CustomPaint, Steuerungsbuttons).
    //makeMove(widget.answer);
    bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    // Ermittle die Bildschirmgröße über MediaQuery.
    final Size screenSize = MediaQuery.of(context).size;

    // Da das Spielfeld im rechten Bereich (90 % der Breite) erscheint:
    fieldWidth = screenSize.width * 0.75;
    // Im lokalen Koordinatensystem des Widgets beginnt die linke Kante bei 0.
    boundaryLeft = 0;
    // Rechte Grenze entspricht der fieldWidth.
    boundaryRight = fieldWidth;

    // Berechnung der Schrittweite:
    // Insgesamt gibt es (minimalSteps * rasterPerStep) horizontale Rasterfenster.
    gridStep = fieldWidth / (minimalSteps * rasterPerStep);

    // Berechne die vertikale Spielfeldhöhe:
    // maxVertical soll weniger als 1/4 der fieldWidth betragen.
    double maxVertical = fieldWidth / 4;
    // Anzahl der Blöcke: Jeder Block entspricht 1 * gridStep.
    int verticalBlocks = maxVertical ~/ (1 * gridStep);
    fieldHeight = verticalBlocks * gridStep;

    // Vertikale Platzierung: Das Spielfeld wird im gesamten Bildschirm vertikal zentriert.
    boundaryTop = (MediaQuery.of(context).size.height - fieldHeight) / 50;
    boundaryBottom = boundaryTop + fieldHeight;

    // Ziellinie: finishLine wird hier auf 97 % der fieldWidth gesetzt.
    finishLine = fieldWidth * 0.97;

    // Startpositionen:
    // Ermittlung des vertikalen Mittelpunkts.
    double centerY = (boundaryTop + boundaryBottom) / 2;
    // Der Spieler startet links (x = 0) etwas oberhalb des Mittelpunkts.
    Offset startPlayer = Offset(0, centerY - (5 * gridStep));
    // Der Rivale startet links (x = 0) etwas unterhalb des Mittelpunkts.
    Offset startRival = Offset(0, centerY + (7 * gridStep));

    if(widget.hexaInit){
      playerPath = [startPlayer];
      rivalPath = [startRival];

      playerState = HexState.Start;
      rivalState = HexState.Start;
      print('playerPath: $playerPath');
      print('rivalPath: $rivalPath');
      print('playerState: $playerState');
      print('rivalPath: $rivalState');
    }
    
    if(widget.buttonPressed){
      makeMove(widget.patientAnswer);
    }

    
    return LayoutBuilder(
      builder: (context, constraints) {
        double totalWidth = constraints.maxWidth;
        double totalHeight = constraints.maxHeight;
        return Row(
          children: [
            SizedBox(width: totalWidth * 0.05,
              height: totalHeight * 0.4),
            // Linker Bereich: 10 % der Breite.
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isPortrait ? MediaQuery.of(context).size.width*0.05 : MediaQuery.of(context).size.width*0.05, 
                           width:  isPortrait ? MediaQuery.of(context).size.width*0.05 : MediaQuery.of(context).size.width*0.05, ),

                  // Oben: Platzhalter für das Bild des Spielers (später durch PNG ersetzt).
                  Image.asset(config.patientTherapist,
                              height: isPortrait ? MediaQuery.of(context).size.width*0.045 : MediaQuery.of(context).size.width*0.045, 
                              width:  isPortrait ? MediaQuery.of(context).size.width*0.045 : MediaQuery.of(context).size.width*0.045, 
                  ),
                  SizedBox(height: isPortrait ? MediaQuery.of(context).size.width*0.01 : MediaQuery.of(context).size.width*0.01, 
                           width:  isPortrait ? MediaQuery.of(context).size.width*0.01 : MediaQuery.of(context).size.width*0.01, ),
                  
                  // Unten: Dynamischer Text, der die emotionale Stimmung des Rivalen anzeigt.
                  Image.asset(
                    getRivalEmotion(),
                    height: isPortrait ? MediaQuery.of(context).size.width*0.045 : MediaQuery.of(context).size.width*0.045, 
                    width:  isPortrait ? MediaQuery.of(context).size.width*0.045 : MediaQuery.of(context).size.width*0.045, 

                  ),
                ],
              ),
            
            // Rechter Bereich: 90 % der Breite.
            Container(
              width: totalWidth * 0.85,
              height: totalHeight * 0.4,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // CustomPaint zeichnet das Spielfeld, die Pfade und die Ziellinie.
                        CustomPaint(
                          painter: StaticHexagonPainter(
                            playerPath: playerPath,
                            rivalPath: rivalPath,
                            finishLine: finishLine,
                            boundaryLeft: boundaryLeft,
                            boundaryTop: boundaryTop,
                            boundaryRight: boundaryRight,
                            boundaryBottom: boundaryBottom,
                          ),
                          child: Container(), // Platzhalter-Container.
                        ),
                        // Wird ein Gewinner festgelegt, so erscheint das Trophy-Widget zentriert.
                        if (wonBy != null)
                          Positioned(
                            left: boundaryRight / 2 - 100,
                            top: boundaryTop / 2,
                            child: _buildTrophy(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Erzeugt das Trophy-Widget, das beim Gewinn angezeigt wird.
  Widget _buildTrophy() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        // Die Farbe der Trophy hängt vom Gewinner ab: Blau für den Spieler, Orange für den Rivalen.
        color:
            wonBy == 'player'
                ? Colors.blue.shade300.withOpacity(0.9)
                : Colors.orange.shade300.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.emoji_events,
        size: 50,
        color: wonBy == 'player' ? Colors.blue[900]! : Colors.red[900]!,
      ),
    );
  }
}