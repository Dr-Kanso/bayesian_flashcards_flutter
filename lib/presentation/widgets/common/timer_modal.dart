import 'package:flutter/material.dart';

class TimerModal extends StatelessWidget {
  final VoidCallback onClose;

  const TimerModal({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF373737),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_off,
                size: 64,
                color: Color(0xFF2496DC),
              ),
              const SizedBox(height: 16),
              const Text(
                'Time\'s Up!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a break and come back when you\'re ready.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onClose,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
