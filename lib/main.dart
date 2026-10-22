import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

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
    'https://api.piped.projectsegfau.lt',
  ];

  void addLog(String m) {
    setState(() { _logs.insert(0, '[${DateTime.now().toString().substring(11,19)}] $m'); if (_logs.length>40) _logs.removeLast(); });
  }

  Future<void> doSearch(String query) async {
    setState(() { _loading=true; _videos=[]; });
    addLog('🔍 Searching: $query MODE: PIPED+INVIDIOUS');
    // Langsung Piped aja, biar ringan
    for (var instance in pipedInstances) {
      try {
        addLog('📡 Try $instance');
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
            addLog('✅ OK ${vids.length} video!');
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
        const Padding(padding: EdgeInsets.all(12), child: Row(children: [Text('😈', style: TextStyle(fontSize:26)), SizedBox(width:8), Text('Ngalong Tube V18 - PIPED STREAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF8A2BE2))) ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: TextField(controller: _searchC, onSubmitted: doSearch, decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        Container(height:90, color: const Color(0xFF0A0A0A), padding: const EdgeInsets.all(8), child: ListView.builder(itemCount:_logs.length, itemBuilder: (c,i) => Text(_logs[i], style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.greenAccent)))),
        if(_loading) const LinearProgressIndicator(color: Color(0xFF8A2BE2)),
        Expanded(child: ListView.builder(itemCount:_videos.length, itemBuilder:(c,i){ final v=_videos[i]; return ListTile(leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(v.thumb, width:90, height:60, fit: BoxFit.cover)), title: Text(v.title, maxLines:2, style: const TextStyle(fontSize:13)), subtitle: Text(v.author, maxLines:1, style: const TextStyle(fontSize:11, color: Colors.grey)), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_)=>PlayerPipedPage(video: v))));})),
      ])),
    );
  }
}

// PLAYER BARU - PAKE PIPED STREAM BIAR ENTENG + BISA PILIH RESOLUSI
class PlayerPipedPage extends StatefulWidget {
  final VideoItem video; const PlayerPipedPage({super.key, required this.video});
  @override
  State<PlayerPipedPage> createState() => _PlayerPipedPageState();
}

class _PlayerPipedPageState extends State<PlayerPipedPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  List<dynamic> _streams = [];
  String _currentQuality = 'Loading...';
  bool _loadingStream = true;
  String _log = '';

  final List<String> pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.adminforge.de',
    'https://api.piped.projectsegfau.lt',
  ];

  @override
  void initState() {
    super.initState();
    fetchStream();
  }

  Future<void> fetchStream() async {
    for (var instance in pipedInstances) {
      try {
        setState(() => _log = 'Try $instance/streams/${widget.video.videoId}');
        final url = Uri.parse('$instance/streams/${widget.video.videoId}');
        final res = await http.get(url).timeout(const Duration(seconds: 8));
        if (res.statusCode==200) {
          final data = jsonDecode(res.body);
          final videoStreams = data['videoStreams'] as List? ?? [];
          if (videoStreams.isNotEmpty) {
            // Sort dari kualitas terendah biar enteng di HP kentang
            videoStreams.sort((a,b) => (a['height']??0).compareTo(b['height']??0));
            setState(() { _streams = videoStreams; });
            // Default pilih 720p kalo ada, kalo gak 480p, kalo gak paling kecil
            var pick = videoStreams.firstWhere((e) => e['height']==720, orElse: () => videoStreams.firstWhere((e) => e['height']==480, orElse: () => videoStreams[0]));
            await playUrl(pick['url'], '${pick['height']}p ${pick['mimeType']?.split('/').last ?? ''}');
            return;
          }
        }
      } catch (e) {
        setState(() => _log = 'Fail $instance: $e');
        continue;
      }
    }
    setState(() { _loadingStream=false; _log='All Piped instances fail'; });
  }

  Future<void> playUrl(String url, String quality) async {
    try {
      setState(() { _loadingStream=true; _currentQuality=quality; });
      _videoController?.dispose();
      _chewieController?.dispose();
      final vc = VideoPlayerController.networkUrl(Uri.parse(url));
      await vc.initialize();
      final cc = ChewieController(videoPlayerController: vc, autoPlay: true, looping: false, allowFullScreen: true, aspectRatio: vc.value.aspectRatio);
      setState(() { _videoController=vc; _chewieController=cc; _loadingStream=false; });
    } catch (e) {
      setState(() { _log='Play fail: $e'; _loadingStream=false; });
    }
  }

  @override
  void dispose() { _videoController?.dispose(); _chewieController?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black, 
        title: Text(widget.video.title, maxLines:1, style: const TextStyle(fontSize:14)),
        actions: [
          if (_streams.isNotEmpty)
            PopupMenuButton(
              icon: const Icon(Icons.hd),
              onSelected: (val) {
                final s = _streams[val as int];
                playUrl(s['url'], '${s['height']}p');
              },
              itemBuilder: (ctx) => List.generate(_streams.length, (i){
                final s = _streams[i];
                return PopupMenuItem(value: i, child: Text('${s['height']}p - ${s['mimeType']} - ${s['fps']}fps'));
              }),
            )
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16/9,
            child: _loadingStream ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: Color(0xFF8A2BE2)), const SizedBox(height:10), Text(_log, style: const TextStyle(fontSize:10, color: Colors.grey)), Text('Quality: $_currentQuality', style: const TextStyle(fontSize:11))])) 
            : _chewieController != null ? Chewie(controller: _chewieController!) : const Center(child: Text('Gagal load stream')),
          ),
          ListTile(title: Text(widget.video.title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${widget.video.author}\nQuality: $_currentQuality | Tap icon HD di pojok kanan atas buat ganti resolusi', style: const TextStyle(fontSize:12, color: Colors.grey))),
          if (_log.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(_log, style: const TextStyle(fontFamily: 'monospace', fontSize:10, color: Colors.greenAccent))),
        ],
      ),
    );
  }
}
