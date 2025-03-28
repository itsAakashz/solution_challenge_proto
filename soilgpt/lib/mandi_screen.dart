import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MandiScreen extends StatefulWidget {
  @override
  _MandiScreenState createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  final String apiKey = "579b464db66ec23bdd000001f1ba15c97c9e48d373e6f663496f034b";
  final String baseUrl = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070";

  final TextEditingController stateController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController marketController = TextEditingController();
  final TextEditingController commodityController = TextEditingController();

  List<dynamic> mandiData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set initial values
    stateController.text = "Bihar";
    districtController.text = "Sheohar";
    marketController.text = "Sheohar";
    commodityController.text = "Rice";
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    String url = "$baseUrl?api-key=$apiKey&format=json"
        "&filters[state.keyword]=${Uri.encodeComponent(stateController.text)}"
        "&filters[district]=${Uri.encodeComponent(districtController.text)}"
        "&filters[market]=${Uri.encodeComponent(marketController.text)}"
        "&filters[commodity]=${Uri.encodeComponent(commodityController.text)}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          mandiData = data["records"] ?? [];
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mandi Prices")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Text input fields
            TextFormField(
              controller: stateController,
              decoration: InputDecoration(
                labelText: "State",
                hintText: "e.g. Bihar, Uttar Pradesh",
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: districtController,
              decoration: InputDecoration(
                labelText: "District",
                hintText: "e.g. Sheohar, Patna",
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: marketController,
              decoration: InputDecoration(
                labelText: "Market",
                hintText: "e.g. Sheohar, Gaya",
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: commodityController,
              decoration: InputDecoration(
                labelText: "Commodity",
                hintText: "e.g. Rice, Wheat",
              ),
            ),
            SizedBox(height: 20),

            // Fetch data button
            ElevatedButton(
              onPressed: fetchData,
              child: Text("Get Prices"),
            ),

            SizedBox(height: 20),

            // Show loading indicator
            if (isLoading) CircularProgressIndicator(),

            // Display fetched data
            Expanded(
              child: mandiData.isEmpty
                  ? Center(child: Text("No data available"))
                  : ListView.builder(
                itemCount: mandiData.length,
                itemBuilder: (context, index) {
                  var item = mandiData[index];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text("${item['commodity']} - ${item['variety'] ?? 'N/A'}"),
                      subtitle: Text("Market: ${item['market']}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Min: ₹${item['min_price'] ?? 'N/A'}"),
                          Text("Max: ₹${item['max_price'] ?? 'N/A'}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}