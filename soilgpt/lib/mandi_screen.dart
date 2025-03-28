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
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text("Mandi Prices", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(stateController, "State", Icons.location_on),
            SizedBox(height: 10),
            _buildTextField(districtController, "District", Icons.map),
            SizedBox(height: 10),
            _buildTextField(marketController, "Market", Icons.store),
            SizedBox(height: 10),
            _buildTextField(commodityController, "Commodity", Icons.shopping_cart),
            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: fetchData,
              child: Text("Get Prices", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),

            SizedBox(height: 20),

            if (isLoading) CircularProgressIndicator(color: Colors.green[700]),

            Expanded(
              child: mandiData.isEmpty
                  ? Center(child: Text("No data available", style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                itemCount: mandiData.length,
                itemBuilder: (context, index) {
                  var item = mandiData[index];
                  return Card(
                    color: Colors.green[100],
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text("${item['commodity']} - ${item['variety'] ?? 'N/A'}",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Market: ${item['market']}",
                          style: TextStyle(color: Colors.black54)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Min: ₹${item['min_price'] ?? 'N/A'}",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text("Max: ₹${item['max_price'] ?? 'N/A'}",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green[700]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
