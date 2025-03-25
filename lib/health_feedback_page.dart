import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthFeedbackPage extends StatelessWidget {
  final String healthProfile;

  const HealthFeedbackPage({super.key, required this.healthProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Health Feedback", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Your Health Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            Text(
              "• Sie verfügen über eine $healthProfile Gesundheitskompetenz.",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Center(
              child: Image.asset(
                'assets/OHL.png',
                height: 250,
                width: 250,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text("Back to Home"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
