import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const NgalongTubeV2());
class NgalongTubeV2 extends StatelessWidget {
  const NgalongTubeV2({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, title: 'NgalongTube V2', theme: ThemeData.dark(), home: const SearchPage());
  }
}
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}
class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController(text: "playlist ngalong malam");
  List videos = [];
  String log = "V2 Siap - Anti Failed Host Lookup";
  bool loading = false;
  final instances = ["https://inv.nadeko.net","https://yewtu.be","https://invidious.nerdvpn.de"];

  Future<void> search(String q) async {
    setState(() { loading = true; log = "Nyari: $q..."; videos = []; });
    for (var base in instances) {
      try {
        var url = "$base/api/v1/search?q=${Uri.encodeComponent(q)}";
        var proxy = Uri.parse("https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}");
        var res = await http.get(proxy).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          var data = jsonDecode(res.body);
          setState(() { videos = data.where((v) => v['type'] == 'video').toList(); log = "Dapet ${videos.length} video dari ${base.split('//').last}"; loading = false; });
          return;
        }
      } catch (e) { log = "Gagal $base, coba lain..."; }
    }
    setState(() { loading = false; log = "Coba nyalain VPN JP + DNS Otomatis"; });
  }
  @override
  void initState() { super.initState(); search(_controller.text); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("😈 NgalongTube V2"), backgroundColor: Colors.black),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _controller, onSubmitted: search, decoration: InputDecoration(hintText: "playlist ngalong malam", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: ()=>search(_controller.text))))),
        Padding(padding: const EdgeInsets.all(8), child: Text(log, style: const TextStyle(color: Colors.grey, fontSize: 12))),
        if (loading) const LinearProgressIndicator(),
        Expanded(child: ListView.builder(itemCount: videos.length, itemBuilder: (c,i){ var v=videos[i]; return ListTile(leading: Image.network("https://i.ytimg.com/vi/${v['videoId']}/mqdefault.jpg", width:100, fit:BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.play_circle)), title: Text(v['title']??'', maxLines:2), subtitle: Text(v['author']??''), onTap: () async { final ytUrl = Uri.parse("https://www.youtube.com/watch?v=${v['videoId']}"); await launchUrl(ytUrl, mode: LaunchMode.externalApplication); }); })),
      ]),
    );
  }
}
