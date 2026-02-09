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

  late String _verificationId;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  int _resendCount = 0;
  static const int _maxResend = 3;

  @override
  void initState() {
    super.initState();
    _silentLoginCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ✅ SILENT AUTO LOGIN
  Future<void> _silentLoginCheck() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await _saveUid(user.uid);
      await _createUserIfNotExists(user);
      _goToNextScreen();
    } else {
      _sendOTP();
      _startCountdown();
    }
  }

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
        }
      });
    });
  }

  // 📩 SEND OTP WITH LIMIT
  void _sendOTP() async {
    if (_resendCount >= _maxResend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP limit reached. Try again later.")),
      );
      return;
    }

    _resendCount++;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        await _saveUid(userCredential.user!.uid);
        await _createUserIfNotExists(userCredential.user!);

        _goToNextScreen();
      },

      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP failed: ${e.message}')),
        );
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _startCountdown();
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // 🔐 VERIFY OTP
  void _verifyOTP() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
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

      await _saveUid(userCredential.user!.uid);
      await _createUserIfNotExists(userCredential.user!);

      _goToNextScreen();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP غلط ہے، دوبارہ کوشش کریں')),
      );
    }
  }

  // 💾 SAVE UID LOCALLY
  Future<void> _saveUid(String uid) async {
    await saveData("customerId", uid);
  }

  // 👤 AUTO CREATE USER DOC
  Future<void> _createUserIfNotExists(User user) async {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'phone': widget.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _goToNextScreen() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NameScreen()),
    );
  }

  // ================= UI BELOW (UNCHANGED) =================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("ہیلپ لائن"),
                  ),
                ],
              ),

              const SizedBox(height: 50),
              const Text(
                "کوڈ درج کریں",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),
              Text(
                "پر ${widget.phoneNumber} بھیجا گیا",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                        style:
                            TextStyle(fontSize: 16, color: Colors.green),
                      ),
                    )
                  : Text(
                      "$_secondsRemaining سیکنڈ میں دوبارہ بھیجیں",
                      style:
                          const TextStyle(fontSize: 14, color: Colors.grey),
                    ),

              const SizedBox(height: 40),

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
            ],
          ),
        ),
      ),
    );
  }
}
