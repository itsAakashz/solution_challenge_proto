import 'package:flutter/material.dart';

class AgriEduScreen extends StatelessWidget {
  final List<Map<String, String>> topics = [
    {
      "title": "Sustainable Farming Practices",
      "url": "https://example.com/sustainable-farming"
    },
    {
      "title": "Seed Buying Guides",
      "url": "https://example.com/seed-buying-guide"
    },
    {
      "title": "Alternatives to Chemical Fertilizers",
      "url": "https://example.com/organic-fertilizers"
    },
    {
      "title": "Agricultural Waste Management",
      "url": "https://example.com/waste-management"
    },
  ];

  void _openLink(BuildContext context, String url) {
    // Implement webview or url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Opening: $url")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AgriEdu - Learn Agriculture")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: topics.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: InkWell(
                onTap: () => _openLink(context, topics[index]["url"]!),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.article, color: Colors.green[700]),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          topics[index]["title"]!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
