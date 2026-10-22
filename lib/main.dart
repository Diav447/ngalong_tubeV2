import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

void main() => runApp(const NgalongTubeV2());

class NgalongTubeV2 extends StatelessWidget {
  const NgalongTubeV2({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false, 
    theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF050505)),
    home: const DevConsolePage()
  );
}

class VideoItem {
  final String videoId; final String title; final String author; final String thumb;
  VideoItem({required this.videoId, required this.title, required this.author, required this.thumb});
}

class DevConsolePage extends StatefulWidget {
  const DevConsolePage({super.key});
  @override
  State<DevConsolePage> createState() => _DevConsolePageState();
}

class _DevConsolePageState extends State<DevConsolePage> {
  final TextEditingController _searchC = TextEditingController(text: 'naruto');
  final List<String> _logs = [];
  List<VideoItem> _videos = [];
  bool _loading = false;

  final List<String> pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.adminforge.de',
  ];

  void addLog(String m) {
    setState(() { _logs.insert(0, '[${DateTime.now().toString().substring(11,19)}] $m'); if (_logs.length>40) _logs.removeLast(); });
  }

  Future<void> doSearch(String query) async {
    setState(() { _loading=true; _videos=[]; });
    for (var instance in pipedInstances) {
      try {
        final url = Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=videos');
        final res = await http.get(url).timeout(const Duration(seconds: 6));
        if (res.statusCode==200) {
          final data = jsonDecode(res.body);
          final items = data['items'] ?? [];
          List<VideoItem> vids = [];
          for (var item in items) {
            String raw = item['url'] ?? '';
            String cleanVid = raw.replaceAll('/watch?v=', '').split('&').first;
            if (cleanVid.length==11) {
              vids.add(VideoItem(videoId: cleanVid, title: item['title'] ?? '', author: item['uploaderName'] ?? '', thumb: item['thumbnail'] ?? 'https://img.youtube.com/vi/$cleanVid/hqdefault.jpg'));
            }
          }
          if (vids.isNotEmpty) {
            setState(() => _videos=vids);
            addLog('OK ${vids.length} video');
            setState(() => _loading=false);
            return;
          }
        }
      } catch (e) { continue; }
    }
    setState(() => _loading=false);
  }

  @override
  void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 500), () => doSearch(_searchC.text)); }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        const Padding(padding: EdgeInsets.all(12), child: Row(children: [Text('V18.3 PIPED', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8A2BE2))) ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: TextField(controller: _searchC, onSubmitted: doSearch, decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        if(_loading) const LinearProgressIndicator(color: Color(0xFF8A2BE2)),
        Expanded(child: ListView.builder(itemCount:_videos.length, itemBuilder:(c,i){ final v=_videos[i]; return ListTile(leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(v.thumb, width:90, height:60, fit: BoxFit.cover)), title: Text(v.title, maxLines:2, style: const TextStyle(fontSize:13)), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_)=>PlayerPipedPage(video: v))));})),
      ])),
    );
  }
}

class PlayerPipedPage extends StatefulWidget {
  final VideoItem video; const PlayerPipedPage({super.key, required this.video});
  @override
  State<PlayerPipedPage> createState() => _PlayerPipedPageState();
}

class _PlayerPipedPageState extends State<PlayerPipedPage> {
  VideoPlayerController? _controller;
  List<dynamic> _streams = [];
  bool _loading = true;
  String _log = 'Loading...';
  final List<String> instances = ['https://pipedapi.kavin.rocks','https://pipedapi.adminforge.de'];

  @override
  void initState() { super.initState(); fetchStream(); }

  Future<void> fetchStream() async {
    for (var inst in instances) {
      try {
        setState(() => _log = 'Fetch $inst');
        final res = await http.get(Uri.parse('$inst/streams/${widget.video.videoId}')).timeout(const Duration(seconds: 8));
        if (res.statusCode==200) {
          final data = jsonDecode(res.body);
          final streams = data['videoStreams'] as List? ?? [];
          if (streams.isNotEmpty) {
            streams.sort((a,b) => (a['height']??0).compareTo(b['height']??0));
            setState(() => _streams = streams);
            var pick = streams.firstWhere((e) => e['height']==480, orElse: () => streams.firstWhere((e) => e['height']==360, orElse: () => streams[0]));
            await play(pick['url']);
            return;
          }
        }
      } catch (e) { continue; }
    }
    setState(() { _loading=false; _log='Gagal'; });
  }

  Future<void> play(String url) async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      await c.play();
      setState(() { _controller=c; _loading=false; _log='Playing'; });
    } catch (e) {
      setState(() { _log='Play error: $e'; _loading=false; });
    }
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.video.title, maxLines:1, style: const TextStyle(fontSize:13)),
        actions: [
          if (_streams.isNotEmpty)
            PopupMenuButton<int>(
              icon: const Icon(Icons.hd),
              onSelected: (i) => play(_streams[i]['url']),
              itemBuilder: (_) => List.generate(_streams.length, (i) => PopupMenuItem(value: i, child: Text('${_streams[i]['height']}p'))),
            )
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16/9,
            child: _loading ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height:8), Text(_log, style: const TextStyle(color: Colors.grey, fontSize:11))]))
            : _controller != null && _controller!.value.isInitialized ? Stack(alignment: Alignment.bottomCenter, children: [VideoPlayer(_controller!), VideoProgressIndicator(_controller!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Color(0xFF8A2BE2)))]) : Text(_log),
          ),
          if (_controller != null) IconButton(icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow, size: 40), onPressed: () => setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play())),
        ],
      ),
    );
  }
}
DART
