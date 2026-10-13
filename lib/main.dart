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
  final _c = TextEditingController(text: "playlist ngalong malam");
  List vids = [];
  String log = "V7.1 FIXED - API Bypass";
  bool loading = false;

  Future<void> search(String q) async {
    setState(() { loading = true; log = "Nembak API YouTube asli..."; vids = []; });
    try {
      var res = await http.post(
        Uri.parse("https://www.youtube.com/youtubei/v1/search?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"),
        headers: {"Content-Type":"application/json"},
        body: jsonEncode({
          "context": {"client": {"clientName": "WEB", "clientVersion": "2.20240101.01.00"}},
          "query": q
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 && res.body.contains("videoId")) {
        var j = jsonDecode(res.body);
        var contents = j['contents']?['twoColumnSearchResultsRenderer']?['primaryContents']?['sectionListRenderer']?['contents']??[];
        List found = [];
        for (var sec in contents) {
          var items = sec['itemSectionRenderer']?['contents']??[];
          for (var it in items) {
            var vr = it['videoRenderer'];
            if (vr!= null) found.add({'videoId': vr['videoId'], 'title': vr['title']?['runs']?[0]?['text']??'No title', 'author': vr['ownerText']?['runs']?[0]?['text']??'YT'});
          }
        }
        if (found.isNotEmpty) {
          setState(() { vids = found.take(15).toList(); log = "TEMBUS VIA YT ASLI! ${found.length} video"; loading = false; });
          return;
        }
      }
    } catch (e) { log = "YT API: $e"; }

    List<String> pipedApis = ["https://pipedapi.kavin.rocks", "https://api.piped.private.coffee"];
    for (var api in pipedApis) {
      try {
        setState(() { log = "Coba backup $api..."; });
        var res = await http.get(Uri.parse("$api/search?q=${Uri.encodeComponent(q)}")).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          var j = jsonDecode(res.body);
          var items = j['items']??j;
          if (items is List && items.isNotEmpty) {
            var mapped = items.where((x)=>x['type']=='stream').map((x)=>{'videoId': (x['url'] as String).split("v=").last.split("&").first.replaceAll("/watch?v=", ""), 'title': x['title'], 'author': x['uploaderName']}).toList();
            if (mapped.isNotEmpty) { setState(() { vids = mapped.take(15).toList(); log = "TEMBUS VIA PIPED!"; loading=false; }); return; }
          }
        }
      } catch (_) {}
    }
    setState(() { log = "Gagal. Matikan DNS Pribadi + WARP WARP mode."; loading=false; });
  }

  @override void initState() { super.initState(); search(_c.text); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("😈 NgalongTube V7.1 FIX"), backgroundColor: Colors.black),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _c, onSubmitted: search, decoration: InputDecoration(hintText:"cari...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: ()=>search(_c.text))))),
        Padding(padding: const EdgeInsets.all(8), child: Text(log, style: const TextStyle(color: Colors.greenAccent, fontSize:12), textAlign: TextAlign.center)),
        if (loading) const LinearProgressIndicator(color: Colors.purple),
        Expanded(child: ListView.builder(itemCount: vids.length, itemBuilder: (c,i){
          var v=vids[i]; return ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network("https://i.ytimg.com/vi/${v['videoId']}/mqdefault.jpg", width:100, fit:BoxFit.cover)),
            title: Text(v['title']??'', maxLines:2, style: const TextStyle(fontSize:13)), subtitle: Text(v['author']??''),
            onTap: () async { await launchUrl(Uri.parse("https://www.youtube.com/watch?v=${v['videoId']}"), mode: LaunchMode.externalApplication); },
          );
        })),
      ]),
    );
  }
}
