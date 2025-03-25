import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'diary_page.dart';
import 'health_check.dart';
import 'chat_page.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
     await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDg3GS3ffUbqG3VOEx4vFj-B36XbpUlGpM",
        appId: "1:914472534202:ios:c4b63556a8ae7339d74283",
        messagingSenderId: "914472534202",
        projectId: "ki4c-773ce",
        storageBucket: "ki4c-773ce.appspot.com",
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KI4C',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 25, 113, 245),
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          color: Color.fromARGB(255, 25, 113, 245),
          elevation: 2,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey[900],
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          color: Colors.blueGrey[900],
          elevation: 2,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white
          ),
        ),
      ),
      themeMode: ThemeMode.system, // Auto switch between light and dark mode
      home: SplashScreen(), // 👈 Show splash screen before checking auth
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/diary': (context) => DiaryPage(),
        '/health_check': (context) => HealthCheckPage(),
        '/chat': (context) => ChatPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}

// ✅ Splash Screen with Animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => AuthWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 25, 113, 245),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "KI4C Chatbot",
              style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Wrapper to check if user is logged in
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color.fromARGB(255, 25, 113, 245)),
                  SizedBox(height: 20),
                  Text(
                    "Loading...",
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          return HomePage();
        }
        return LoginPage();
      },
    );
  }
}
