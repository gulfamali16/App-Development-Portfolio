import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(LudoFunApp());

class LudoFunApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo Fun!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: LudoHomePage(),
    );
  }
}

class Player {
  String name;
  int score;
  Player({required this.name, this.score = 0});
}

class LudoHomePage extends StatefulWidget {
  @override
  _LudoHomePageState createState() => _LudoHomePageState();
}

class _LudoHomePageState extends State<LudoHomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roundsController = TextEditingController();
  final List<Player> _players = [];
  int _currentPlayerIndex = 0;
  int _diceValue = 1;
  final Random _rng = Random();

  // Rounds
  int _totalRounds = 1;
  int _currentRound = 1;

  // Rotation
  double _rotationTurns = 0;

  // Winner text
  String _winnerText = "";

  // Add player
  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _players.length >= 4) return;
    setState(() {
      _players.add(Player(name: name));
      _nameController.clear();
    });
  }

  // Set total rounds
  void _setRounds() {
    final rounds = int.tryParse(_roundsController.text);
    if (rounds != null && rounds > 0) {
      setState(() {
        _totalRounds = rounds;
        _roundsController.clear();
      });
    }
  }

  // Reset game
  void _resetGame() {
    setState(() {
      _players.clear();
      _currentPlayerIndex = 0;
      _diceValue = 1;
      _rotationTurns = 0;
      _totalRounds = 1;
      _currentRound = 1;
      _winnerText = "";
      _nameController.clear();
      _roundsController.clear();
    });
  }

// Roll dice
  void _rollDice() {
    if (_players.isEmpty || _currentRound > _totalRounds) return;

    final roll = _rng.nextInt(6) + 1;

    setState(() {
      _diceValue = roll;
      _players[_currentPlayerIndex].score += roll;

      // Map dice value to a fixed rotation
      // Each face gets a unique rotation (in turns: 1 turn = 360 degrees)
      final faceRotations = {
        1: 0.0,
        2: 0.25,
        3: 0.5,
        4: 0.75,
        5: 1.0,
        6: 1.25,
      };
      _rotationTurns = faceRotations[roll]!;

      // Update player and round
      _currentPlayerIndex++;
      if (_currentPlayerIndex >= _players.length) {
        _currentPlayerIndex = 0;
        _currentRound++;
      }

      if (_currentRound > _totalRounds) {
        _showWinner();
      } else {
        _winnerText = "";
      }
    });
  }

  // Show winner and reset dice
  void _showWinner() {
    Player winner = _players[0];
    for (var p in _players) {
      if (p.score > winner.score) winner = p;
    }

    setState(() {
      _winnerText = "🏆 Winner: ${winner.name} (Score: ${winner.score})";
      _diceValue = 1; // reset dice
    });
  }

  Color _scoreColor(int idx) {
    final colors = [
      Color(0xFFEF6C6C),
      Color(0xFF6C8AEF),
      Color(0xFF59C36A),
      Color(0xFFF5C54A),
    ];
    return idx < colors.length ? colors[idx] : Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF7F00FF),
        Color(0xFFB4006E),
        Color(0xFFFFA451),
      ],
      stops: [0.0, 0.45, 1.0],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Ludo Fun!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: _resetGame,
                      icon: Icon(Icons.restart_alt, color: Colors.white, size: 28),
                      tooltip: 'Restart Game',
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Add Player Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Player Name', style: TextStyle(color: Colors.white70)),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter player name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addPlayer,
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text('Add Player', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Color(0xFF6E2BD8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Set Rounds Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Total Rounds', style: TextStyle(color: Colors.white70)),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _roundsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter total rounds',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _setRounds,
                          icon: Icon(Icons.format_list_numbered, color: Colors.white),
                          label: Text('Set Rounds', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Color(0xFF6E2BD8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 22),

                // Round & Player Turn + Winner Text + Dice
                Column(
                  children: [
                    // Default instruction
                    if (_players.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          "Add players and set rounds to start!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70),
                        ),
                      ),

                    // Player Turn / Round
                    if (_players.isNotEmpty && _currentRound <= _totalRounds)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          "Round $_currentRound of $_totalRounds\n${_players[_currentPlayerIndex].name}'s Turn!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  blurRadius: 6,
                                  color: Colors.black26,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      ),

                    // Winner Text
                    if (_winnerText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _winnerText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellowAccent,
                            shadows: [
                              Shadow(
                                  blurRadius: 4,
                                  color: Colors.black38,
                                  offset: Offset(0, 2))
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 20),

                    // Dice Centered
                    Center(
                      child: GestureDetector(
                        onTap: _rollDice,
                        child: AnimatedRotation(
                          turns: _rotationTurns,
                          duration: Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                    offset: Offset(0, 4))
                              ],
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Image.asset(
                              'assets/dice$_diceValue.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 18),

                    // Roll Dice Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _rollDice,
                        icon: Icon(Icons.casino, color: Colors.purple),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          child: Text('Roll Dice', style: TextStyle(fontSize: 16, color: Colors.purple)),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          side: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 18),

                // Scoreboard
                if (_players.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text('Scoreboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 12),
                        Column(
                          children: List.generate(_players.length, (index) {
                            final p = _players[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _scoreColor(index),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  title: Text(p.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  trailing: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                                    child: Text('${p.score}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}