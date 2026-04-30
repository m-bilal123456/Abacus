// ignore_for_file: unnecessary_underscores

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// import your screens
// import 'addvoicescreen.dart';
// import 'editvoicescreen.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _currentlyPlayingId;
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 🔥 PLAYBACK HANDLER (your working logic)
  Future<void> _handlePlayback(String docId, String url) async {
    try {
      if (_currentlyPlayingId == docId && _isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
          _currentlyPlayingId = null;
        });
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.release();

      await _audioPlayer.setSource(UrlSource(url));
      await _audioPlayer.resume();

      setState(() {
        _currentlyPlayingId = docId;
        _isPlaying = true;
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingId = null;
          });
        }
      });
    } catch (e) {
      debugPrint("Playback Error: $e");
    }
  }


  /// 🎧 AUDIO CARD UI (your old UI style but dynamic)
  Widget _buildAudioCard(
      Map<String, dynamic> data, String docId, bool isPlaying) {
    final String title = data['title'] ?? "No Title";
    final String description = data['description'] ?? "";
    final String audioUrl = data['audio_url'] ?? "";

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPlaying ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            /// Play Button
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 36,
                color: Colors.green,
              ),
              onPressed: () => _handlePlayback(docId, audioUrl),
            ),

            const SizedBox(width: 16),

            /// Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isPlaying
                            ? FontWeight.bold
                            : FontWeight.normal,
                      )),
                  const SizedBox(height: 4),
                  Text(description,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 👤 PROFILE CARD (unchanged)
  Widget _profileCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("خنا اعجاز",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("کسٹمر سروس ڈیپارٹمنٹ",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                SizedBox(height: 4),
                Text("کینٹین", style: TextStyle(fontSize: 16)),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voice Clips")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _profileCard(),
            const SizedBox(height: 20),

            /// 🔥 FIRESTORE STREAM
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('voice')
                    .where('deleted', isNotEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text("No voice clips found."));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;

                      final isPlaying =
                          _currentlyPlayingId == doc.id && _isPlaying;

                      return Column(
                        children: [
                          _buildAudioCard(data, doc.id, isPlaying),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}