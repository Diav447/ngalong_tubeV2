import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  runApp(const NgalongTubeV2());
}

class NgalongTubeV2 extends StatelessWidget {
  const NgalongTubeV2({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NGALONG TUBE V2',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF8A2BE2),
      ),
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
  final TextEditingController _searchC = TextEditingController(text: 'Naruto');
  final List<String> _logs = [];
  List<VideoItem> _videos = [];
  bool _loading = false;

  final List<String> invidiousInstances = [
    'https://yewtu.be',
    'https://invidious.jing.rocks',
    'https://inv.nadeko.net',
    'https://invidious.protokolla.fi',
    'https://iv.melmac.space',
    'https://invidious.lunar.icu',
  ];

  final List<String> pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://api.piped.private.coffee',
    'https://pipedapi.r4fo.com',
  ];

  void addLog(String msg) {
    final now = TimeOfDay.now();
    final time = '[${now.hour}:${now.minute.toString().padLeft(2,'0')}:${DateTime.now().second.toString().padLeft(2,'0')}]';
    setState(() {
      _logs.insert(0, '$time $msg');
      if (_logs.length > 30) _logs.removeLast();
    });
  }

  Future<void> doSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _loading = true; _videos = []; });
    addLog('🔍 Searching: $query');

    for (var base in invidiousInstances) {
      try {
        addLog('⏳ Coba: $base');
        final url = Uri.parse('$base/api/v1/search?q=${Uri.encodeComponent(query)}');
        final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final List data = jsonDecode(res.body);
          final vids = data.where((e) => e['type'] == 'video').take(20).map((e) => VideoItem(
            videoId: e['videoId'] ?? '',
            title: e['title'] ?? 'No Title',
            author: e['author'] ?? 'Unknown',
            thumb: e['videoThumbnails'] != null && (e['videoThumbnails'] as List).isNotEmpty ? e['videoThumbnails'][0]['url'] : 'https://img.youtube.com/vi/${e['videoId']}/hqdefault.jpg',
          )).where((v) => v.videoId.isNotEmpty).toList();
          if (vids.isNotEmpty) {
            setState(() => _videos = vids);
            addLog('✅ OK $base - ${vids.length} video');
            setState(() => _loading = false);
            return;
          }
        }
      } catch (e) {
        addLog('❌ FAIL $base');
        continue;
      }
    }

    for (var base in pipedInstances) {
      try {
        addLog('⏳ Fallback Piped: $base');
        final url = Uri.parse('$base/search?q=${Uri.encodeComponent(query)}');
        final res = await http.get(url).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final Map data = jsonDecode(res.body);
          final List items = data['items'] ?? [];
          final vids = items.where((e) => e['type'] == 'stream').take(20).map((e) => VideoItem(
            videoId: e['url']?.toString().split('?v=').last ?? '',
            title: e['title'] ?? '',
            author: e['uploaderName'] ?? '',
            thumb: e['thumbnail'] ?? '',
          )).where((v) => v.videoId.isNotEmpty).toList();
          if (vids.isNotEmpty) {
            setState(() => _videos = vids);
            addLog('✅ OK PIPED $base');
            setState(() => _loading = false);
            return;
          }
        }
      } catch (e) { continue; }
    }

    addLog('❌ ALL FAIL - Coba search lain / ganti DNS ke 1.1.1.1');
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () => doSearch(_searchC.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Text('😈', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  const Text('V13 DEV CONS...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF9C4DFF))),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF8A2BE2))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF8A2BE2), width: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 110,
              width: double.infinity,
              color: const Color(0xFF0A0A0A),
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (c, i) {
                  final log = _logs[i];
                  Color col = Colors.greenAccent;
                  if (log.contains('FAIL')) col = Colors.redAccent;
                  if (log.contains('Coba') || log.contains('Searching')) col = Colors.cyanAccent;
                  return Text(log, style: TextStyle(color: col, fontFamily: 'monospace', fontSize: 11));
                },
              ),
            ),
            if (_loading) const LinearProgressIndicator(color: Color(0xFF8A2BE2)),
            Expanded(
              child: _videos.isEmpty && !_loading
                  ? const Center(child: Text('Cari dulu bro...', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _videos.length,
                      itemBuilder: (c, i) {
                        final v = _videos[i];
                        return ListTile(
                          leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(v.thumb, width: 100, fit: BoxFit.cover, errorBuilder: (a,b,c) => Container(width: 100, color: Colors.grey))),
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
