import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WH40K Match Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey.shade900,
          brightness: Brightness.dark,
        ).copyWith(surface: Colors.black),
      ),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;

  static const List<String> _tabLabels = [
    'Match',
    'Historique',
    'Joueurs',
    'Room',
  ];

  static const List<IconData> _tabIcons = [
    Icons.sports_esports,
    Icons.history,
    Icons.people,
    Icons.meeting_room,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('${_tabLabels[_currentIndex]} — coming soon')),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: List.generate(
          _tabLabels.length,
          (i) => BottomNavigationBarItem(
            icon: Icon(_tabIcons[i]),
            label: _tabLabels[i],
          ),
        ),
      ),
    );
  }
}
