import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() => runApp(const NgalongTubeV2());

class NgalongTubeV2 extends StatelessWidget {
  const NgalongTubeV2({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black), home: const DevConsolePage());
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

  void addLog(String m) {
    setState(() { _logs.insert(0, '[${DateTime.now().toString().substring(11,19)}] $m'); if (_logs.length>40) _logs.removeLast(); });
  }

  Future<void> doSearch(String query) async {
    setState(() { _loading=true; _videos=[]; });
    addLog('🔍 Searching: $query ke YOUTUBE.COM langsung');

    try {
      // INNERTUBE - KEY PUBLIC YOUTUBE
      final url = Uri.parse('https://www.youtube.com/youtubei/v1/search?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8');
      final body = jsonEncode({
        "context": {"client": {"clientName": "WEB", "clientVersion": "2.20240301.09.00", "hl":"id","gl":"ID"}},
        "query": query
      });
      final res = await http.post(url, headers: {"Content-Type":"application/json","User-Agent":"Mozilla/5.0"}, body: body).timeout(const Duration(seconds: 12));
      
      addLog('📡 Status: ${res.statusCode} dari youtube.com');
      
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
          addLog('✅ OK YOUTUBE.COM - ${vids.length} video ketemu!');
          setState(() => _loading=false);
          return;
        } else {
          addLog('⚠️ Youtube.com bales tapi kosong');
        }
      }
    } catch (e) {
      addLog('❌ FAIL youtube.com -> $e');
    }

    addLog('❌ ALL FAIL - Internet lu mati?');
    setState(() => _loading=false);
  }

  @override
  void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 500), () => doSearch(_searchC.text)); }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        const Padding(padding: EdgeInsets.all(12), child: Row(children: [Text('😈', style: TextStyle(fontSize:26)), SizedBox(width:8), Text('V15 YT DIRECT...', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C4DFF)))])),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: TextField(controller: _searchC, onSubmitted: doSearch, decoration: InputDecoration(prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))))),
        Container(height:130, color: const Color(0xFF0A0A0A), padding: const EdgeInsets.all(8), child: ListView.builder(itemCount:_logs.length, itemBuilder:(c,i){ final l=_logs[i]; Color col=Colors.white70; if(l.contains('FAIL')) col=Colors.redAccent; if(l.contains('OK')) col=Colors.greenAccent; if(l.contains('Searching')||l.contains('Status')) col=Colors.cyanAccent; return Text(l, style: TextStyle(color:col, fontFamily:'monospace', fontSize:11));})),
        if(_loading) const LinearProgressIndicator(color: Color(0xFF8A2BE2)),
        Expanded(child: ListView.builder(itemCount:_videos.length, itemBuilder:(c,i){ final v=_videos[i]; return ListTile(leading: ClipRRect(borderRadius:BorderRadius.circular(8), child: Image.network(v.thumb, width:100, fit:BoxFit.cover)), title: Text(v.title, maxLines:2, style: const TextStyle(fontSize:13)), subtitle: Text(v.author, style: const TextStyle(fontSize:11, color:Colors.grey)), onTap: () => Navigator.push(c, MaterialPageRoute(builder:(_)=>PlayerPage(video:v))));}))
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
  void initState() { super.initState(); _c=YoutubePlayerController(initialVideoId: widget.video.videoId, flags: const YoutubePlayerFlags(autoPlay:true)); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: Text(widget.video.title, maxLines:1), backgroundColor: Colors.black), body: YoutubePlayer(controller: _c));
}
