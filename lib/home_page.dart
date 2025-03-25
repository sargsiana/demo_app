import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("user_permissions")
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var userData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};
        bool healthCheckPassed = userData["health_check_passed"] ?? false;
        String healthProfile = userData["health_profile"] ??
            "Please complete the health check";

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text("KI4C Home",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            backgroundColor: Theme.of(context).primaryColor,
            centerTitle: true,
            elevation: 2,
          ),
          drawer: _buildDrawer(context),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome to KI4C!",
                      style: GoogleFonts.poppins(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Your recent activity:",
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.black54)),
                  SizedBox(height: 20),
                  _buildDashboard(context),
                  SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Your Health Profile",
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text(healthProfile,
                              style: GoogleFonts.poppins(
                                  fontSize: 16, color: Colors.black87)),
                          if (healthCheckPassed) ...[
                            SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _showFeedbackDialog(context),
                              child: Text(
                                "See your feedback",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text("Explore different features:",
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.black54)),
                  SizedBox(height: 10),
                  _buildFeatureCard(
                    context,
                    icon: Icons.book,
                    title: "Diary",
                    description: "Write about your day.",
                    route: '/diary',
                  ),
                  healthCheckPassed
                      ? _buildDisabledFeatureCard(
                          icon: Icons.favorite,
                          title: "Health Check",
                          description: "Already completed")
                      : _buildFeatureCard(
                          context,
                          icon: Icons.favorite,
                          title: "Health Check",
                          description: "Monitor your mental health.",
                          route: '/health_check',
                        ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.chat,
                    title: "Chat",
                    description: "Talk to the health assistant.",
                    route: '/chat',
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Your Feedback",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Image.asset('assets/OHL.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              Text(
                "Es ist wichtig, dass wir mit Informationen zu Sicherheit und Gesundheit bei der Arbeit umgehen können. "
                "Wir sollten Informationen finden, verstehen und beurteilen können. Dazu ist es hilfreich, wenn die Informationen "
                "schnell und einfach, in einer für uns verständlichen Sprache vorliegen. Das erleichtert diese zu finden, "
                "einzuschätzen und zu bewerten.",
                style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Activity Summary",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            SizedBox(height: 200, child: _buildStepsChart(context)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Steps Today", "8,450", Icons.directions_walk,
                    Colors.blueAccent),
                _buildStatCard("Mood Score", "7.5/10",
                    Icons.emoji_emotions, Colors.orangeAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsChart(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: List.generate(
            7, (index) => _buildBarData(index, (4000 + (index * 500)).toDouble())),
        titlesData: FlTitlesData(
          leftTitles: SideTitles(showTitles: true, reservedSize: 30),
          bottomTitles: SideTitles(
            showTitles: true,
            getTitles: (value) {
              const days = ["M", "T", "W", "T", "F", "S", "S"];
              return days[value.toInt()];
            },
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  BarChartGroupData _buildBarData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          y: y,
          colors: [Colors.blueAccent],
          width: 16,
          borderRadius: BorderRadius.circular(6),
        )
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String description,
      required String route}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        title: Text(title,
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: GoogleFonts.poppins(fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildDisabledFeatureCard(
      {required IconData icon,
      required String title,
      required String description}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: EdgeInsets.only(bottom: 10),
      color: Colors.grey[100],
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.grey),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        subtitle:
            Text(description, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
        trailing: Icon(Icons.check_circle, size: 16, color: Colors.green),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('KI4C App',
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('Health Management',
                    style:
                        GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Add settings route if needed
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(value,
              style:
                  GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
