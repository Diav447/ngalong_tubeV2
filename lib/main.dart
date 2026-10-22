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
  List<VideoItem> _videos = [];
  bool _loading = false;
  String _status = 'Siap';

  // List Piped + Invidious biar gak kosong lagi
  final List<String> _searchEndpoints = [
    'https://pipedapi.adminforge.de/search?q=',
    'https://pipedapi.kavin.rocks/search?q=',
    'https://api.piped.private.coffee/search?q=',
    'https://pipedapi.syncpundit.io/search?q=',
    'https://inv.nadeko.net/api/v1/search?q=', // Invidious fallback
    'https://yewtu.be/api/v1/search?q=',
  ];

  Future<void> doSearch(String query) async {
    if(query.trim().isEmpty) return;
    setState(() { _loading=true; _videos=[]; _status='Cari $query...'; });
    
    for (var base in _searchEndpoints) {
      try {
        setState(() => _status = 'Coba ${Uri.parse(base).host}...');
        String fullUrl = base.contains('search?q=') && base.contains('piped') 
          ? '${base}${Uri.encodeComponent(query)}&filter=videos'
          : '${base}${Uri.encodeComponent(query)}';
        
        final res = await http.get(Uri.parse(fullUrl), headers: {'User-Agent':'Mozilla/5.0'}).timeout(const Duration(seconds: 7));
        
        if (res.statusCode==200) {
          final List<dynamic> data = base.contains('piped') ? (jsonDecode(res.body)['items'] ?? []) : jsonDecode(res.body) as List;
          List<VideoItem> vids = [];
          for (var item in data) {
            try {
              String vid = '';
              String title = '';
              String author = '';
              String thumb = '';
              
              if (base.contains('piped')) {
                String raw = item['url'] ?? '';
                vid = raw.replaceAll('/watch?v=', '').split('&').first;
                title = item['title'] ?? '';
                author = item['uploaderName'] ?? '';
                thumb = item['thumbnail'] ?? '';
              } else { // invidious
                if(item['type']!='video') continue;
                vid = item['videoId'] ?? '';
                title = item['title'] ?? '';
                author = item['author'] ?? '';
                thumb = (item['videoThumbnails'] != null && item['videoThumbnails'].length>0) ? item['videoThumbnails'][0]['url'] : 'https://img.youtube.com/vi/$vid/hqdefault.jpg';
              }
              
              if (vid.length>=11) {
                vid = vid.substring(0,11);
                vids.add(VideoItem(videoId: vid, title: title, author: author, thumb: thumb.isEmpty ? 'https://img.youtube.com/vi/$vid/hqdefault.jpg' : thumb));
              }
            } catch(_){continue;}
          }
          if (vids.isNotEmpty) {
            setState(() { _videos=vids; _loading=false; _status='${vids.length} video dari ${Uri.parse(base).host}'; });
            return;
          }
        }
      } catch (e) { continue; }
    }
    setState(() { _loading=false; _status='Gak ketemu / API mati semua, coba kata lain'; });
  }

  @override
  void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 800), () => doSearch(_searchC.text)); }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        const Padding(padding: EdgeInsets.fromLTRB(16,12,16,8), child: Align(alignment: Alignment.centerLeft, child: Text('V18.4 FIX KOSONG', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8A2BE2), fontSize:16)))),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: TextField(controller: _searchC, onSubmitted: doSearch, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Search naruto, anime...', prefixIcon: const Icon(Icons.search, color: Colors.grey), suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: ()=>doSearch(_searchC.text)), filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(_status, style: const TextStyle(color: Colors.grey, fontSize:11))),
        if(_loading) const LinearProgressIndicator(color: Color(0xFF8A2BE2), minHeight:2),
        Expanded(child: _videos.isEmpty && !_loading 
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.search_off, size:40, color: Colors.grey), const SizedBox(height:8), Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))]))
          : ListView.builder(itemCount:_videos.length, itemBuilder:(c,i){ final v=_videos[i]; return ListTile(leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(v.thumb, width:90, height:50, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(width:90,height:50,color: Colors.grey[900]))), title: Text(v.title, maxLines:2, style: const TextStyle(fontSize:13)), subtitle: Text(v.author, maxLines:1, style: const TextStyle(fontSize:11, color: Colors.grey)), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_)=>PlayerPipedPage(video: v))));})),
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
  String _log = 'Loading HLS...';
  final List<String> instances = [
    'https://pipedapi.adminforge.de',
    'https://pipedapi.kavin.rocks',
    'https://api.piped.private.coffee',
    'https://pipedapi.syncpundit.io',
    'https://pipedapi.drgns.space'
  ];

  @override
  void initState() { super.initState(); fetchStream(); }

  Future<void> fetchStream() async {
    for (var inst in instances) {
      try {
        setState(() => _log = 'Fetch ${Uri.parse(inst).host}');
        final res = await http.get(Uri.parse('$inst/streams/${widget.video.videoId}'), headers: {'User-Agent':'Mozilla/5.0'}).timeout(const Duration(seconds: 10));
        if (res.statusCode==200) {
          final data = jsonDecode(res.body);
          
          // 1. COBA HLS DULU - ini yang paling ampuh
          String? hlsUrl = data['hls'];
          if (hlsUrl != null && hlsUrl.isNotEmpty) {
            await play(hlsUrl);
            // simpen juga mp4 buat pilihan resolusi
            final vStreams = data['videoStreams'] as List? ?? [];
            if (vStreams.isNotEmpty) {
              vStreams.sort((a,b) => (a['height']??0).compareTo(b['height']??0));
              setState(() => _streams = vStreams);
            }
            return;
          }
          
          // 2. Kalo HLS gak ada, coba dash
          String? dashUrl = data['dash'];
          if (dashUrl != null && dashUrl.toString().isNotEmpty) {
             // dash susah di video_player, skip dulu
          }

          // 3. Fallback MP4
          final streams = data['videoStreams'] as List? ?? [];
          if (streams.isNotEmpty) {
            streams.sort((a,b) => (a['height']??0).compareTo(b['height']??0));
            setState(() => _streams = streams);
            var pick = streams.firstWhere((e) => e['height']==360, orElse: () => streams[0]);
            await play(pick['url']);
            return;
          }
        }
      } catch (e) { 
        setState(()=> _log = 'Error $e');
        continue; 
      }
    }
    // Fallback terakhir: coba Invidious
    try {
      setState(()=> _log = 'Coba Invidious...');
      final inv = await http.get(Uri.parse('https://inv.nadeko.net/api/v1/videos/${widget.video.videoId}')).timeout(const Duration(seconds: 8));
      if(inv.statusCode==200){
        final d = jsonDecode(inv.body);
        final fStreams = d['formatStreams'] as List? ?? [];
        if(fStreams.isNotEmpty){
          await play(fStreams[0]['url']);
          return;
        }
      }
    } catch(_){}
    
    setState(() { _loading=false; _log='Gagal load stream, coba video lain'; });
  }

  Future<void> play(String url) async {
    try {
      if(_controller!=null) await _controller!.dispose();
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      await c.play();
      setState(() { _controller=c; _loading=false; _log='Playing ${Uri.parse(url).host}'; });
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
      appBar: AppBar(backgroundColor: Colors.black, title: Text(widget.video.title, maxLines:1, style: const TextStyle(fontSize:13)),
        actions: [if (_streams.isNotEmpty) PopupMenuButton<int>(icon: const Icon(Icons.hd), onSelected: (i) => play(_streams[i]['url']), itemBuilder: (_) => List.generate(_streams.length, (i) => PopupMenuItem(value: i, child: Text('${_streams[i]['height']}p'))))]),
      body: Column(children: [
          AspectRatio(aspectRatio: 16/9, child: _loading ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: Color(0xFF8A2BE2)), const SizedBox(height:12), Text(_log, style: const TextStyle(color: Colors.grey, fontSize:11))])) : _controller != null && _controller!.value.isInitialized ? Stack(alignment: Alignment.bottomCenter, children: [VideoPlayer(_controller!), VideoProgressIndicator(_controller!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Color(0xFF8A2BE2)))]) : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error, color: Colors.red), const SizedBox(height:8), Text(_log, textAlign: TextAlign.center)]))),
          if (_controller != null) Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: Icon(_controller!.value.isPlaying ? Icons.pause_circle : Icons.play_circle, size: 50, color: const Color(0xFF8A2BE2)), onPressed: () => setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()))]),
        ],
      ),
    );
  }
}
