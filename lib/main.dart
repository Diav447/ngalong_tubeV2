import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const NgalongTubeV4());

class NgalongTubeV4 extends StatelessWidget {
  const NgalongTubeV4({super.key});
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
  String log = "V4 - Direct YouTube (No Blokir)";
  bool loading = false;

  Future<void> search(String q) async {
    if (q.isEmpty) return;
    setState(() { loading = true; log = "Nembak YouTube langsung..."; videos = []; });

    try {
      // Ini endpoint YouTube asli, 100% ga diblock di Indo
      final url = Uri.parse("https://www.youtube.com/results?search_query=${Uri.encodeComponent(q)}");
      final res = await http.get(url, headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept-Language": "en-US,en;q=0.9",
      }).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        String body = res.body;
        // Ambil bagian ytInitialData
        final exp = RegExp(r'ytInitialData\s*=\s*(\{.+?\});', dotAll: true);
        final match = exp.firstMatch(body);
        if (match!= null) {
          var jsonData = jsonDecode(match.group(1)!);
          // parsing sederhana
          List found = [];
          void findVideos(dynamic obj) {
            if (obj is Map) {
              if (obj.containsKey('videoId') && obj.containsKey('title')) {
                var title = "";
                try {
                  if (obj['title'] is Map && obj['title']['runs']!= null) {
                    title = obj['title']['runs'][0]['text'];
                  } else if (obj['title'] is String) {
                    title = obj['title'];
                  } else if (obj['title']['simpleText']!= null) {
                    title = obj['title']['simpleText'];
                  }
                } catch (_) {}
                if (title.isNotEmpty) {
                  found.add({
                    'videoId': obj['videoId'],
                    'title': title,
                    'author': obj['longBylineText']?['runs']?[0]?['text']?? "YouTube"
                  });
                }
              }
              obj.forEach((k, v) => findVideos(v));
            } else if (obj is List) {
              for (var v in obj) findVideos(v);
            }
          }
          findVideos(jsonData);

          // deduplicate
          var seen = <String>{};
          var unique = found.where((v) => seen.add(v['videoId'])).take(20).toList();

          if (unique.isNotEmpty) {
            setState(() { videos = unique; log = "Tembus! Dapet ${unique.length} video langsung dari YouTube"; loading = false; });
            return;
          }
        }
        // fallback regex kalo ytInitialData gagal
        var reg = RegExp(r'"videoId":"([a-zA-Z0-9_-]{11})"');
        var ids = reg.allMatches(body).map((m) => m.group(1)!).toSet().take(15).toList();
        if (ids.isNotEmpty) {
          setState(() {
            videos = ids.map((id) => {'videoId': id, 'title': 'Video $id', 'author': 'YouTube'}).toList();
            log = "Tembus via regex! ${ids.length} video";
            loading = false;
          });
          return;
        }
      }
      setState(() { log = "YouTube ga ngasih data: ${res.statusCode}"; loading = false; });
    } catch (e) {
      setState(() { log = "Error: $e - Coba klik refresh lagi"; loading = false; });
    }
  }

  @override
  void initState() { super.initState(); search(_controller.text); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("😈 NgalongTube V4 DIRECT"), backgroundColor: Colors.black),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _controller, onSubmitted: search, decoration: InputDecoration(hintText: "cari apa...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => search(_controller.text))))),
          Padding(padding: const EdgeInsets.all(8), child: Text(log, style: const TextStyle(color: Colors.greenAccent, fontSize: 12), textAlign: TextAlign.center)),
          if (loading) const LinearProgressIndicator(color: Colors.purple),
          Expanded(child: ListView.builder(itemCount: videos.length, itemBuilder: (c, i) {
            var v = videos[i];
            return ListTile(
              leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network("https://i.ytimg.com/vi/${v['videoId']}/mqdefault.jpg", width: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.play_circle))),
              title: Text(v['title']?? '', maxLines: 2, style: const TextStyle(fontSize: 13)),
              subtitle: Text(v['author']?? '', style: const TextStyle(fontSize: 11)),
              onTap: () async { final ytUrl = Uri.parse("https://www.youtube.com/watch?v=${v['videoId']}"); await launchUrl(ytUrl, mode: LaunchMode.externalApplication); },
            );
          })),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(backgroundColor: Colors.purple, onPressed: () => search(_controller.text), child: const Icon(Icons.refresh)),
    );
  }
}
