import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../providers/session_provider.dart';
import '../widgets/common/timer_modal.dart';
import 'dart:convert';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Session'),
        actions: [
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              return Row(
                children: [
                  Text(
                    '${sessionProvider.timer ~/ 60}:${(sessionProvider.timer % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    onPressed: sessionProvider.toggleTimer,
                    icon: Icon(sessionProvider.isTimerRunning
                        ? Icons.pause
                        : Icons.play_arrow),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        sessionProvider.endSession();
                      },
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('End Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          return Stack(
            children: [
              _buildReviewContent(sessionProvider),
              if (sessionProvider.showTimerModal)
                TimerModal(onClose: sessionProvider.dismissTimerModal),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewContent(SessionProvider sessionProvider) {
    final card = sessionProvider.currentCard;

    if (card == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Session info
          if (sessionProvider.currentSession != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF373737),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Active Session: ${sessionProvider.currentSession!.name}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

          const SizedBox(height: 20),

          // Card content
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Front side
                    Expanded(
                      child: Column(
                        children: [
                          Html(data: card.front),
                          if (card.frontImage != null)
                            Expanded(
                              child: _buildImageFromBase64(card.frontImage!),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Back side or show answer button
                    if (sessionProvider.showBack) ...[
                      Expanded(
                        child: Column(
                          children: [
                            Html(data: card.back),
                            if (card.backImage != null)
                              Expanded(
                                child: _buildImageFromBase64(card.backImage!),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildRatingControls(sessionProvider),
                    ] else
                      ElevatedButton(
                        onPressed: sessionProvider.showCardBack,
                        child: const Text('Show Answer'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(String base64String) {
    try {
      final bytes = base64Decode(base64String.split(',').last);
      return Image.memory(bytes, fit: BoxFit.contain);
    } catch (e) {
      return Container(
        height: 100,
        color: Colors.grey[300],
        child: const Center(child: Text('Invalid image')),
      );
    }
  }

  Widget _buildRatingControls(SessionProvider sessionProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Hard'),
            Expanded(
              child: Slider(
                value: sessionProvider.rating.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) =>
                    sessionProvider.updateRating(value.toInt()),
              ),
            ),
            const Text('Easy'),
          ],
        ),
        Text(
          'Rating: ${sessionProvider.rating}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: sessionProvider.submitReview,
          child: const Text('Submit Review'),
        ),
      ],
    );
  }
}
