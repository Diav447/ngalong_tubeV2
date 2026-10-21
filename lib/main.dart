import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SearchPage()));

class SearchPage extends StatefulWidget { const SearchPage({super.key}); @override State<SearchPage> createState() => _S(); }

class _S extends State<SearchPage> {
  final _c = TextEditingController(text: "jp sad song");
  List vids = [];
  List<String> logs = [];
  bool load = false;
  bool showLog = true;

  void addLog(String s) {
    final t = "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}";
    setState(() => logs.insert(0, "[$t] $s"));
  }

  Future<void> search(String q) async {
    setState(() { load = true; vids = []; logs = []; });
    addLog("🚀 START search: $q");
    final headers = {"User-Agent": "Mozilla/5.0 (Linux; Android 13)"};
    
    // LIST API LU YANG 5 JALUR
    final List<Map> routes = [
      {"name": "YT WEB", "url": "https://www.youtube.com/youtubei/v1/search?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8", "type": "post_web"},
      {"name": "YT ANDROID", "url": "https://www.youtube.com/youtubei/v1/search?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8", "type": "post_android"},
      {"name": "PIPED puffy", "url": "https://vid.puffyan.us/api/v1/search?q=", "type": "get"},
      {"name": "PIPED y.com.sb", "url": "https://y.com.sb/api/v1/search?q=", "type": "get"},
      {"name": "INVID namazso", "url": "https://invidious.namazso.eu/api/v1/search?q=", "type": "get"},
    ];

    for (int i = 0; i < routes.length; i++) {
      if (vids.isNotEmpty) break;
      try {
        addLog("${i+1}/5 TRY ${routes[i]['name']}");
        http.Response r;
        if (routes[i]['type'] == 'post_web') {
          r = await http.post(Uri.parse(routes[i]['url']), headers: headers, body: jsonEncode({"context":{"client":{"clientName":"WEB","clientVersion":"2.20240101"}}, "query": q})).timeout(Duration(seconds:12));
        } else if (routes[i]['type'] == 'post_android') {
          r = await http.post(Uri.parse(routes[i]['url']), headers: headers, body: jsonEncode({"context":{"client":{"clientName":"ANDROID","clientVersion":"19.09"}}, "query": q})).timeout(Duration(seconds:12));
        } else {
          r = await http.get(Uri.parse("${routes[i]['url']}${Uri.encodeComponent(q)}"), headers: headers).timeout(Duration(seconds:12));
        }

        addLog("${i+1}/5 RESP ${r.statusCode} Len:${r.body.length}");
        if (r.statusCode == 200) {
          List f = [];
          if (r.body.trim().startsWith("{")) {
            var j = jsonDecode(r.body);
            var contents = j['contents']?['twoColumnSearchResultsRenderer']?['primaryContents']?['sectionListRenderer']?['contents'];
            if (contents != null) {
              for(var sec in contents){
                var items = sec['itemSectionRenderer']?['contents'] ?? [];
                for(var it in items){
                  var vr = it['videoRenderer'];
                  if(vr != null) f.add({"title": vr['title']?['runs']?[0]?['text'], "channel": vr['ownerText']?['runs']?[0]?['text'] ?? vr['longBylineText']?['runs']?[0]?['text'], "vid": vr['videoId'], "thumb": "https://i.ytimg.com/vi/${vr['videoId']}/hqdefault.jpg"});
                }
              }
            }
          } else {
            var j = jsonDecode(r.body);
            if (j is List) {
              f = j.where((e)=>e['type']=='video').map((e)=>{"title": e['title'], "channel": e['author'], "vid": e['videoId'], "thumb": "https://i.ytimg.com/vi/${e['videoId']}/hqdefault.jpg"}).toList();
            }
          }
          if (f.isNotEmpty) { setState(()=>vids=f); addLog("✅ SUCCESS jalur ${i+1}, dapet ${f.length}"); break; }
        }
      } catch(e) { addLog("💥 ERROR jalur ${i+1}: $e"); }
    }
    setState(()=> load=false);
    if(vids.isEmpty) addLog("❌ ALL FAIL - Coba search lain / ganti DNS 1.1.1.1");
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text("😈 V12 DEV CONS...", style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)), actions: [IconButton(icon: Icon(showLog?Icons.bug_report:Icons.bug_report_outlined, color: Colors.white), onPressed: ()=>setState(()=>showLog=!showLog))]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _c, style: const TextStyle(color: Colors.white), onSubmitted: search, decoration: InputDecoration(hintText: "jp sad song", hintStyle: const TextStyle(color: Colors.white54), prefixIcon: const Icon(Icons.search, color: Colors.white70), filled: true, fillColor: const Color(0xFF2A2A2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Colors.purpleAccent))))),
        if(load) const LinearProgressIndicator(color: Colors.purpleAccent),
        if(showLog) Container(height: 110, width: double.infinity, color: const Color(0xFF111111), padding: const EdgeInsets.all(6), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: logs.map((l)=>Text(l, style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'))).toList()))),
        Expanded(child: vids.isEmpty ? const Center(child: Text("Cari dulu bro...", style: TextStyle(color: Colors.white54))) : ListView.builder(itemCount: vids.length, itemBuilder: (_,i){
          final v=vids[i];
          return ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(v['thumb'], width: 110, height: 62, fit: BoxFit.cover)),
            title: Text(v['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(v['channel'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(videoId: v['vid'], title: v['title']))),
          );
        }))
      ]),
    );
  }
}

class PlayerPage extends StatefulWidget {
  final String videoId; final String title;
  const PlayerPage({super.key, required this.videoId, required this.title});
  @override State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late YoutubePlayerController _c;
  @override void initState() {
    super.initState();
    _c = YoutubePlayerController(initialVideoId: widget.videoId, flags: const YoutubePlayerFlags(autoPlay: true, mute: false, enableCaption: false));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text(widget.title, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Column(children: [
        YoutubePlayer(controller: _c, showVideoProgressIndicator: true, progressIndicatorColor: Colors.purpleAccent),
        Padding(padding: const EdgeInsets.all(12), child: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}
