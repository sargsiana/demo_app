import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(user!.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return Center(child: Text("No profile data found."));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildProfileCard(
                title: "Full Name",
                content: "${data['first_name']} ${data['last_name']}",
                icon: Icons.person,
              ),
              _buildProfileCard(
                title: "Username",
                content: data['username'] ?? "-",
                icon: Icons.alternate_email,
              ),
              _buildProfileCard(
                title: "Birthdate",
                content: data['birthdate']?.toString().split("T").first ?? "-",
                icon: Icons.cake,
              ),
              _buildProfileCard(
                title: "Joined",
                content: data['created_at']?.toDate().toString().split(".").first ?? "-",
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.edit, color:Colors.white),
                label: Text("Edit Profile", style: GoogleFonts.poppins(color:Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // 🔧 Navigate to edit screen or show dialog
                },
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard({required String title, required String content, required IconData icon}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text(content, style: GoogleFonts.poppins(fontSize: 16)),
      ),
    );
  }
}
