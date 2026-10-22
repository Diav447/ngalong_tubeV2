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

enum SearchMode { hybrid, direct, piped }

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
  SearchMode _mode = SearchMode.hybrid; // DEFAULT HYBRID

  final List<String> pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.adminforge.de',
    'https://api.piped.projectsegfau.lt',
  ];

  void addLog(String m) {
    setState(() { 
      _logs.insert(0, '[${DateTime.now().toString().substring(11,19)}] $m'); 
      if (_logs.length>50) _logs.removeLast(); 
    });
  }

  String get modeLabel {
    switch(_mode){
      case SearchMode.direct: return '🚀 NGEBUT';
      case SearchMode.piped: return '👻 HANTU';
      case SearchMode.hybrid: return '🔀 HYBRID';
    }
  }

  Future<void> doSearch(String query) async {
    setState(() { _loading=true; _videos=[]; });
    addLog('🔍 Mode: $modeLabel | Query: $query');

    // MODE DIRECT ATAU HYBRID: COBA YOUTUBE LANGSUNG DULU
    if (_mode == SearchMode.direct || _mode == SearchMode.hybrid) {
      try {
        addLog('📡 Try YOUTUBE.COM...');
        final url = Uri.parse('https://www.youtube.com/youtubei/v1/search?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8');
        final body = jsonEncode({
          "context": {"client": {"clientName": "WEB", "clientVersion": "2.20240301.09.00", "hl":"id","gl":"ID"}},
          "query": query
        });
        final res = await http.post(url, headers: {"Content-Type":"application/json","User-Agent":"Mozilla/5.0"}, body: body).timeout(const Duration(seconds: 8));
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
              final author = vr['ownerText']?['runs']?[0]?['text'] ?? 'Unknown';
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
        addLog('❌ Youtube fail: $e');
        if (_mode == SearchMode.direct) { setState(() => _loading=false); return; }
      }
    }

    // MODE PIPED ATAU HYBRID: FALLBACK PIPED
    if (_mode == SearchMode.piped || _mode == SearchMode.hybrid) {
      for (var instance in pipedInstances) {
        try {
          addLog('📡 Try Piped: $instance');
          final url = Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=videos');
          final res = await http.get(url).timeout(const Duration(seconds: 5));
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
              addLog('✅ OK PIPED ${instance.split('.').first} - ${vids.length} video!');
              setState(() => _loading=false);
              return;
            }
          }
        } catch (e) { addLog('❌ Piped fail: $e'); continue; }
      }
    }
    addLog('❌ ALL FAIL');
    setState(() => _loading=false);
  }

  void cycleMode(){
    setState(() {
      if (_mode == SearchMode.hybrid) _mode = SearchMode.direct;
      else if (_mode == SearchMode.direct) _mode = SearchMode.piped;
      else _mode = SearchMode.hybrid;
    });
    addLog('🔄 Ganti mode ke: $modeLabel');
  }

  @override
  void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 500), () => doSearch(_searchC.text)); }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          const Text('😈', style: TextStyle(fontSize:26)), const SizedBox(width:8), const Text('Ngalong Tube V17.5', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8A2BE2))),
          const Spacer(),
          GestureDetector(onTap: cycleMode, child: Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:6), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF8A2BE2))), child: Text(modeLabel, style: const TextStyle(fontSize:11, fontWeight: FontWeight.bold)))),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: TextField(controller: _searchC, onSubmitted: doSearch, decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
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
  void initState() { super.initState(); _c=YoutubePlayerController(initialVideoId: widget.video.videoId, flags: const YoutubePlayerFlags(autoPlay: true, mute: false, forceHD: false)); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(title: Text(widget.video.title, maxLines:1), backgroundColor: Colors.black),
    body: YoutubePlayerBuilder(
      player: YoutubePlayer(controller: _c, showVideoProgressIndicator: true, aspectRatio: 16/9, progressIndicatorColor: const Color(0xFF8A2BE2)),
      builder: (context, player) => Column(children: [player, Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.video.title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(widget.video.author, style: const TextStyle(color: Colors.grey))]))))]),
    ),
  );
}
