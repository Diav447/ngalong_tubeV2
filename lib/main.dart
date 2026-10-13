import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const NgalongTubeV3());

class NgalongTubeV3 extends StatelessWidget {
  const NgalongTubeV3({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SearchPage(),
    );
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
  String log = "V3 - Mode Brutal Active";
  bool loading = false;

  // Proxy yang masih tembus di Indo
  String proxify(String url, int type) {
    if (type == 0) return "https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}";
    if (type == 1) return "https://corsproxy.io/?${Uri.encodeComponent(url)}";
    return "https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(url)}";
  }

  Future<void> search(String q) async {
    if (q.isEmpty) return;
    setState(() {
      loading = true;
      log = "Nge-bypass blokir...";
      videos = [];
    });

    List<String> apis = [
      "https://inv.nadeko.net/api/v1/search?q=${Uri.encodeComponent(q)}",
      "https://yewtu.be/api/v1/search?q=${Uri.encodeComponent(q)}",
      "https://pipedapi.kavin.rocks/search?q=${Uri.encodeComponent(q)}",
      "https://api.piped.privacydev.net/search?q=${Uri.encodeComponent(q)}",
    ];

    for (var api in apis) {
      for (int p = 0; p < 3; p++) {
        try {
          var proxied = proxify(api, p);
          var res = await http.get(Uri.parse(proxied)).timeout(const Duration(seconds: 15));
          if (res.statusCode == 200 && res.body.length > 100) {
            var data = jsonDecode(res.body);
            List list = [];
            if (data is Map && data.containsKey('items')) {
              // format piped
              list = data['items'];
              list = list.map((e) => {
                'videoId': e['url']?.toString().split('v=').last ?? e['url'].toString().split('/').last,
                'title': e['title'],
                'author': e['uploaderName']
              }).toList();
            } else {
              // format invidious
              list = data;
            }
            var filtered = list.where((v) => v['videoId'] != null).toList();
            if (filtered.isNotEmpty) {
              setState(() {
                videos = filtered;
                log = "Dapet ${filtered.length} video! Proxy $p tembus.";
                loading = false;
              });
              return;
            }
          }
        } catch (e) {
          // lanjut proxy lain
        }
      }
    }

    setState(() {
      loading = false;
      log = "Masih ke-block semua. Coba: 1. Nyalain 1.1.1.1 (WARP), 2. Klik search lagi";
    });
  }

  @override
  void initState() {
    super.initState();
    search(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("😈 NgalongTube V3 Brutal"), backgroundColor: Colors.black),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              onSubmitted: search,
              decoration: InputDecoration(
                hintText: "cari apa...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => search(_controller.text)),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(8), child: Text(log, style: const TextStyle(color: Colors.purpleAccent, fontSize: 12), textAlign: TextAlign.center)),
          if (loading) const LinearProgressIndicator(color: Colors.purple),
          Expanded(
            child: ListView.builder(
              itemCount: videos.length,
              itemBuilder: (c, i) {
                var v = videos[i];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network("https://i.ytimg.com/vi/${v['videoId']}/mqdefault.jpg", width: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.play_circle)),
                  ),
                  title: Text(v['title'] ?? '', maxLines: 2, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(v['author'] ?? '', style: const TextStyle(fontSize: 11)),
                  onTap: () async {
                    final ytUrl = Uri.parse("https://www.youtube.com/watch?v=${v['videoId']}");
                    await launchUrl(ytUrl, mode: LaunchMode.externalApplication);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Colors.purple,
        onPressed: () => search(_controller.text),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
