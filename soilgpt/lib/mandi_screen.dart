import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AgricultureLoadingAnimation extends StatefulWidget {
  final double size;

  const AgricultureLoadingAnimation({Key? key, this.size = 100.0}) : super(key: key);

  @override
  _AgricultureLoadingAnimationState createState() => _AgricultureLoadingAnimationState();
}

class _AgricultureLoadingAnimationState extends State<AgricultureLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _AgriculturePainter(rotationValue: _rotationAnimation.value),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Text(
            "Loading Market Data...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.green[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgriculturePainter extends CustomPainter {
  final double rotationValue;

  _AgriculturePainter({required this.rotationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    // Draw sun
    final sunPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.25, sunPaint);

    // Draw sun rays - animated rotation
    final rayPaint = Paint()
      ..color = Colors.amber.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * pi / 180 + rotationValue;
      final start = Offset(
        center.dx + (radius * 0.25) * cos(angle),
        center.dy + (radius * 0.25) * sin(angle),
      );
      final end = Offset(
        center.dx + (radius * 0.5) * cos(angle),
        center.dy + (radius * 0.5) * sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }

    // Draw wheat stalks
    final stalkPaint = Paint()
      ..color = Colors.green[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final wheatPaint = Paint()
      ..color = Colors.amber[800]!
      ..style = PaintingStyle.fill;

    // Draw ground
    final groundPaint = Paint()
      ..color = Colors.brown[400]!
      ..style = PaintingStyle.fill;



        // Draw wheat plants
        for (int i = 0; i < 8; i++) {
      final position = i * (size.width / 7);
      final height = radius * 0.4 + (i % 3) * 10;

      // Draw stalk
      final stalkPath = Path()
        ..moveTo(position, center.dy + radius * 0.6)
        ..quadraticBezierTo(
          position + 10,
          center.dy + radius * 0.6 - height * 0.7,
          position,
          center.dy + radius * 0.6 - height,
        );
      canvas.drawPath(stalkPath, stalkPaint);

      // Draw wheat head
      final headCenter = Offset(position, center.dy + radius * 0.6 - height);
      canvas.drawCircle(headCenter, 8, wheatPaint);

      // Draw wheat grains
      for (double j = 0; j < 2 * pi; j += pi / 4) {
        final grainPos = Offset(
          headCenter.dx + 6 * cos(j + rotationValue * 0.5),
          headCenter.dy + 6 * sin(j + rotationValue * 0.5),
        );
        canvas.drawCircle(grainPos, 2, wheatPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MandiScreen extends StatefulWidget {
  @override
  _MandiScreenState createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  final String apiKey = "AIzaSyCYjyGPPWcarkZFuIld4Xz6ZIjwitACP9o";
  final String sheetId = "1ZwFVREtFYSU9eiIDDmxkUu9zjdCF9LRZcaFo9ITsOc4";
  final String range = "Sheet1!A:J";

  List<Map<String, String>> mandiData = [];
  List<Map<String, String>> filteredMandiData = [];

  List<String> states = [];
  List<String> filteredDistricts = [];
  List<String> filteredMarkets = [];
  List<String> filteredCommodities = [];

  String? selectedState;
  String? selectedDistrict;
  String? selectedMarket;
  String? selectedCommodity;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadSheetData();
  }

  Future<void> loadSheetData() async {
    setState(() => isLoading = true);

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
              states = mandiData.map((e) => e["state"]!).toSet().toList()..sort();
              isLoading = false;
            });
          }
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
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
            .toList()..sort();
        selectedDistrict = null;
        selectedMarket = null;
        selectedCommodity = null;
        filteredMarkets = [];
        filteredCommodities = [];
        filteredMandiData = [];
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
            .toList()..sort();
        selectedMarket = null;
        selectedCommodity = null;
        filteredCommodities = [];
        filteredMandiData = [];
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
            .toList()..sort();
        selectedCommodity = null;
        filteredMandiData = [];
      });
    }
  }

  void fetchData() {
    setState(() => isLoading = true);

    var tempFilteredData = mandiData
        .where((e) =>
    e["state"] == selectedState &&
        e["district"] == selectedDistrict &&
        e["market"] == selectedMarket &&
        e["commodity"] == selectedCommodity)
        .toList();

    Future.delayed(Duration(seconds: 1), () {
      // Simulate network delay for demo purposes
      setState(() {
        filteredMandiData = tempFilteredData;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Mandi Prices", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: isLoading && mandiData.isEmpty
          ? AgricultureLoadingAnimation(size: 150)
          : Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            if (isPortrait) ...[
              _buildFilterSection(isPortrait, screenWidth),
              SizedBox(height: 20),
              _buildResultsSection(),
            ] else ...[
              // Landscape layout
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: _buildFilterSection(isPortrait, screenWidth),
                      ),
                    ),
                    SizedBox(width: 20),
                    Flexible(
                      flex: 3,
                      child: _buildResultsSection(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isPortrait, double screenWidth) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          children: [
            Text("Filter Prices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
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
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (selectedState != null &&
                    selectedDistrict != null &&
                    selectedMarket != null &&
                    selectedCommodity != null)
                    ? fetchData
                    : null,
                child: Text("Get Prices", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (isLoading)
                Expanded(child: AgricultureLoadingAnimation(size: 120))
              else if (filteredMandiData.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      selectedCommodity == null
                          ? "Select filters and click 'Get Prices'"
                          : "No data available",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredMandiData.length,
                    itemBuilder: (context, index) {
                      var item = filteredMandiData[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${item['commodity']}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "${item['variety']}",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "${item['market']}",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Min: ₹${item['Min_x0020_Price']}",
                                      style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      "Max: ₹${item['Max_x0020_Price']}",
                                      style: TextStyle(
                                          color: Colors.red[800],
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      "Modal: ₹${item['Modal_x0020_Price']}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
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
      ),
    );
  }

  Widget buildDropdown(
      String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: selectedValue,
        onChanged: items.isEmpty ? null : onChanged,
        items: items
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text(
            e,
            overflow: TextOverflow.ellipsis,
          ),
        ))
            .toList(),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        dropdownColor: Colors.grey[50],
      ),
    );
  }
}