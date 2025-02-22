import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/game_state.dart';
import 'game_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          context.read<GameState>().setFacePath(base64Image);
        } else {
          context.read<GameState>().setFacePath(image.path);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Face Flappy',
              style: TextStyle(
                fontSize: 48,
                color: Color(0xFF39FF14),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Consumer<GameState>(
              builder: (context, gameState, child) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF39FF14), width: 2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ClipOval(
                    child: gameState.facePath != null
                        ? kIsWeb
                            ? Image.network(gameState.facePath!)
                            : Image.file(File(gameState.facePath!))
                        : const Icon(Icons.face, size: 60, color: Color(0xFF39FF14)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
              ),
              child: const Text('Change Face'),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                context.read<GameState>().startGame();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text(
                'Start Game',
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            Consumer<GameState>(
              builder: (context, gameState, child) {
                return Text(
                  'High Score: ${gameState.highScore}',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF39FF14),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
