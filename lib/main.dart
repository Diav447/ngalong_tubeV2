import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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

  // LIST PIPED YANG MASIH HIDUP 2026 - URUTAN PALING STABIL
  final List<String> pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.adminforge.de',
    'https://api.piped.projectsegfau.lt',
    'https://pipedapi.leptospira.lv',
    'https://piped-api.lunar.icu',
  ];

  void addLog(String m) {
    setState(() { 
      _logs.insert(0, '[${DateTime.now().toString().substring(11,19)}] $m'); 
      if (_logs.length>50) _logs.removeLast(); 
    });
  }

  Future<void> doSearch(String query) async {
    setState(() { _loading=true; _videos=[]; });
    addLog('🔍 Searching: $query');

    // === METODE 1: YOUTUBE.COM LANGSUNG (PRIMER - V16 LU) ===
    try {
      addLog('📡 Try YOUTUBE.COM...');
      final url = Uri.parse('https://www.youtube.com/youtubei/v1/search?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8');
      final body = jsonEncode({
        "context": {"client": {"clientName": "WEB", "clientVersion": "2.20240301.09.00", "hl":"id","gl":"ID"}},
        "query": query
      });
      final res = await http.post(url, headers: {"Content-Type":"application/json","User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}, body: body).timeout(const Duration(seconds: 8));
      addLog('📡 Youtube.com Status: ${res.statusCode}');

      if (res.statusCode==200) {
        final data = jsonDecode(res.body);
        final contents = data['contents']?['twoColumnSearchResultsRenderer']?['primaryContents']?['sectionListRenderer']?['contents'] as List? ?? [];
        List<VideoItem> vids = [];
        for (var sec in contents) {
          final itemSec = sec['itemSectionRenderer']?['contents'] as List? ?? [];
          for (var item in itemSec) {
            final vr = item['videoRenderer'];
            if (vr==null) continue;
            final vid = vr['videoId'] ?? '';
            final title = vr['title']?['runs']?[0]?['text'] ?? vr['title']?['simpleText'] ?? 'No Title';
            final author = vr['ownerText']?['runs']?[0]?['text'] ?? vr['longBylineText']?['runs']?[0]?['text'] ?? 'Unknown';
            final thumb = vr['thumbnail']?['thumbnails']?.last?['url'] ?? 'https://img.youtube.com/vi/$vid/hqdefault.jpg';
            if (vid.length==11) vids.add(VideoItem(videoId: vid, title: title, author: author, thumb: thumb));
          }
        }
        if (vids.isNotEmpty) {
          setState(() => _videos=vids);
          addLog('✅ OK YOUTUBE.COM - ${vids.length} video!');
          setState(() => _loading=false);
          return;
        }
      }
    } catch (e) {
      addLog('❌ FAIL youtube.com -> $e');
    }

    // === METODE 2: PIPED FALLBACK (BALIKIN PIPED DKK) ===
    addLog('🔄 Youtube fail, coba Piped instances...');
    for (var instance in pipedInstances) {
      try {
        addLog('📡 Try Piped: $instance');
        final url = Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=videos');
        final res = await http.get(url, headers: {"User-Agent":"Mozilla/5.0"}).timeout(const Duration(seconds: 5));
        addLog('📡 Piped ${instance.split('/').last} Status: ${res.statusCode}');
        if (res.statusCode==200) {
          final data = jsonDecode(res.body);
          final items = data['items'] ?? data['content'] ?? [];
          List<VideoItem> vids = [];
          for (var item in items) {
            final vid = item['url']?.toString().split('v=').last ?? item['id'] ?? '';
            // piped kadang return /watch?v=xxx
            String cleanVid = vid.contains('/') ? vid.split('v=').last.split('&').first : vid;
            if (cleanVid.length != 11) {
               cleanVid = item['url']?.toString().replaceAll('/watch?v=', '') ?? '';
            }
            if (cleanVid.length==11) {
              vids.add(VideoItem(
                videoId: cleanVid, 
                title: item['title'] ?? 'No Title', 
                author: item['uploaderName'] ?? item['author'] ?? 'Unknown',
                thumb: item['thumbnail'] ?? 'https://img.youtube.com/vi/$cleanVid/hqdefault.jpg'
              ));
            }
          }
          if (vids.isNotEmpty) {
            setState(() => _videos=vids);
            addLog('✅ OK PIPED $instance - ${vids.length} video!');
            setState(() => _loading=false);
            return;
          }
        }
      } catch (e) {
        addLog('❌ Piped $instance fail -> $e');
        continue; // coba instance selanjutnya
      }
    }

    addLog('❌ ALL FAIL - Cek internet lu bro!');
    setState(() => _loading=false);
  }

  @override
  void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 500), () => doSearch(_searchC.text)); }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        const Padding(padding: EdgeInsets.all(12), child: Row(children: [Text('😈', style: TextStyle(fontSize:26)), SizedBox(width:8), Text('Ngalong Tube V17 REBORN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF8A2BE2))) ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: TextField(controller: _searchC, onSubmitted: doSearch, decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        const SizedBox(height: 8),
        Container(height:130, color: const Color(0xFF0A0A0A), padding: const EdgeInsets.all(8), child: ListView.builder(itemCount:_logs.length, itemBuilder: (c,i) => Text(_logs[i], style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.greenAccent)))),
        if(_loading) const LinearProgressIndicator(color: Color(0xFF8A2BE2)),
        Expanded(child: ListView.builder(itemCount:_videos.length, itemBuilder:(c,i){ final v=_videos[i]; return ListTile(leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(v.thumb, width:90, height:60, fit: BoxFit.cover)), title: Text(v.title, maxLines:2, style: const TextStyle(fontSize:13)), subtitle: Text(v.author, maxLines:1, style: const TextStyle(fontSize:11, color: Colors.grey)), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_)=>PlayerPage(video: v))));})),
      ])),
    );
  }
}

class PlayerPage extends StatefulWidget {
  final VideoItem video; const PlayerPage({super.key, required this.video});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}
class _PlayerPageState extends State<PlayerPage> {
  late YoutubePlayerController _c;
  @override
  void initState() { super.initState(); _c=YoutubePlayerController(initialVideoId: widget.video.videoId, flags: const YoutubePlayerFlags(autoPlay: true, mute: false, enableCaption: false)); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: Text(widget.video.title, maxLines:1), backgroundColor: Colors.black), body: YoutubePlayer(controller: _c, showVideoProgressIndicator: true));
}
