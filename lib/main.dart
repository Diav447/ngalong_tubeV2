import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const NgalongTubeV7());
class NgalongTubeV7 extends StatelessWidget {
  const NgalongTubeV7({super.key});
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark(), home: const SearchPage());
}
class SearchPage extends StatefulWidget { const SearchPage({super.key}); @override State<SearchPage> createState() => _SearchPageState(); }
class _SearchPageState extends State<SearchPage> {
  final _c = TextEditingController(text: "ikan");
  List vids = [];
  String log = "V7 FINAL - API Bypass";
  bool loading = false;

  Future<void> search(String q) async {
    setState(() { loading = true; log = "Nembak API YouTube asli..."; vids = []; });
    // 1. Coba InnerTube API resmi YouTube (yang dipake app YouTube ori lu)
    try {
      var res = await http.post(Uri.parse("https://www.youtube.com/youtubei/v1/search?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"),
        headers: {"Content-Type":"application/json"},
        body: jsonEncode({"context":{"clientName":"WEB","clientVersion":"2.20240101"}},"query":q})
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 && res.body.contains("videoId")) {
        var j = jsonDecode(res.body);
        var contents = j['contents']?['twoColumnSearchResultsRenderer']?['primaryContents']?['sectionListRenderer']?['contents']??[];
        List found = [];
        for (var sec in contents) {
          var items = sec['itemSectionRenderer']?['contents']??[];
          for (var it in items) {
            var vr = it['videoRenderer'];
            if (vr!= null) found.add({'videoId': vr['videoId'], 'title': vr['title']?['runs']?[0]?['text']??'No title', 'author': vr['ownerText']?['runs']?[0]?['text']??'YouTube'});
          }
        }
        if (found.isNotEmpty) {
          setState(() { vids = found.take(15).toList(); log = "TEMBUS VIA YOUTUBE ASLI! ${found.length} video"; loading = false; });
          return;
        }
      }
    } catch (e) { log = "YouTube API gagal: $e"; }

    // 2. Backup - Piped API (paling ringan, jarang diblock)
    List<String> pipedApis = ["https://pipedapi.kavin.rocks", "https://api.piped.private.coffee", "https://pipedapi.adminforge.de"];
    for (var api in pipedApis) {
      try {
        setState(() { log = "Coba $api..."; });
        var res = await http.get(Uri.parse("$api/search?q=${Uri.encodeComponent(q)}")).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          var j = jsonDecode(res.body);
          var items = j['items']??j;
          if (items is List && items.isNotEmpty) {
            var mapped = items.where((x)=>x['type']=='stream').map((x)=>{'videoId': (x['url'] as String).split("v=").last.split("&").first.replaceAll("/watch?v=", ""), 'title': x['title'], 'author': x['uploaderName']}).toList();
            if (mapped.isNotEmpty) {
              setState(() { vids = mapped.take(15).toList(); log = "TEMBUS VIA PIPED $api!"; loading=false; }); return;
            }
          }
        }
      } catch (_) {}
    }
    setState(() { log = "Semua API gagal. Matikan DNS Pribadi + WARP WAJIB mode WARP + Force Stop app."; loading=false; });
  }

  @override void initState() { super.initState(); search(_c.text); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("😈 NgalongTube V7 FINAL"), backgroundColor: Colors.black),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _c, onSubmitted: search, decoration: InputDecoration(hintText:"cari ikan cupang...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: ()=>search(_c.text))))),
        Padding(padding: const EdgeInsets.all(8), child: Text(log, style: const TextStyle(color: Colors.greenAccent, fontSize:12), textAlign: TextAlign.center)),
        if (loading) const LinearProgressIndicator(color: Colors.purple),
        Expanded(child: ListView.builder(itemCount: vids.length, itemBuilder: (c,i){
          var v=vids[i]; return ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network("https://i.ytimg.com/vi/${v['videoId']}/mqdefault.jpg", width:100, fit:BoxFit.cover, errorBuilder: (a,b,c)=>const Icon(Icons.broken_image))),
            title: Text(v['title']??'', maxLines:2, style: const TextStyle(fontSize:13)), subtitle: Text(v['author']??''),
            onTap: () async { await launchUrl(Uri.parse("https://www.youtube.com/watch?v=${v['videoId']}"), mode: LaunchMode.externalApplication); },
          );
        })),
      ]),
      floatingActionButton: FloatingActionButton.small(backgroundColor: Colors.purple, onPressed: ()=>search(_c.text), child: const Icon(Icons.refresh)),
    );
  }
}
