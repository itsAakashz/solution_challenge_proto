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
  final String range = "Sheet1!A:J"; // Updated range to include all columns

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
      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('values')) {
          List<List<dynamic>> rows = (data['values'] as List)
              .map((row) => row is List ? row : [row])
              .toList();

          if (rows.length > 1) {
            List<Map<String, String>> tempMandiData = [];

            for (int i = 1; i < rows.length; i++) {
              if (rows[i].length >= 9) {
                tempMandiData.add({
                  "state": rows[i][0].toString(),
                  "district": rows[i][1].toString(),
                  "market": rows[i][2].toString(),
                  "commodity": rows[i][3].toString(),
                  "variety": rows[i][4].toString(),
                  "Min_x0020_Price": rows[i][7].toString(), // Index 7 for Min
                  "Max_x0020_Price": rows[i][8].toString(),  // Index 8 for Max
                  "Modal_x0020_Price": rows[i][9].toString(),// Index 9 for Modal
                });
              }
            }

            setState(() {
              mandiData = tempMandiData;
              states = mandiData.map((e) => e["state"]!).toSet().toList();
            });
          }
        }
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
            .where((e) => e["state"] == selectedState &&
            e["district"] == selectedDistrict &&
            e["market"] == selectedMarket)
            .map((e) => e["commodity"]!)
            .toSet()
            .toList();
        selectedCommodity = null;
      });
    }
  }

  void fetchData() {
    setState(() => isLoading = true);

    var filteredData = mandiData.where((e) =>
    e["state"] == selectedState &&
        e["district"] == selectedDistrict &&
        e["market"] == selectedMarket &&
        e["commodity"] == selectedCommodity).toList();

    setState(() {
      mandiData = filteredData;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadSheetData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mandi Prices"),
        backgroundColor: Colors.green[700],
      ),
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
              items: states
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
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
              items: filteredDistricts
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
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
              items: filteredMarkets
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              decoration: InputDecoration(labelText: "Market"),
            ),
            DropdownButtonFormField<String>(
              value: selectedCommodity,
              onChanged: (value) => setState(() => selectedCommodity = value),
              items: filteredCommodities
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              decoration: InputDecoration(labelText: "Commodity"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchData,
              child: Text("Get Prices", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            ),
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
                      title: Text("${item['commodity']} - ${item['variety']}"),
                      subtitle: Text("Market: ${item['market']}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Min: ₹${item['Min_x0020_Price']}"),
                          Text("Max: ₹${item['Max_x0020_Price']}"),
                          Text("Modal: ₹${item['Modal_x0020_Price']}"),
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