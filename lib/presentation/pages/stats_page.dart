import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/deck_provider.dart';
import '../widgets/stats/stats_chart.dart';
import '../../domain/models/session.dart';
import '../../domain/models/user.dart';
import '../../domain/models/review.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _statsType = 'user';
  String? _selectedDeck;
  String? _selectedSessionId;
  List<Session> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final sessions = await sessionProvider.getSessions();
    setState(() {
      _sessions = sessions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F2F31),
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: const Color(0xFF373737),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 20),
            if (_statsType == 'session') _buildSessionsList(),
            const SizedBox(height: 20),
            Expanded(child: _buildStatsChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF373737),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Stats Type:',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statsType,
                  onChanged: (value) {
                    setState(() {
                      _statsType = value!;
                      if (_statsType != 'session') {
                        _selectedSessionId = null;
                      }
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF2F2F31),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF2F2F31),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User Statistics')),
                    DropdownMenuItem(value: 'deck', child: Text('Deck Statistics')),
                    DropdownMenuItem(value: 'session', child: Text('Session Statistics')),
                  ],
                ),
              ),
            ],
          ),
          if (_statsType == 'deck') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Deck:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<DeckProvider>(
                    builder: (context, deckProvider, child) {
                      return DropdownButtonFormField<String>(
                        value: _selectedDeck,
                        onChanged: (value) {
                          setState(() {
                            _selectedDeck = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: const Color(0xFF2F2F31),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF2F2F31),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Select a deck')),
                          ...deckProvider.decks.map((deck) => DropdownMenuItem(
                            value: deck.name,
                            child: Text(deck.name),
                          )),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
          if (_statsType == 'session') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Session:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSessionId,
                    onChanged: (value) {
                      setState(() {
                        _selectedSessionId = value;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF2F2F31),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF2F2F31),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select a session')),
                      ..._sessions.map((session) => DropdownMenuItem(
                        value: session.id,
                        child: Text('${session.name} (${_formatDate(session.startTime)})'),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_sessions.isEmpty) {
      return const Text(
        'No study sessions found. Start a new session to begin.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF373737),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study Sessions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 12,
                headingRowColor: WidgetStateProperty.all(const Color(0xFF2F2F31)),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF2496DC).withValues(alpha: 51); // 0.2 opacity is roughly 51 as alpha
                  }
                  return null;
                }),
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Date', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Duration', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                ],
                rows: _sessions.map((session) {
                  final isSelected = _selectedSessionId == session.id;
                  return DataRow(
                    selected: isSelected,
                    cells: [
                      DataCell(Text(session.name, style: const TextStyle(color: Colors.white))),
                      DataCell(Text(_formatDate(session.startTime), style: const TextStyle(color: Colors.white))),
                      DataCell(Text(_formatDuration(session), style: const TextStyle(color: Colors.white))),
                      DataCell(
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedSessionId = session.id;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2496DC),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('View Stats'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChart() {
    return Consumer2<SessionProvider, DeckProvider>(
      builder: (context, sessionProvider, deckProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getStatsData(sessionProvider, deckProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading statistics: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final data = snapshot.data!;
            return StatsChart(
              statsType: _statsType,
              user: data['user'] as User?,
              reviews: data['reviews'] as List<Review>?,
              session: data['session'] as Session?,
              deckName: _selectedDeck,
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getStatsData(SessionProvider sessionProvider, DeckProvider deckProvider) async {
    switch (_statsType) {
      case 'user':
        // Get default user (for now, we'll use a mock user)
        final user = User(
          id: 1,
          username: 'default',
          recallHistory: await _getUserRecallHistory(),
        );
        return {'user': user};

      case 'deck':
        if (_selectedDeck != null) {
          final deck = deckProvider.decks.firstWhere((d) => d.name == _selectedDeck);
          final reviews = await _getDeckReviews(deck.id!);
          return {'reviews': reviews};
        }
        return {'reviews': <Review>[]};

      case 'session':
        if (_selectedSessionId != null) {
          final session = _sessions.firstWhere((s) => s.id == _selectedSessionId);
          final reviews = await _getSessionReviews(_selectedSessionId!);
          return {'session': session, 'reviews': reviews};
        }
        return {'session': null, 'reviews': <Review>[]};

      default:
        return {};
    }
  }

  Future<List<List<dynamic>>> _getUserRecallHistory() async {
    // This would normally come from your database
    // For now, return mock data
    return [
      [10, 1], [15, 0], [5, 1], [20, 1], [8, 0],
      [12, 1], [18, 1], [6, 0], [25, 1], [14, 1],
    ];
  }

  Future<List<Review>> _getDeckReviews(int deckId) async {
    // This would fetch reviews for all cards in the deck
    return [];
  }

  Future<List<Review>> _getSessionReviews(String sessionId) async {
    // This would fetch reviews for the specific session
    return [];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(Session session) {
    final duration = session.endTime != null 
        ? session.endTime!.difference(session.startTime)
        : Duration.zero;
    final minutes = duration.inMinutes;
    return '$minutes min';
  }
}
