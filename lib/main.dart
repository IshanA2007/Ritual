import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

Future<void> clearSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // await prefs.clear();
  prefs.setBool("completed_today", false);
  print("SharedPreferences cleared (selectively)!"); // Debugging
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartScreen(),
    );
  }
}

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool isCompleted = false;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    clearSharedPreferences();
    checkIfCompleted();
    loadStreak();
  }

  Future<void> checkIfCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isCompleted = prefs.getBool("completed_today") ?? false;
    });
  }

  Future<void> loadStreak() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime today = DateTime.now();
    String? lastDateString = prefs.getString("last_completion_date");
    DateTime? lastCompletedDate = lastDateString != null ? DateTime.parse(lastDateString) : null;

    int storedStreak = prefs.getInt("streak") ?? 1;

    if (lastCompletedDate == null) {
      streak = 1; // First time running the app, no previous date
    } else {
      Duration difference = today.difference(lastCompletedDate);
      if (difference.inDays == 0) {
        streak = storedStreak; // Keep streak same if already completed today
      } else if (difference.inDays == 1) {
        streak = storedStreak + 1; // Increment streak for consecutive days
      } else {
        streak = 1; // Reset streak if skipped a day
      }
    }

    await prefs.setInt("streak", streak);
    await prefs.setString("last_completion_date", today.toIso8601String());
    setState(() {});
  }

  void markAsCompleted() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  DateTime today = DateTime.now();
  String? lastDateString = prefs.getString("last_completion_date");
  DateTime? lastCompletedDate = lastDateString != null ? DateTime.parse(lastDateString) : null;

  int streak = prefs.getInt("streak") ?? 0;

  if (lastCompletedDate == null || today.difference(lastCompletedDate).inDays > 1) {
    streak = 1;  // ✅ Start at 1 if it's the first completion or a reset
  } else if (today.difference(lastCompletedDate).inDays == 1) {
    streak += 1; // ✅ Increment for consecutive days
  }
  else{
    print("<1 day - for testing i will allow it.");
    streak += 1;
  }

  await prefs.setBool("completed_today", true);
  await prefs.setInt("streak", streak);
  await prefs.setString("last_completion_date", today.toIso8601String());

  setState(() {
    isCompleted = true;
    this.streak = streak;  // ✅ Force UI refresh with the new streak value
  });

  print("🔥 Streak updated to: $streak"); // Debugging
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFD3A5), Color(0xFFFD6585)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Come back tomorrow!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Streak: $streak",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Start Your Ritual",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MeditationScreen(onDone: markAsCompleted)),
                          );
                        },
                        child: Text("Start"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class MeditationScreen extends StatefulWidget {
  final VoidCallback onDone;
  MeditationScreen({required this.onDone});

  @override
  _MeditationScreenState createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  int countdown = 10; // 3 minutes in seconds
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startMeditation();
  }

  void startMeditation() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JournalScreen(onDone: widget.onDone)),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Breathe... ${countdown}s left",
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}

class JournalScreen extends StatefulWidget {
  final VoidCallback onDone;
  JournalScreen({required this.onDone});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  TextEditingController _controller = TextEditingController();

  void submitHappiness() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> happinessLogs = prefs.getStringList("happiness_logs") ?? [];
    happinessLogs.add(_controller.text);
    await prefs.setStringList("happiness_logs", happinessLogs);

    // Move to the past entries screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PastEntriesScreen(onDone: widget.onDone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "What made you happy today?",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: submitHappiness,
              child: Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}

class ChecklistScreen extends StatefulWidget {
  final VoidCallback onDone;
  ChecklistScreen({required this.onDone});

  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  List<String> checklistItems = [
    "Compliment someone",
    "Helped a friend",
    "Took a mindful break",
    "Expressed gratitude",
    "Did something creative",
  ];

  List<bool> checkedItems = List.filled(5, false); // Five checkboxes

  @override
  void initState() {
    super.initState();
  }

  // Marks session as complete and navigates back
  void completeSession(BuildContext context) async {
    widget.onDone();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Did you do something kind today?",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            SizedBox(height: 20),

            // Checkbox List
            Column(
              children: List.generate(checklistItems.length, (index) {
                return CheckboxListTile(
                  title: Text(
                    checklistItems[index],
                    style: TextStyle(color: Colors.white),
                  ),
                  value: checkedItems[index],
                  onChanged: (value) {
                    setState(() {
                      checkedItems[index] = value ?? false;
                    });
                  },
                  activeColor: Colors.brown,
                  checkColor: Colors.white,
                );
              }),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => completeSession(context),
              child: Text("Finish"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PastEntriesScreen extends StatefulWidget {
  final VoidCallback onDone;
  PastEntriesScreen({required this.onDone});

  @override
  _PastEntriesScreenState createState() => _PastEntriesScreenState();
}

class _PastEntriesScreenState extends State<PastEntriesScreen> {
  List<String> happinessLogs = [];

  @override
  void initState() {
    super.initState();
    loadHappinessLogs();
  }

  Future<void> loadHappinessLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      happinessLogs = prefs.getStringList("happiness_logs") ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100),
            Text(
              "Past Happy Moments",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: happinessLogs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      happinessLogs[index],
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChecklistScreen(onDone: widget.onDone)),
                );
              },
              child: Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}