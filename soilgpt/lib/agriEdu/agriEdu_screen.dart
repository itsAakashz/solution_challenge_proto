import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AgriEduScreen extends StatefulWidget {
  @override
  _GenreListScreenState createState() => _GenreListScreenState();
}

class _GenreListScreenState extends State<AgriEduScreen> {
  late Future<List<dynamic>> _genres;

  @override
  void initState() {
    super.initState();
    _genres = fetchGenres();  // Fetch data when the screen loads
  }

  // Define fetchGenres method
  Future<List<dynamic>> fetchGenres() async {
    final url = "https://raw.githubusercontent.com/itsAakashz/solution_challenge_proto/main/soilgpt/assets/articleGenre.json";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['genre']; // Extract the 'genre' array
    } else {
      throw Exception('Failed to load genres');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Article Genres")),
      body: FutureBuilder<List<dynamic>>(
        future: _genres,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading genres"));
          } else {
            List<dynamic> genres = snapshot.data!;
            return ListView.builder(
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                return ListTile(
                  title: Text(genre['title']),
                  subtitle: Text(genre['url']),
                  onTap: () {
                    // Open article URL
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
