import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MandiScreen extends StatefulWidget {
  @override
  _MandiScreenState createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  final String apiKey = "AIzaSyCYjyGPPWcarkZFuIld4Xz6ZIjwitACP9o";
  final String sheetId = "1ZwFVREtFYSU9eiIDDmxkUu9zjdCF9LRZcaFo9ITsOc4";
  final String range = "Sheet1!A:D"; // Adjust according to your sheet structure

  List<Map<String, String>> mandiData = [];

  List<String> states = [];
  List<String> filteredDistricts = [];
  List<String> filteredMarkets = [];
  List<String> filteredCommodities = [];

  String? selectedState;
  String? selectedDistrict;
  String? selectedMarket;
  String? selectedCommodity;

  bool isLoading = false;

  Future<void> loadSheetData() async {
    final url =
        "https://sheets.googleapis.com/v4/spreadsheets/$sheetId/values/$range?key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      print("API Response: ${response.body}"); // Debugging

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('values')) {
          List<List<dynamic>> rows =
          (data['values'] as List).map((row) => row is List ? row : [row]).toList();

          if (rows.length > 1) {
            List<Map<String, String>> tempMandiData = [];

            for (int i = 1; i < rows.length; i++) {
              if (rows[i].length >= 4) {
                tempMandiData.add({
                  "state": rows[i][0].toString(),
                  "district": rows[i][1].toString(),
                  "market": rows[i][2].toString(),
                  "commodity": rows[i][3].toString(),
                });
              }
            }

            setState(() {
              mandiData = tempMandiData;
              states = mandiData.map((e) => e["state"]!).toSet().toList();
            });

            print("✅ States Loaded: $states");
          } else {
            print("❌ No data rows found.");
          }
        } else {
          print("❌ No 'values' key in response.");
        }
      } else {
        print("❌ Failed to load data: ${response.body}");
      }
    } catch (e) {
      print("Error loading sheet data: $e");
    }
  }

  void filterDistricts() {
    if (selectedState != null) {
      setState(() {
        filteredDistricts = mandiData
            .where((e) => e["state"] == selectedState)
            .map((e) => e["district"]!)
            .toSet()
            .toList();
        selectedDistrict = null;
        selectedMarket = null;
        selectedCommodity = null;
        filteredMarkets = [];
        filteredCommodities = [];
      });
    }
  }

  void filterMarkets() {
    if (selectedDistrict != null) {
      setState(() {
        filteredMarkets = mandiData
            .where((e) => e["state"] == selectedState && e["district"] == selectedDistrict)
            .map((e) => e["market"]!)
            .toSet()
            .toList();
        selectedMarket = null;
        selectedCommodity = null;
        filteredCommodities = [];
      });
    }
  }

  void filterCommodities() {
    if (selectedMarket != null) {
      setState(() {
        filteredCommodities = mandiData
            .where((e) =>
        e["state"] == selectedState &&
            e["district"] == selectedDistrict &&
            e["market"] == selectedMarket)
            .map((e) => e["commodity"]!)
            .toSet()
            .toList();
        selectedCommodity = null;
      });
    }
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    final mandiApiKey ="579b464db66ec23bdd0000012713f4d953de4b7c719eaa034cc65f1a";
    final String apiUrl =
        "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
        "?api-key=$mandiApiKey&format=json"
        "&filters[state]=$selectedState"
        "&filters[district]=$selectedDistrict"
        "&filters[market]=$selectedMarket"
        "&filters[commodity]=$selectedCommodity";


    try {
      print("🔍 Fetching: $apiUrl"); // Log API request URL

      final response = await http.get(Uri.parse(apiUrl));
      print("📩 Response Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data["records"] != null) {
          setState(() {
            mandiData = List<Map<String, String>>.from(data["records"]);
          });
        } else {
          throw Exception("⚠️ No records found");
        }
      } else {
        throw Exception("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Error fetching Mandi data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }


  @override
  void initState() {
    super.initState();
    loadSheetData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mandi Prices"), backgroundColor: Colors.green[700],),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedState,
              onChanged: (value) {
                setState(() {
                  selectedState = value;
                  filterDistricts();
                });
              },
              items: states.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              decoration: InputDecoration(labelText: "State"),
            ),
            DropdownButtonFormField<String>(
              value: selectedDistrict,
              onChanged: (value) {
                setState(() {
                  selectedDistrict = value;
                  filterMarkets();
                });
              },
              items: filteredDistricts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              decoration: InputDecoration(labelText: "District"),
            ),
            DropdownButtonFormField<String>(
              value: selectedMarket,
              onChanged: (value) {
                setState(() {
                  selectedMarket = value;
                  filterCommodities();
                });
              },
              items: filteredMarkets.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              decoration: InputDecoration(labelText: "Market"),
            ),
            DropdownButtonFormField<String>(
              value: selectedCommodity,
              onChanged: (value) => setState(() => selectedCommodity = value),
              items: filteredCommodities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              decoration: InputDecoration(labelText: "Commodity"),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: fetchData, child: Text("Get Prices", style: TextStyle(color: Colors.white),),style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700])),
            SizedBox(height: 20),
            if (isLoading) CircularProgressIndicator(),
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