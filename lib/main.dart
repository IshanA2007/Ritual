import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}
Future<void> clearSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  print("SharedPreferences cleared!"); // Debugging
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

  @override
  void initState() {
    super.initState();
    clearSharedPreferences();
    checkIfCompleted();
  }

  Future<void> checkIfCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isCompleted = prefs.getBool("completed_today") ?? false;
    });
  }

  void markAsCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("completed_today", true);
    setState(() {
      isCompleted = true;
    });
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
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Start Your Happiness Loop",
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

  void submitHappiness() {
    print("User wrote: ${_controller.text}"); // This can be sent to Firebase
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChecklistScreen(onDone: widget.onDone)),
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
    loadCheckedItems();
  }

  // Load stored checkbox states
  Future<void> loadCheckedItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      checkedItems = List.generate(checklistItems.length,
          (index) => prefs.getBool('checkbox_$index') ?? false);
    });
  }

  // Save checkbox states
  Future<void> saveCheckedItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < checkedItems.length; i++) {
      prefs.setBool('checkbox_$i', checkedItems[i]);
    }
  }

  // Marks session as complete and navigates back
  void completeSession(BuildContext context) async {
    await saveCheckedItems();
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
                      saveCheckedItems(); // Save state instantly
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