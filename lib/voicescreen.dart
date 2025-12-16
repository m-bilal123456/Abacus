import 'package:abacus/audiomanager.dart';
import 'package:flutter/material.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final audioManager = AudioManager();
  final dummyAudio = 'assets/audio.mp3';

  @override
  void initState() {
    super.initState();
    audioManager.addListener(_updateUI);
  }

  @override
  void dispose() {
    audioManager.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  String format(Duration d) {
    return "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    bool isActive = audioManager.currentUrl == dummyAudio && audioManager.isPlaying;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "خنا اعجاز",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "کسٹمر سروس ڈیپارٹمنٹ",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "کینٹین",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Audio Play Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isActive ? Colors.green : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isActive ? Icons.pause : Icons.play_arrow,
                        size: 36,
                        color: Colors.green,
                      ),
                      onPressed: () {
                        isActive
                            ? audioManager.pause()
                            : audioManager.play(dummyAudio, isAsset: true);
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dec 11",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "سننے کے لیے یہاں دبائیں",
                            style: const TextStyle(fontSize: 14),
                          ),
                          Slider(
                            value: audioManager.position.inSeconds.toDouble(),
                            max: audioManager.duration.inSeconds > 0
                                ? audioManager.duration.inSeconds.toDouble()
                                : 1,
                            onChanged: (value) {
                              audioManager.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                          Text(format(audioManager.position)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
