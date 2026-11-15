import 'hub.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBdqfBIIMukCOKbweMcKr_6nQeD9DCEN5k",
      appId: "1:740746545542:web:3968f4b62f3ad6857e8407",
      messagingSenderId: "740746545542",
      projectId: "systems-82249",
      storageBucket: "systems-82249.firebasestorage.app",
    ),
  );
  runApp(const TF141App());
}

class TF141App extends StatelessWidget {
  const TF141App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TASK FORCE 141',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD0D8E0),
          secondary: Color(0xFF00F0FF),
        ),
      ),
      home: const MetallicSpinBootScreen(),
    );
  }
}

class MetallicSpinBootScreen extends StatefulWidget {
  const MetallicSpinBootScreen({super.key});

  @override
  State<MetallicSpinBootScreen> createState() => _MetallicSpinBootScreenState();
}

class _MetallicSpinBootScreenState extends State<MetallicSpinBootScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  bool _showKeypad = false;
  String _pin = "";
  String _errorMsg = "";
  final String _passcode = "1410";

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _showKeypad = true);
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    HapticFeedback.heavyImpact();
    setState(() {
      _errorMsg = "";
      if (key == "CLR") {
        _pin = "";
      } else if (_pin.length < 4 && key != "OK") {
        _pin += key;
      }

      if (_pin.length == 4) {
        if (_pin == _passcode) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OperatorSetupScreen()),
          );
        } else {
          _errorMsg = "ACCESS DENIED";
          _pin = "";
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: CustomPaint(
              size: const Size(260, 260),
              painter: HexMeshSpotlightPainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _spinController,
                    builder: (_, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateY(_spinController.value * 2 * math.pi),
                        child: child,
                      );
                    },
                    child: CustomPaint(
                      size: const Size(155, 155),
                      painter: TF141MedallionPainter(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "TASK FORCE 141",
                    style: TextStyle(
                      color: Color(0xFFE2E6EA),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (_showKeypad) ...[
                    Text(
                      _errorMsg.isEmpty ? "ENTER ACCESS CODE" : _errorMsg,
                      style: TextStyle(
                        color: _errorMsg.isEmpty
                            ? const Color(0xFF8A99A8)
                            : const Color(0xFFFF3B30),
                        fontSize: 12,
                        letterSpacing: 3,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: i < _pin.length
                                ? const Color(0xFFD0D8E0)
                                : Colors.transparent,
                            border: Border.all(
                              color: const Color(0xFF5A6875),
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 245,
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.55,
                        children: [
                          "1", "2", "3",
                          "4", "5", "6",
                          "7", "8", "9",
                          "CLR", "0", "OK"
                        ].map((k) {
                          return OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD0D8E0),
                              backgroundColor: const Color(0xFF0D1014),
                              side: const BorderSide(color: Color(0xFF2B343E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () => _onKeyTap(k),
                            child: Text(
                              k,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OperatorSetupScreen extends StatefulWidget {
  const OperatorSetupScreen({super.key});

  @override
  State<OperatorSetupScreen> createState() => _OperatorSetupScreenState();
}

class _OperatorSetupScreenState extends State<OperatorSetupScreen> {
  String _selectedSlot = "ALPHA-1";
  final TextEditingController _callsignController =
      TextEditingController(text: "GHOST");
  String _status = "IN POSITION";

  final List<String> _slots = ["ALPHA-1", "BRAVO-2", "CHARLIE-3", "DELTA-4"];
  final List<String> _statuses = [
    "IN POSITION",
    "MOVING",
    "ENGAGED",
    "OVERWATCH"
  ];

  void _deploy() {
    final callsign = _callsignController.text.trim().isEmpty
        ? _selectedSlot
        : _callsignController.text.trim().toUpperCase();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TacticalCommandHub(
          slotId: _selectedSlot,
          callsign: callsign,
          initialStatus: _status,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0D10),
        title: const Text(
          "SQUAD DEPLOYMENT // 4-UNIT LINK",
          style: TextStyle(fontFamily: 'monospace', fontSize: 14, letterSpacing: 2),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SELECT UNIT SLOT (1-4):",
                    style: TextStyle(color: Color(0xFF8A99A8), fontFamily: 'monospace')),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _slots.map((slot) {
                    final active = _selectedSlot == slot;
                    return ChoiceChip(
                      
