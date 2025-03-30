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
  final String range = "Sheet1!A:J";

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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('values')) {
          List<List<dynamic>> rows =
          (data['values'] as List).map((row) => row is List ? row : [row]).toList();

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
                  "Min_x0020_Price": rows[i][7].toString(),
                  "Max_x0020_Price": rows[i][8].toString(),
                  "Modal_x0020_Price": rows[i][9].toString(),
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

  void fetchData() {
    setState(() => isLoading = true);

    var filteredData = mandiData
        .where((e) =>
    e["state"] == selectedState &&
        e["district"] == selectedDistrict &&
        e["market"] == selectedMarket &&
        e["commodity"] == selectedCommodity)
        .toList();

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Mandi Prices", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildDropdown("State", states, selectedState, (value) {
              setState(() {
                selectedState = value;
                filterDistricts();
              });
            }),
            buildDropdown("District", filteredDistricts, selectedDistrict, (value) {
              setState(() {
                selectedDistrict = value;
                filterMarkets();
              });
            }),
            buildDropdown("Market", filteredMarkets, selectedMarket, (value) {
              setState(() {
                selectedMarket = value;
                filterCommodities();
              });
            }),
            buildDropdown("Commodity", filteredCommodities, selectedCommodity, (value) {
              setState(() => selectedCommodity = value);
            }),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchData,
              child: Text("Get Prices", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
            SizedBox(height: 20),
            if (isLoading)
              CircularProgressIndicator()
            else
              Expanded(
                child: mandiData.isEmpty
                    ? Center(child: Text("No data available", style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                  itemCount: mandiData.length,
                  itemBuilder: (context, index) {
                    var item = mandiData[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          "${item['commodity']} - ${item['variety']}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Market: ${item['market']}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Min: ₹${item['Min_x0020_Price']}",
                                style: TextStyle(color: Colors.green[800])),
                            Text("Max: ₹${item['Max_x0020_Price']}",
                                style: TextStyle(color: Colors.red[800])),
                            Text("Modal: ₹${item['Modal_x0020_Price']}",
                                style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget buildDropdown(
      String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        onChanged: onChanged,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
