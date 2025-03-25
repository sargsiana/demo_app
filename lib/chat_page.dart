import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // 👈 Added
  List<Map<String, String>> messages = [];
  bool isTyping = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  Future<void> _getUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _loadChatHistory();
    }
  }

  Future<void> _loadChatHistory() async {
    if (userId == null) return;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore
        .collection("chats")
        .doc(userId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .get();

    setState(() {
      messages = snapshot.docs.map((doc) => {
                "role": doc["role"] as String,
                "content": doc["content"] as String,
              }).toList();
    });

    _scrollToBottom(); // 👈 Scroll after loading history
  }

  Future<void> _saveMessage(String role, String content) async {
    if (userId == null) return;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection("chats").doc(userId).collection("messages").add({
      "role": role,
      "content": content,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || userId == null) return;

    setState(() {
      messages.add({"role": "user", "content": message});
      isTyping = true;
    });
    _scrollToBottom(); // 👈 Scroll after user message

    _controller.clear();
    await _saveMessage("user", message);

    setState(() {
      messages.add({"role": "bot", "content": ""});
    });
    _scrollToBottom(); // 👈 Scroll after bot placeholder

    final request = http.Request(
      'POST',
      Uri.parse('https://9d88-93-229-96-179.ngrok-free.app/api/generate'),
    )
      ..headers["Content-Type"] = "application/json"
      ..body = jsonEncode({
        "model": "mistral:instruct",
        "prompt": "You are a mental health assistant trained on evidence-based psychology. "
            "You should provide clear, concise, supportive, and scientifically-backed responses. If needed, you can ask for more information. Advice should not be too long, keep it short and simple. "
            "Respond only to the user's prompts.\n\nUser: $message\nAssistant:",
        "stream": true
      });

    final streamedResponse = await http.Client().send(request);
    StringBuffer botResponse = StringBuffer();

    streamedResponse.stream
        .transform(utf8.decoder)
        .listen((chunk) {
      try {
        final jsonChunk = jsonDecode(chunk);
        final text = jsonChunk["response"] ?? "";

        setState(() {
          botResponse.write(text);
          messages.last["content"] = botResponse.toString();
        });
        _scrollToBottom(); // 👈 Scroll while bot is typing
      } catch (e) {
        if (kDebugMode) {
          print("Error parsing chunk: $e");
        }
      }
    }, onDone: () async {
      await _saveMessage("bot", botResponse.toString());
      setState(() {
        isTyping = false;
      });
    });
  }

  void _scrollToBottom() {
  Future.delayed(Duration(milliseconds: 100), () {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}


  Future<void> _clearChatHistory() async {
    if (userId == null) return;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection("chats")
        .doc(userId)
        .collection("messages")
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    setState(() {
      messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Mental Health Chatbot", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 25, 113, 245),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: _clearChatHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // 👈 Attach scroll controller
              itemCount: messages.length,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: isUser ? Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg["content"] ?? "",
                      style: GoogleFonts.poppins(fontSize: 16, color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.android, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Bot is typing...",
                    style: GoogleFonts.poppins(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (value) => sendMessage(value),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  backgroundColor: Colors.blueAccent,
                  elevation: 3,
                  onPressed: () => sendMessage(_controller.text),
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
