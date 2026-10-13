import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const NgalongTubeV6());

class NgalongTubeV6 extends StatelessWidget {
  const NgalongTubeV6({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark(), home: const SearchPage());
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
  String log = "V6 - HARDCODE IP (Anti DNS)";
  bool loading = false;

  Future<void> search(String q) async {
    setState(() { loading = true; log = "Tembak IP YouTube langsung (ga pake DNS)..."; videos = []; });
    
    // IP YouTube asli (ga perlu DNS)
    List<String> ytIps = ["142.250.190.14", "142.250.4.14", "172.217.194.14"];
    
    for (var ip in ytIps) {
      try {
        HttpClient client = HttpClient();
        client.badCertificateCallback = (a,b,c) => true;
        client.connectionTimeout = const Duration(seconds: 10);
        
        var url = "https://$ip/results?search_query=${Uri.encodeComponent(q)}";
        var req = await client.getUrl(Uri.parse(url));
        req.headers.set('Host', 'www.youtube.com');
        req.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 13)');
        req.headers.set('Accept', 'text/html');
        
        var resp = await req.close().timeout(const Duration(seconds: 15));
        var body = await resp.transform(utf8.decoder).join();
        
        if (body.contains('videoId')) {
          var reg = RegExp(r'"videoId":"([a-zA-Z0-9_-]{11})"');
          var ids = reg.allMatches(body).map((m) => m.group(1)!).toSet().take(15).toList();
          if (ids.isNotEmpty) {
            setState(() {
              videos = ids.map((id) => {'videoId': id, 'title': 'Ngalong - $id', 'author': 'YouTube Direct IP $ip'}).toList();
              log = "TEMBUS ANJIR! IP $ip berhasil! Kurumi merestui wkwk";
              loading = false;
            });
            return;
          }
        }
      } catch (e) {
        log = "IP $ip gagal: $e, coba IP lain...";
      }
    }
    setState(() { log = "Semua IP gagal. Coba: 1. Matikan DNS Pribadi, 2. WARP Mode WARP bukan 1.1.1.1"; loading = false; });
  }

  @override
  void initState() { super.initState(); search(_controller.text); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("😈 NgalongTube V6 IP"), backgroundColor: Colors.black),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _controller, onSubmitted: search, decoration: InputDecoration(hintText: "cari apa...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => search(_controller.text))))),
        Padding(padding: const EdgeInsets.all(8), child: Text(log, style: const TextStyle(color: Colors.greenAccent, fontSize: 12), textAlign: TextAlign.center)),
        if (loading) const LinearProgressIndicator(color: Colors.purple),
        Expanded(child: ListView.builder(itemCount: videos.length, itemBuilder: (c,i){
          var v=videos[i];
          return ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network("https://i.ytimg.com/vi/${v['videoId']}/mqdefault.jpg", width: 100, fit: BoxFit.cover)),
            title: Text(v['title']??'', maxLines: 2, style: const TextStyle(fontSize:13)),
            subtitle: Text(v['author']??''),
            onTap: () async { await launchUrl(Uri.parse("https://www.youtube.com/watch?v=${v['videoId']}"), mode: LaunchMode.externalApplication); },
          );
        })),
      ]),
      floatingActionButton: FloatingActionButton.small(backgroundColor: Colors.purple, onPressed: () => search(_controller.text), child: const Icon(Icons.refresh)),
    );
  }
}
