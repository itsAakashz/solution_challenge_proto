import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'package:SoilGPT/contact_screen.dart';
import 'package:SoilGPT/soilLens_screen.dart';
import 'package:http/http.dart' as http;
import 'package:SoilGPT/mandi_screen.dart';
import 'dart:convert';
import 'package:SoilGPT/farmTube/video_feed_screen.dart';
import 'package:SoilGPT/agriEdu/agriEdu_screen.dart';
import 'package:SoilGPT/weather_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController nitrogenController = TextEditingController();
  final TextEditingController phosphorusController = TextEditingController();
  final TextEditingController potassiumController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController humidityController = TextEditingController();
  final TextEditingController phController = TextEditingController();
  final TextEditingController rainfallController = TextEditingController();

  String? savedLocation;
  bool isLoading = false;
  String recommendedCrop = "";
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<String, dynamic> weatherData = {};

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedLocation = prefs.getString('savedLocation');
    });
  }

  Future<void> _saveLocation(String location) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedLocation', location);
    setState(() {
      savedLocation = location;
    });
  }

  void _showLocationDialog() {
    final TextEditingController locationController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Location"),
          content: TextField(
            controller: locationController,
            decoration: InputDecoration(hintText: "Country/State/Region"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String location = locationController.text;
                if (location.isNotEmpty) {
                  _saveLocation(location);
                }
                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  Future<void> getCropRecommendation() async {
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      recommendedCrop = "";
    });

    final apiKey = "AIzaSyBX55Wxz61k-TpRhcuLyOGr8vU2PdFeS1Q";
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey");

    String prompt = """
You are a senior agronomist with 30 years of field experience working with the Food and Agriculture Organization (FAO). 
Your task is to provide precise crop recommendations based on comprehensive soil and climate analysis.

## Detailed Input Parameters:

### Soil Nutrient Analysis (mg/kg):
1. Nitrogen (N): ${nitrogenController.text} 
   - Optimal range: 20-50 mg/kg for most crops
2. Phosphorus (P): ${phosphorusController.text}
   - Optimal range: 10-30 mg/kg
3. Potassium (K): ${potassiumController.text}
   - Optimal range: 100-200 mg/kg

### Environmental Conditions:
1. Temperature: ${temperatureController.text}°C 
   - Classification:
     * <10°C: Cold
     * 10-25°C: Temperate
     * >25°C: Tropical/Hot
2. Humidity: ${humidityController.text}%
   - Ideal range: 40-70% for most crops
3. Soil pH: ${phController.text}
   - <6.5: Acidic (suitable for blueberries, potatoes)
   - 6.5-7.5: Neutral (ideal for most crops)
   - >7.5: Alkaline (suitable for asparagus, cabbage)
4. Rainfall: ${rainfallController.text} mm/year
   - <500mm: Arid
   - 500-1500mm: Moderate
   - >1500mm: High

### Geographic Context:
Region: ${savedLocation ?? "Not specified"}

## Required Analysis Methodology:

1. Soil Fertility Assessment:
   - Calculate fertility index using:
     Fertility Score = (N/50 + P/30 + K/200) × 100
   - Classify as:
     * <40: Low fertility
     * 40-70: Medium fertility
     * >70: High fertility

2. Climate Suitability Analysis:
   - Cross-reference temperature, humidity and rainfall with FAO crop climate requirements
   - Identify any climate stress factors (drought risk, heat stress, etc.)

3. Soil pH Compatibility:
   - Match pH level with crop-specific preferences
   - Recommend amendments if pH is suboptimal

## Output Format Requirements:

### Primary Recommendation (Most Suitable Crop)
- Crop Name: 
- Scientific Name:
- Suitability Score: (0-100)
- Key Advantages: 
- Yield Potential: 
- Market Value: 

### Secondary Options (2-3 alternatives)
[Same format as above for each]

### Detailed Soil Report:
1. Nutrient Analysis:
   - Nitrogen Status: 
   - Phosphorus Status:
   - Potassium Status:
   - Micronutrient Considerations:

2. Soil Health Indicators:
   - Organic Matter Estimate:
   - Water Holding Capacity:
   - Erosion Risk:

### Climate Adaptation Strategy:
1. Temperature Management:
2. Water Requirements:
3. Seasonal Timing:

### Cultivation Protocol:
1. Planting Guidelines:
   - Optimal planting dates
   - Seed rate/plant spacing
2. Fertilization Plan:
   - NPK requirements
   - Application schedule
3. Pest/Disease Management:
   - Common threats
   - Organic control options

### Economic Viability:
1. Input Costs:
2. Expected Returns:
3. Risk Factors:

### Sustainability Assessment:
1. Water Usage Efficiency:
2. Soil Conservation Impact:
3. Carbon Footprint:

Note: Provide all recommendations in metric units. Include specific varieties suited to the region when possible. Highlight any government subsidy programs or support schemes available for recommended crops.
""";
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 800
          }
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('candidates') && jsonResponse['candidates'].isNotEmpty) {
          setState(() {
            recommendedCrop = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          });
        } else {
          setState(() {
            recommendedCrop = "No valid response from API. Please try again.";
          });
        }
      } else {
        setState(() {
          recommendedCrop = "Error: ${response.statusCode}. Please check your connection and try again.";
        });
      }
    } catch (e) {
      setState(() {
        recommendedCrop = "Error: ${e.toString()}. Please try again later.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu,
                color: Colors.green[900],
                size: MediaQuery.of(context).size.width * 0.07),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Text(
            "SOIL GPT",
            style: GoogleFonts.poppins(
              fontSize: MediaQuery.of(context).size.width * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          Icon(Icons.eco_rounded,
              color: Colors.green[700],
              size: MediaQuery.of(context).size.width * 0.07),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.green[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/img.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Soil GPT',
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.06,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            _buildDrawerItem(Icons.home, 'Home', () => Navigator.pop(context)),
            _buildDrawerItem(Icons.cloud, 'Weather', () {
              if (savedLocation != null && savedLocation!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeatherScreen(
                      location: savedLocation!,
                      weatherData: weatherData,
                    ),
                  ),
                );
              } else {
                _showLocationDialog();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please set your location first'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }),
            _buildDrawerItem(Icons.cast_for_education, 'AgriEdu',
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => AgriEduScreen()))),
            _buildDrawerItem(Icons.camera_alt, 'Soil Lens',
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => SoilLensScreen()))),
            _buildDrawerItem(Icons.shopping_cart_rounded, 'Mandi Price',
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => MandiScreen()))),
            _buildDrawerItem(Icons.contact_page, 'Contact',
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => ContactScreen()))),
            _buildDrawerItem(Icons.ondemand_video_outlined, 'FarmTube',
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShortVideoFeed()))),
            _buildDrawerItem(Icons.location_on, 'Set Location', _showLocationDialog),
            Divider(),
            _buildDrawerItem(Icons.logout, 'Logout', logout, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: Column(
                  children: [
                    Icon(
                      Icons.grass,
                      size: MediaQuery.of(context).size.width * 0.2,
                      color: Colors.green[700],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Analyzing Soil...',
                      style: GoogleFonts.poppins(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                        color: Colors.green[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.green[100],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Growing the perfect recommendations for you',
                      style: GoogleFonts.poppins(
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle("Enter Soil & Weather Conditions"),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            _buildTextField(nitrogenController, "Nitrogen (N) mg/kg", Icons.science_outlined),
            _buildTextField(phosphorusController, "Phosphorus (P) mg/kg", Icons.thermostat_auto),
            _buildTextField(potassiumController, "Potassium (K) mg/kg", Icons.water_drop),
            _buildTextField(temperatureController, "Temperature (°C)", Icons.thermostat_rounded),
            _buildTextField(humidityController, "Humidity (%)", Icons.cloud),
            _buildTextField(phController, "pH Level", Icons.bubble_chart),
            _buildTextField(rainfallController, "Rainfall (mm)", Icons.grain),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            _buildRecommendButton(),
            if (isLoading)
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                child: _buildLoadingAnimation(),
              ),
            if (!isLoading && recommendedCrop.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Crop Recommendation:",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          recommendedCrop,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (savedLocation != null && savedLocation!.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                child: Text(
                  "Location: $savedLocation",
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[900],
                  ),
                ),
              ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: MediaQuery.of(context).size.width * 0.05,
          fontWeight: FontWeight.w600,
          color: Colors.green[900],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.01),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.85),
          prefixIcon: Icon(icon, color: Colors.green[700]),
          contentPadding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.02,
            horizontal: MediaQuery.of(context).size.width * 0.04,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendButton() {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ElevatedButton(
          onPressed: getCropRecommendation,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.02,
              horizontal: MediaQuery.of(context).size.width * 0.1,
            ),
            backgroundColor: Colors.green[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Recommend Crop",
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.045,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: MediaQuery.of(context).size.width * 0.04,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFb2f7b0), Color(0xFFd2f8d2)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      drawer: _buildDrawer(),
    );
  }
}