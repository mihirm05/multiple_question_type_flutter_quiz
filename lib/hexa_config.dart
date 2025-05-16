// Importiert dart:ui mit dem Alias "ui", um erweiterte Grafikfunktionen nutzen zu können.
import 'package:flutter/material.dart';

// -------------------------------------------------------------------
// Enum für alle möglichen Zustände des Hexagonmusters.
// -------------------------------------------------------------------
// Ein Enum (Aufzählung) ist eine feste Menge von Werten. In diesem Fall
// definiert HexState die Richtungen, in die sich unser Token im Spiel bewegen kann.
enum HexState {
  Start, // Startzustand, bevor eine Bewegung erfolgt.
  RightDown, // Bewegung in Richtung rechts unten.
  Up, // Bewegung nach oben.
  RightUp, // Bewegung in Richtung rechts oben.
  LeftUp, // Bewegung in Richtung links oben.
  Down, // Bewegung nach unten.
  LeftDown, // Bewegung in Richtung links unten.
}

// -------------------------------------------------------------------
// Klasse MoveResult
// -------------------------------------------------------------------
// Diese Klasse fasst das Ergebnis eines Spielzuges zusammen – sie speichert
// sowohl die neue Position (als Offset, einer Kombination von x- und y-Koordinate)
// als auch den neuen Zustand (vom Typ HexState), der angibt, in welche Richtung
// der Token als nächstes bewegt wird.
class MoveResult {
  final Offset newPosition; // Neue Position nach der Bewegung.
  final HexState newState; // Neuer Zustand (Richtung) nach der Bewegung.

  // Konstruktor: Initialisiert newPosition und newState.
  MoveResult(this.newPosition, this.newState);
}

// Pfade (Listen von Offsets) für den Spieler und den Rivalen.
List<Offset> playerPath = [];
List<Offset> rivalPath = [];


// Aktuelle Zustände der Teilnehmer (vom Typ HexState).
HexState playerState = HexState.Start;
HexState rivalState = HexState.Start;


// Historie der Spielerantworten (true = richtig, false = falsch).
List<bool> playerMoveHistory = [];
List<bool?> rivalMoveHistory = [];


// -------------------------------------------------------------------
// Klasse StaticHexagonPainter
// -------------------------------------------------------------------
// Diese Klasse ist ein CustomPainter, der die visuellen Elemente des Spielfelds zeichnet.
// Sie darf NICHT innerhalb einer anderen Klasse deklariert werden – sie wird hier als eigenständige (top-level) Klasse definiert.
class StaticHexagonPainter extends CustomPainter {
  final List<Offset>
  playerPath; // Liste der Punkte, die den Spielerpfad darstellen.
  final List<Offset>
  rivalPath; // Liste der Punkte, die den Rivalpfad darstellen.
  final double finishLine; // x-Koordinate der Ziellinie.
  final double
  boundaryLeft; // Linke Grenze des Spielfelds (lokales Koordinatensystem des Widgets).
  final double boundaryTop; // Obere Grenze.
  final double boundaryRight; // Rechte Grenze.
  final double boundaryBottom; // Untere Grenze.

  // Konstruktor mit required Parametern: Alle Felder müssen beim Erzeugen angegeben werden.
  StaticHexagonPainter({
    required this.playerPath,
    required this.rivalPath,
    required this.finishLine,
    required this.boundaryLeft,
    required this.boundaryTop,
    required this.boundaryRight,
    required this.boundaryBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Zeichnet den Pfad des Spielers in Blau.
    _drawPath(canvas, playerPath, Colors.blue);
    // Zeichnet den Pfad des Rivalen in Orange.
    _drawPath(canvas, rivalPath, Colors.orange);
    // Wenn der Spielerpfad nicht leer ist, zeichne ein Personensymbol an der letzten Position.
    if (playerPath.isNotEmpty) {
      _drawIcon(canvas, playerPath.last, Icons.person, Colors.blue);
    }
    // Wenn der Rivalenpfad nicht leer ist, zeichne ein Warnsymbol an der letzten Position.
    if (rivalPath.isNotEmpty) {
      _drawIcon(canvas, rivalPath.last, Icons.warning, Colors.orange);
    }
    // Zeichnet die gestrichelte Ziellinie.
    final double dashWidth = 8.0; // Breite jedes Strichs.
    final double dashSpace = 5.0; // Abstand zwischen den Strichen.
    double startY =
        boundaryTop; // Beginn der gestrichelten Linie am oberen Rand.
    final Paint linePaint =
        Paint()
          ..color =
              Colors
                  .black // Farbe der Linie.
          ..strokeWidth =
              3 // Dicke der Linie.
          ..style = PaintingStyle.stroke;
    while (startY < boundaryBottom) {
      final double endY = startY + dashWidth;
      canvas.drawLine(
        Offset(finishLine, startY),
        Offset(finishLine, endY.clamp(startY, boundaryBottom)),
        linePaint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  // Methode _drawPath:
  // Diese Methode verbindet die Punkte (Offsets) in der Liste "path" zu einem Pfad und zeichnet ihn mit der angegebenen Farbe.
  void _drawPath(Canvas canvas, List<Offset> path, Color color) {
    if (path.length < 2) return;
    final Paint paint =
        Paint()
          ..color =
              color // Farbe des Pfades.
          ..strokeWidth =
              4 // Dicke der gezeichneten Linie.
          ..style = PaintingStyle.stroke;
    final Path fullPath = Path()..moveTo(path[0].dx, path[0].dy);
    for (final point in path.skip(1)) {
      fullPath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(fullPath, paint);
  }

  // Methode _drawIcon:
  // Diese Methode zeichnet ein Icon (basierend auf dem Unicode-Codepunkt) an der gegebenen Position.
  // Die Zeichnung erfolgt über einen TextPainter, der das Icon zentriert darstellt.
  void _drawIcon(Canvas canvas, Offset position, IconData icon, Color color) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(
          icon.codePoint,
        ), // Konvertiert den Codepunkt des Icons in einen String.
        style: TextStyle(
          fontSize: 25, // Schriftgröße, die dem Icon entspricht.
          fontFamily:
              icon.fontFamily, // Nutzt die Schriftfamilie, die das Icon definiert.
          color: color, // Farbe des Icons.
        ),
      ),
      textDirection: TextDirection.ltr, // Leserichtung: von links nach rechts.
    )..layout();
    // Um das Icon zu zentrieren, wird von der Position die halbe Breite und halbe Höhe des TextPainters abgezogen.
    final Offset offset =
        position - Offset(textPainter.width / 2, textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant StaticHexagonPainter oldDelegate) {
    // Repaint erforderlich, wenn sich die Pfade von Spieler oder Rival verändert haben.
    return oldDelegate.playerPath != playerPath ||
        oldDelegate.rivalPath != rivalPath;
  }
}

