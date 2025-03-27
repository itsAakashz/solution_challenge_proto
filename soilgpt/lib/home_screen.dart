import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'package:SoilGPT/contact_screen.dart';
import 'package:SoilGPT/soilLens_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController nitrogenController = TextEditingController();
  final TextEditingController phosphorusController = TextEditingController();
  final TextEditingController potassiumController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController humidityController = TextEditingController();
  final TextEditingController phController = TextEditingController();
  final TextEditingController rainfallController = TextEditingController();

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Light Green Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFb2f7b0), Color(0xFFd2f8d2)], // Light green gradient
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
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.green[900], size: 28),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Text(
            "SOIL GPT",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          Icon(Icons.eco_rounded, color: Colors.green[700], size: 28),
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
                        fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            _buildDrawerItem(Icons.home, 'Home', () => Navigator.pop(context)),
            _buildDrawerItem(Icons.camera_alt, 'Soil Lens',
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => SoilLensScreen()))),
            _buildDrawerItem(Icons.contact_page, 'Contact',
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => ContactScreen()))),
            Divider(),
            _buildDrawerItem(Icons.logout, 'Logout', logout, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle("Enter Soil & Weather Conditions"),
          SizedBox(height: 15),
          _buildTextField(nitrogenController, "Nitrogen (N)", Icons.science_outlined),
          _buildTextField(phosphorusController, "Phosphorus (P)", Icons.thermostat_auto),
          _buildTextField(potassiumController, "Potassium (K)", Icons.water_drop),
          _buildTextField(temperatureController, "Temperature (°C)", Icons.thermostat_rounded),
          _buildTextField(humidityController, "Humidity (%)", Icons.cloud),
          _buildTextField(phController, "pH Level", Icons.bubble_chart),
          _buildTextField(rainfallController, "Rainfall (mm)", Icons.grain),
          SizedBox(height: 20),
          _buildRecommendButton(),
        ],
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.green[900],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
        ),
      ),
    );
  }

  Widget _buildRecommendButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Recommend Crop",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
