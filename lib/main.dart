import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() { runApp(const NgalongTubeV2()); }

class NgalongTubeV2 extends StatelessWidget {
  const NgalongTubeV2({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NGALONG TUBE V2',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const DevConsolePage(),
    );
  }
}

class VideoItem {
  final String videoId;
  final String title;
  final String author;
  final String thumb;
  VideoItem({required this.videoId, required this.title, required this.author, required this.thumb});
}

class DevConsolePage extends StatefulWidget {
  const DevConsolePage({super.key});
  @override
  State<DevConsolePage> createState() => _DevConsolePageState();
}

class _DevConsolePageState extends State<DevConsolePage> {
  final TextEditingController _searchC = TextEditingController(text: 'jp sad song');
  final List<String> _logs = [];
  List<VideoItem> _videos = [];
  bool _loading = false;

  void addLog(String msg) {
    final now = DateTime.now();
    final time = '[${now.hour}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}]';
    setState(() {
      _logs.insert(0, '$time $msg');
      if (_logs.length > 35) _logs.removeLast();
    });
  }

  Future<void> doSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _loading = true; _videos = []; });
    addLog('🔍 Searching: $query');

    try {
      addLog('⏳ Coba: YouTube Direct API');
      final url = Uri.parse('https://yt.lemnoslife.com/noKey/search?part=snippet&q=${Uri.encodeComponent(query)}&maxResults=20&type=video');
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final Map data = jsonDecode(res.body);
        final List items = data['items'] ?? [];
        final vids = items.map((e) {
          final id = e['id']?['videoId'] ?? '';
          final snippet = e['snippet'] ?? {};
          return VideoItem(
            videoId: id,
            title: snippet['title'] ?? 'No Title',
            author: snippet['channelTitle'] ?? 'Unknown',
            thumb: snippet['thumbnails']?['high']?['url'] ?? 'https://img.youtube.com/vi/$id/hqdefault.jpg',
          );
        }).where((v) => v.videoId.isNotEmpty).toList();
        if (vids.isNotEmpty) {
          setState(() => _videos = vids);
          addLog('✅ OK YouTube Direct - ${vids.length} video');
          setState(() => _loading = false);
          return;
        }
      }
    } catch (e) {
      addLog('❌ FAIL Direct');
    }

    final pipedInstances = [
      'https://pipedapi.kavin.rocks',
      'https://api.piped.private.coffee',
      'https://pipedapi.r4fo.com',
    ];
    for (var base in pipedInstances) {
      try {
        addLog('⏳ Coba Piped: $base');
        final url = Uri.parse('$base/search?q=${Uri.encodeComponent(query)}');
        final res = await http.get(url).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final Map data = jsonDecode(res.body);
          final List items = data['items'] ?? [];
          final vids = items.where((e) => e['type'] == 'stream').take(20).map((e) => VideoItem(
            videoId: (e['url'] ?? '').toString().split('?v=').last,
            title: e['title'] ?? '',
            author: e['uploaderName'] ?? '',
            thumb: e['thumbnail'] ?? '',
          )).where((v) => v.videoId.length == 11).toList();
          if (vids.isNotEmpty) {
            setState(() => _videos = vids);
            addLog('✅ OK Piped $base');
            setState(() => _loading = false);
            return;
          }
        }
      } catch (e) { continue; }
    }

    addLog('❌ ALL FAIL - Cek internet!');
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () => doSearch(_searchC.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text('😈', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  const Text('V14 DEV CONS...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF9C4DFF))),
                  const Spacer(),
                  IconButton(onPressed: () => setState(() => _logs.clear()), icon: const Icon(Icons.bug_report, size: 20))
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchC,
                onSubmitted: doSearch,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  hintText: 'jp sad song, naruto...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF8A2BE2))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF8A2BE2), width: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 130,
              color: const Color(0xFF0A0A0A),
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (c, i) {
                  final log = _logs[i];
                  Color col = Colors.white70;
                  if (log.contains('FAIL')) col = Colors.redAccent;
                  if (log.contains('Coba')) col = Colors.cyanAccent;
                  if (log.contains('OK')) col = Colors.greenAccent;
                  return Text(log, style: TextStyle(color: col, fontFamily: 'monospace', fontSize: 11));
                },
              ),
            ),
            if (_loading) const LinearProgressIndicator(color: Color(0xFF8A2BE2)),
            Expanded(
              child: ListView.builder(
                itemCount: _videos.length,
                itemBuilder: (c, i) {
                  final v = _videos[i];
                  return ListTile(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(v.thumb, width: 100, fit: BoxFit.cover, errorBuilder: (a,b,c) => Container(width:100, color: Colors.grey, child: const Icon(Icons.play_arrow)))),
                    title: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(v.author, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(video: v))),
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

class PlayerPage extends StatefulWidget {
  final VideoItem video;
  const PlayerPage({super.key, required this.video});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late YoutubePlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(initialVideoId: widget.video.videoId, flags: const YoutubePlayerFlags(autoPlay: true));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.video.title, maxLines: 1), backgroundColor: Colors.black),
      body: Column(children: [YoutubePlayer(controller: _controller, showVideoProgressIndicator: true)]),
    );
  }
}
