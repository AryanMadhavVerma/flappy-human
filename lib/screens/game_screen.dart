import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'dart:ui' as ui;
import 'dart:io';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double gravity = 0.2;
  static const double jumpForce = -1.5;
  static const double playerSize = 50.0;
  
  double playerY = 0.0;
  double playerVelocity = 0.0;
  List<double> pipeX = [];
  List<double> pipeOpeningY = [];
  Timer? gameTimer;
  ui.Image? playerImage;
  bool isStarted = false;
  bool isGameOver = false;
  double deathAnimationTime = 0.0;
  
  @override
  void initState() {
    super.initState();
    resetGame();
    _loadPlayerImage();
  }

  Future<void> _loadPlayerImage() async {
    final gameState = context.read<GameState>();
    if (gameState.facePath != null) {
      final completer = Completer<ui.Image>();
      ImageProvider imageProvider;
      
      if (gameState.facePath!.startsWith('data:')) {
        imageProvider = NetworkImage(gameState.facePath!);
      } else {
        imageProvider = FileImage(File(gameState.facePath!));
      }

      imageProvider.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) {
          completer.complete(info.image);
        }),
      );
      
      playerImage = await completer.future;
      setState(() {});
    }
  }

  void resetGame() {
    setState(() {
      playerY = 0.0;
      playerVelocity = 0.0;
      pipeX = [1.5]; // Start with one pipe
      pipeOpeningY = [0.0];
      isStarted = false;
      isGameOver = false;
      deathAnimationTime = 0.0;
    });
    
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void updateGame() {
    if (!mounted) return;
    
    final gameState = context.read<GameState>();
    if (!gameState.isPlaying) return;

    setState(() {
      if (isGameOver) {
        // Death animation
        deathAnimationTime += 0.016;
        if (deathAnimationTime >= 1.0) {
          gameState.gameOver();
          return;
        }
        playerVelocity += gravity;
        playerY += playerVelocity * 0.016; // Time-based movement
        return;
      }

      if (!isStarted) return;

      // Update player position
      playerVelocity += gravity;
      playerY += playerVelocity * 0.016; // Time-based movement

      // Update pipes
      for (int i = 0; i < pipeX.length; i++) {
        // Move pipes left at half speed
        pipeX[i] -= 1.0 * 0.016; // Reduced from 2.0 to 1.0 for 50% slower movement

        // Check if pipe is off screen
        if (pipeX[i] < -0.5) {
          pipeX[i] = 1.5; // Reset pipe to right side
          // Random height between -0.3 and 0.3
          pipeOpeningY[i] = -0.3 + (DateTime.now().millisecondsSinceEpoch % 600) / 1000.0;
          gameState.incrementScore();
        }

        // Check collision
        if (pipeX[i] < 0.3 && pipeX[i] > 0.1) {
          final gapSize = 0.3; // Fixed gap size
          if (playerY < pipeOpeningY[i] - gapSize ||
              playerY > pipeOpeningY[i] + gapSize) {
            startDeathAnimation();
          }
        }
      }

      // Check boundaries
      if (playerY > 1.0 || playerY < -1.0) {
        startDeathAnimation();
      }
    });
  }

  void startDeathAnimation() {
    isGameOver = true;
    deathAnimationTime = 0.0;
  }

  void jump() {
    if (isGameOver) return;
    
    if (!isStarted) {
      isStarted = true;
      return;
    }
    setState(() {
      playerVelocity = jumpForce;
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => jump(),
        child: Consumer<GameState>(
          builder: (context, gameState, child) {
            return Stack(
              children: [
                CustomPaint(
                  painter: GamePainter(
                    playerY: playerY,
                    pipeX: pipeX,
                    pipeOpeningY: pipeOpeningY,
                    gapSize: 0.3,
                    playerImage: playerImage,
                    isGameOver: isGameOver,
                  ),
                  size: Size.infinite,
                ),
                if (!isStarted && !isGameOver && gameState.isPlaying)
                  const Center(
                    child: Text(
                      'Tap to Start',
                      style: TextStyle(
                        fontSize: 36,
                        color: Color(0xFF39FF14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score: ${gameState.score}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Color(0xFF39FF14),
                        ),
                      ),
                      Text(
                        'Level: ${gameState.currentLevel}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Color(0xFF39FF14),
                        ),
                      ),
                    ],
                  ),
                ),
                if (gameState.isDead)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Game Over\nScore: ${gameState.score}\nLevel: ${gameState.currentLevel}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 48,
                            color: Color(0xFFFF1493),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            gameState.startGame();
                            resetGame();
                          },
                          child: const Text('Restart'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Main Menu'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  static const double playerSize = 50.0;
  final double playerY;
  final List<double> pipeX;
  final List<double> pipeOpeningY;
  final double gapSize;
  final ui.Image? playerImage;
  final bool isGameOver;

  GamePainter({
    required this.playerY,
    required this.pipeX,
    required this.pipeOpeningY,
    required this.gapSize,
    required this.isGameOver,
    this.playerImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final backgroundPaint = Paint()..color = const Color(0xFF000B1C);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Draw grid lines for visual effect
    final gridPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..strokeWidth = 1.0;
    
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw pipes with glow effect
    final pipePaint = Paint()
      ..color = const Color(0xFFFF1493)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
      
    for (int i = 0; i < pipeX.length; i++) {
      final pipeLeft = size.width * pipeX[i];
      final openingY = size.height * (0.5 + pipeOpeningY[i]);
      final halfGap = size.height * gapSize;

      // Upper pipe
      canvas.drawRect(
        Rect.fromLTWH(pipeLeft, 0, 80, openingY - halfGap),
        pipePaint,
      );

      // Lower pipe
      canvas.drawRect(
        Rect.fromLTWH(
          pipeLeft,
          openingY + halfGap,
          80,
          size.height - (openingY + halfGap),
        ),
        pipePaint,
      );
    }

    // Draw player
    final playerPosition = Offset(
      size.width * 0.2,
      size.height * (0.5 + playerY),
    );

    if (playerImage != null) {
      final playerRect = Rect.fromCenter(
        center: playerPosition,
        width: playerSize,
        height: playerSize,
      );
      
      // Add glow effect
      final glowPaint = Paint()
        ..color = isGameOver ? Colors.red.withOpacity(0.3) : const Color(0xFF39FF14).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
      canvas.drawCircle(playerPosition, playerSize * 0.6, glowPaint);
      
      canvas.drawImageRect(
        playerImage!,
        Rect.fromLTWH(0, 0, playerImage!.width.toDouble(), playerImage!.height.toDouble()),
        playerRect,
        Paint(),
      );
    } else {
      // Draw default player with glow
      final glowPaint = Paint()
        ..color = isGameOver ? Colors.red.withOpacity(0.3) : const Color(0xFF39FF14).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
      canvas.drawCircle(playerPosition, playerSize * 0.6, glowPaint);
      
      final playerPaint = Paint()
        ..color = isGameOver ? Colors.red : const Color(0xFF39FF14);
      canvas.drawCircle(playerPosition, playerSize * 0.5, playerPaint);
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}

