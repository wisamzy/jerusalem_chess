import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/game_provider.dart';
import '../providers/theme_language_provider.dart';
import '../providers/authentication_provider.dart';
import '../helper/helper_methods.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  late ThemeLanguageProvider _themeLanguageProvider;
  Map<String, dynamic> translations = {};
  List<Map<String, dynamic>> gameHistory = [];
  bool isLoading = true;
  int initialWins = 0;
  int initialLosses = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _themeLanguageProvider = Provider.of<ThemeLanguageProvider>(context);
    loadTranslations(_themeLanguageProvider.currentLanguage).then((value) {
      if (mounted) {
        setState(() {
          translations = value;
        });
      }
    });

    // Fetch initial wins and losses and then fetch game history
    fetchInitialWinsAndLosses().then((_) {
      fetchGameHistory();
    });
  }

  Future<void> fetchInitialWinsAndLosses() async {
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    final userModel = authProvider.userModel;

    if (userModel != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userModel.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          initialWins = userDoc['wins'] ?? 0;
          initialLosses = userDoc['losses'] ?? 0;
        });
      }
    }
  }

  void reloadTranslations(String language) {
    loadTranslations(language).then((value) {
      if (mounted) {
        setState(() {
          translations = value;
        });
      }
    });
  }

  Future<void> fetchGameHistory() async {
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    final userModel = authProvider.userModel;

    if (userModel != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userModel.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          gameHistory = List<Map<String, dynamic>>.from(userDoc['gameHistory'] ?? []);
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final textColor = _themeLanguageProvider.isLightMode ? Colors.black : Colors.white;
    final backgroundColor = _themeLanguageProvider.isLightMode ? Colors.white : const Color(0xFF121212);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xff4e3c96),
        title: Text(getTranslation('gameHistory', translations),
            style: const TextStyle(color: Colors.white, fontFamily: 'IBM Plex Sans Arabic', fontWeight: FontWeight.w700)),
        actions: [
          // Dark mode toggle button
          IconButton(
            icon: Icon(_themeLanguageProvider.isLightMode ? Icons.light_mode : Icons.dark_mode),
            color: _themeLanguageProvider.isLightMode ? const Color(0xfff0c230) : const Color(0xfff0f5f7),
            onPressed: _themeLanguageProvider.toggleThemeMode,
          ),
          // Language change button
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (String selectedLanguage) {
              _themeLanguageProvider.changeLanguage(selectedLanguage);
              reloadTranslations(selectedLanguage);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'Arabic',
                child: Text('العربية'),
              ),
              const PopupMenuItem<String>(
                value: 'English',
                child: Text('English'),
              ),
            ],
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          if (isLoading) {
            return Center(child: CircularProgressIndicator());
          } else {
            if (gameProvider.showAnalysisBoard) {
              return ListView.builder(
                itemCount: gameProvider.moveHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(gameProvider.moveHistory[index], style: TextStyle(color: textColor)),
                  );
                },
              );
            } else {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Table(
                    border: TableBorder.all(color: const Color(0xff4e3c96), width: 3),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(4),
                      2: FlexColumnWidth(2), // Added this line for the W/L column
                    },
                    children: [
                      TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Ops', style: TextStyle(color: textColor,
                                  fontFamily: 'IBM Plex Sans Arabic',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Moves', style: TextStyle(color: textColor,
                                  fontFamily: 'IBM Plex Sans Arabic',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('W/L', style: TextStyle(color: textColor,
                                  fontFamily: 'IBM Plex Sans Arabic',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22)), // Added this line
                            ),
                          ),
                        ],
                      ),
                      ...gameHistory.map((game) {
                        final opponentName = game['opponentName'] ?? 'Unknown';
                        final moves = game['moves']?.join(', ') ?? 'No moves';
                        final userDoc = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
                        final currentWins = userDoc?.wins ?? 0;
                        final currentLosses = userDoc?.losses ?? 0;

                        String result;
                        if (currentLosses > initialLosses && currentWins == initialWins) {
                          result = 'L';
                        } else if (currentWins > initialWins && currentLosses == initialLosses) {
                          result = 'W';
                        } else {
                          result = '-';
                        }

                        return TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(opponentName, style: TextStyle(
                                    color: textColor,
                                    fontFamily: 'IBM Plex Sans Arabic',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18)),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(moves, style: TextStyle(color: textColor,
                                    fontFamily: 'IBM Plex Sans Arabic',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18)),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(result, style: TextStyle(color: textColor,
                                    fontFamily: 'IBM Plex Sans Arabic',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18)), // Added this line
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
