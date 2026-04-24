import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:abacus/cache.dart';
import 'namescreen.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();

  String _verificationId = "";
  Timer? _timer;

  int _secondsRemaining = 60;
  bool _canResend = false;

  int _resendCount = 0;
  static const int _maxResend = 3;

  // ================= DEBUG SYSTEM =================

  String _debugLog = "";
  final bool _showDebug = true;

  void _log(String message) {
    final time = DateTime.now().toIso8601String();
    setState(() {
      _debugLog += "\n[$time] $message";
    });
    print(message);
  }

  // =================================================

  @override
  void initState() {
    super.initState();
    _log("🟢 OTP Screen Opened");
    _silentLoginCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // ================= SILENT LOGIN =================

  Future<void> _silentLoginCheck() async {
    _log("🔍 Checking existing Firebase user...");

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        _log("✅ User already logged in: ${user.uid}");

        await _saveUid(user.uid);
        _log("✅ UID saved locally");

        await _createUserIfNotExists(user);
        _log("✅ Firestore user checked");

        _goToNextScreen();
      } else {
        _log("ℹ No existing user found. Sending OTP...");
        _sendOTP();
        _startCountdown();
      }
    } catch (e, stack) {
      _log("❌ Silent login error: $e");
      _log("STACK: $stack");
    }
  }

  // ================= COUNTDOWN =================

  void _startCountdown() {
    _secondsRemaining = 60;
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
          _log("⏱ Countdown finished. Can resend OTP.");
        }
      });
    });
  }

  // ================= SEND OTP =================

  void _sendOTP() async {
    _log("🚀 Starting OTP request...");
    _log("📱 Phone number: ${widget.phoneNumber}");

    if (_resendCount >= _maxResend) {
      _log("❌ OTP resend limit reached.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP limit reached. Try again later.")),
      );
      return;
    }

    _resendCount++;

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          _log("✅ verificationCompleted triggered (AUTO SMS)");

          try {
            final userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);

            _log("✅ Auto sign-in success. UID: ${userCredential.user?.uid}");

            await _saveUid(userCredential.user!.uid);
            _log("✅ UID saved locally");

            await _createUserIfNotExists(userCredential.user!);
            _log("✅ Firestore user checked/created");

            _goToNextScreen();
          } catch (e, stack) {
            _log("❌ Auto sign-in error: $e");
            _log("STACK: $stack");
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          _log("❌ verificationFailed triggered");
          _log("Error Code: ${e.code}");
          _log("Error Message: ${e.message}");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP failed: ${e.message}')),
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          _log("📩 OTP Code Sent!");
          _log("Verification ID: $verificationId");
          _verificationId = verificationId;
          _startCountdown();
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _log("⏳ Auto retrieval timeout");
          _verificationId = verificationId;
        },
      );
    } catch (e, stack) {
      _log("❌ verifyPhoneNumber crashed");
      _log("Error: $e");
      _log("STACK: $stack");
    }
  }

  // ================= VERIFY OTP =================

  void _verifyOTP() async {
    final otp = _otpController.text.trim();

    _log("🔐 Manual OTP verification started");
    _log("Entered OTP: $otp");

    if (_verificationId.isEmpty) {
      _log("❌ Verification ID is empty!");
    }

    if (otp.length != 6) {
      _log("❌ OTP length invalid");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('براہ کرم 6 ہندسوں کا OTP درج کریں')),
      );
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      _log("✅ Manual sign-in success. UID: ${userCredential.user?.uid}");

      await _saveUid(userCredential.user!.uid);
      _log("✅ UID saved locally");

      await _createUserIfNotExists(userCredential.user!);
      _log("✅ Firestore user checked/created");

      _goToNextScreen();
    } on FirebaseAuthException catch (e, stack) {
      _log("❌ FirebaseAuthException during manual verify");
      _log("Error Code: ${e.code}");
      _log("Message: ${e.message}");
      _log("STACK: $stack");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e, stack) {
      _log("❌ Unknown error during manual verify");
      _log("Error: $e");
      _log("STACK: $stack");
    }
  }

  // ================= FIRESTORE =================

  Future<void> _saveUid(String uid) async {
    try {
      await saveData("customerId", uid);
      _log("💾 UID saved locally successfully");
    } catch (e, stack) {
      _log("❌ Failed to save UID locally");
      _log("Error: $e");
      _log("STACK: $stack");
    }
  }

  Future<void> _createUserIfNotExists(User user) async {
    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        _log("👤 Creating new Firestore user...");

        await userDoc.set({
          'uid': user.uid,
          'phone': widget.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _log("✅ New user document created");
      } else {
        _log("ℹ User already exists in Firestore");
      }
    } catch (e, stack) {
      _log("❌ Firestore user creation error");
      _log("Error: $e");
      _log("STACK: $stack");
    }
  }

  void _goToNextScreen() {
    _log("➡ Navigating to NameScreen");

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NameScreen()),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 40),

              const Text(
                "کوڈ درج کریں",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                "پر ${widget.phoneNumber} بھیجا گیا",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: screenSize.width,
                child: TextField(
                  controller: _otpController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 32),
                  decoration: const InputDecoration(
                    hintText: "123456",
                    border: InputBorder.none,
                    counterText: "",
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _canResend
                  ? TextButton(
                      onPressed: _sendOTP,
                      child: const Text(
                        "OTP دوبارہ بھیجیں",
                        style: TextStyle(color: Colors.green),
                      ),
                    )
                  : Text("$_secondsRemaining سیکنڈ میں دوبارہ بھیجیں"),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _verifyOTP,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    "Next",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= DEBUG PANEL =================

              if (_showDebug)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _debugLog,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}