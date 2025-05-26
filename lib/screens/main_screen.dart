import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/session_provider.dart';
import '../presentation/pages/deck_page.dart';
import '../presentation/pages/add_card_page.dart';
import '../presentation/pages/review_page.dart';
import '../presentation/pages/stats_page.dart';
import '../presentation/pages/manage_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DeckPage(),
    const AddCardPage(),
    const ManagePage(),
    const StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        // If there's an active session, show the review page
        if (sessionProvider.isReviewActive) {
          return const ReviewPage();
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF373737),
            selectedItemColor: const Color(0xFF2496DC),
            unselectedItemColor: Colors.grey,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.library_books),
                label: 'Decks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_card),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.manage_accounts),
                label: 'Manage',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Stats',
              ),
            ],
          ),
        );
      },
    );
  }
}
