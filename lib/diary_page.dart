import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  DiaryPageState createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage> {
  final TextEditingController _diaryController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isSaving = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  Future<void> _saveDiaryEntry() async {
    if (_user == null) {
      _showSnackbar("You must be logged in to save entries.", Colors.redAccent);
      return;
    }

    if (_diaryController.text.trim().isEmpty) {
      _showSnackbar("Diary entry cannot be empty.", Colors.orangeAccent);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection("diary_entries").add({
        "user_id": _user!.uid,
        "text": _diaryController.text.trim(),
        "timestamp": DateTime.now(),
      });

      _diaryController.clear();
      _showSnackbar("Diary entry saved!", Colors.greenAccent);
    } catch (e) {
      _showSnackbar("Error saving entry: $e", Colors.redAccent);
    }

    setState(() {
      _isSaving = false;
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text(
            "Please log in to view diary entries.",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Diary", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDiaryInputField(),
          ),
          _isSaving
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _saveDiaryEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text("Save Entry", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                ),
          Expanded(child: DiaryEntriesList(user: _user!)),
        ],
      ),
    );
  }

  /// ✅ Custom TextField for Diary Input
  Widget _buildDiaryInputField() {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {});
      },
      child: TextField(
        controller: _diaryController,
        focusNode: _focusNode,
        maxLines: 5,
        style: GoogleFonts.poppins(fontSize: 16),
        decoration: InputDecoration(
          labelText: "Write your diary entry...",
          labelStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900] // Dark mode improved contrast
              : Colors.white,
          contentPadding: EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none, // 🔥 Removes purple focus border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
        ),
      ),
    );
  }
}

/// ✅ Diary Entries List with Improved UI
class DiaryEntriesList extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User user;

  DiaryEntriesList({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("diary_entries")
          .where("user_id", isEqualTo: user.uid)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error loading entries: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No diary entries yet. Add your first entry!",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final entries = snapshot.data!.docs;

        return ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final doc = entries[index];
            final data = doc.data() as Map<String, dynamic>;

            String formattedTime = "No timestamp";
            if (data["timestamp"] != null) {
              final timestamp = data["timestamp"] as Timestamp;
              final date = timestamp.toDate();
              formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
            }

            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await _confirmDelete(context, doc.id);
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(data["text"] ?? "No entry", style: GoogleFonts.poppins(fontSize: 16)),
                  subtitle: Text('Added on: $formattedTime', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, doc.id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ Confirm Deletion Dialog
  Future<bool?> _confirmDelete(BuildContext context, String docId) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Entry?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete this entry?", style: GoogleFonts.poppins()),
        actions: [
  TextButton(
    onPressed: () => Navigator.pop(context, false), // ❌ cancel deletion
    child: Text("Cancel"),
  ),
  TextButton(
    onPressed: () {
      _deleteEntry(docId); // ✅ delete
      Navigator.pop(context, true); // ✅ close dialog after confirming
    },
    child: Text("Delete", style: TextStyle(color: Colors.red)),
  ),
],
      ),
    );
  }

  // ✅ Delete entry by document ID
  void _deleteEntry(String docId) {
    _firestore.collection("diary_entries").doc(docId).delete();
  }
}
