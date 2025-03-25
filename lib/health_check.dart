import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthCheckPage extends StatefulWidget {
  const HealthCheckPage({super.key});

  @override
  HealthCheckPageState createState() => HealthCheckPageState();
}

class HealthCheckPageState extends State<HealthCheckPage> {
  int _currentIndex = 0;
  bool _submitted = false;
  List<String>? _responseData;

  final List<String> _options = [
    'sehr schwierig',
    'eher schwierig',
    'eher einfach',
    'sehr einfach',
  ];

  final List<String> _questions = [
    '1. Informationen zu Sicherheit und Gesundheit am Arbeitsplatz in verständlicher Sprache zu finden?',
    '2. Zu beurteilen, wann meine Arbeit schlechte Auswirkungen auf meine Gesundheit und mein Wohlbefinden hat?',
    '3. Hinweise zu Sicherheit und Gesundheit am Arbeitsplatz zu verstehen?',
    '4. Bei gesundheitlich belastenden Arbeitssituationen tatkräftig Lösungen umzusetzen?',
    '5. Die Arbeitsbedingungen mit anderen zu verändern, dass sie sich positiv auf Gesundheit auswirken?',
    '6. bei der Arbeit mit Anderen über Risiken für Gesundheit und Wohlbefinden zu sprechen?',
    '7. einzuschätzen, welche Angebote zur Förderung der Gesundheit am Arbeitsplatz für mich passend sind?',
    '8. Informationen über Gesundheitsrisiken, die mich am Arbeitsplatz betreffen, selbst zu finden?',
  ];

  final Map<String, String?> _responses = {
    'Q1': null,
    'Q2': null,
    'Q3': null,
    'Q4': null,
    'Q5': null,
    'Q6': null,
    'Q7': null,
    'Q8': null,
  };

  /// ✅ Save processed health profile to Firestore after receiving from R script
  void _saveToFirestore(String healthProfile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('user_permissions').doc(user.uid).set({
        'health_check_passed': true,
        'health_profile': healthProfile,
      });

      if (kDebugMode) {
        print("✅ Health check saved in Firestore!");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error saving health check: $e");
      }
    }
  }

  Future<void> _submitSurvey() async {
    if (_responses.values.any((response) => response == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte beantworten Sie alle Fragen!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final List<int> scores = _responses.values.map((response) {
      switch (response) {
        case 'sehr schwierig':
          return 1;
        case 'eher schwierig':
          return 2;
        case 'eher einfach':
          return 3;
        case 'sehr einfach':
          return 4;
        default:
          return 0;
      }
    }).toList();

    final surveyData = {"score": scores};

    try {
      final url = Uri.parse('https://9d88-93-229-96-179.ngrok-free.app/process_survey'); // 🔹 R script API endpoint
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(surveyData),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final healthProfile = responseData.isNotEmpty ? responseData[0] : "Unbekannt";

        setState(() {
          _responseData = List<String>.from(responseData);
          _submitted = true;
        });

        _saveToFirestore(healthProfile); // 🔹 Save profile from R script response
      } else {
        if (kDebugMode) {
          print("Server error: ${response.statusCode} ${response.reasonPhrase}");
        }
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
      // Check if widget is still mounted before showing SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler bei der Verbindung zum Server.')),
        );
      }
    }
  }

  Widget _buildQuestion() {
    final questionKey = 'Q${_currentIndex + 1}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _questions[_currentIndex],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ..._options.map((option) {
          return RadioListTile(
            title: Text(option),
            value: option,
            groupValue: _responses[questionKey],
            onChanged: (String? value) {
              setState(() {
                _responses[questionKey] = value;
                if (_currentIndex < _questions.length - 1) {
                  _currentIndex++;
                } else {
                  _submitSurvey();
                }
              });
            },
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arbeitsbezogene Gesundheitskompetenz'),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
            minHeight: 8.0,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _submitted
                  ? _buildResponseDisplay(context) // ✅ Pass context for navigation
                  : _buildQuestion(),
            ),
          ),
          
        ],
      ),
    );
  }

  /// ✅ Display processed response from R script with "Back to Home" button
 Widget _buildResponseDisplay(BuildContext context) {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Vielen Dank für Ihre Teilnahme!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Ihre Ergebnisse:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // ✅ Display the responses in a list format with better spacing
          Column(
            children: _responseData!.map((response) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Sie verfügen über eine $response Gesundheitskompetenz.',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),

          // ✅ Larger and properly spaced image
          Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: 300, // limits width
      maxHeight: 300, // limits height
    ),
    child: Image.asset(
      'assets/OHL.png',
      fit: BoxFit.contain,
    ),
  ),
),


          const SizedBox(height: 30),

          // ✅ Constrain text width to improve readability
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), // Limit text width
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Es ist wichtig, dass wir mit Informationen zu Sicherheit und Gesundheit bei der Arbeit umgehen können. "
                "Wir sollten Informationen finden, verstehen und beurteilen können. Dazu ist es hilfreich, wenn die "
                "Informationen schnell und einfach, in einer für uns verständlichen Sprache vorliegen. Das erleichtert "
                "diese zu finden, einzuschätzen und zu bewerten.",
                style: TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.justify, // Improve text readability
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ✅ "Back to Home" Button
          ElevatedButton.icon(
            icon: const Icon(Icons.home),
            label: const Text("Zurück zur Startseite"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home'); // ✅ Navigate to Home Page
            },
          ),
        ],
      ),
    ),
  );
}


}
