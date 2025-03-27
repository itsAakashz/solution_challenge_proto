

---

# **SoilGPT 🌱🤖**  
An AI-powered soil analysis and recommendation system built with Flutter.

## **📌 Overview**
SoilGPT is a mobile application designed to assist farmers, gardeners, and agricultural professionals in analyzing soil conditions using AI-powered insights. The app takes input from users about soil type, moisture, and location, and provides recommendations on crop selection, soil treatment, and sustainable farming practices. 

## **🚀 Features**
### **1️⃣ AI-Powered Soil Analysis**
   - Uses machine learning models to analyze soil data.
   - Provides insights on soil composition, fertility, and crop compatibility.

### **2️⃣ Smart Recommendations**
   - Suggests suitable crops based on soil properties.
   - Recommends fertilizers and soil treatment strategies.

### **3️⃣ Real-time Weather Integration**
   - Fetches live weather updates to provide dynamic farming recommendations.
   - Offers alerts for extreme weather conditions.

### **4️⃣ Image-Based Soil Detection (Future Scope)**
   - Uses image recognition to identify soil type from uploaded photos.
   - Provides automated analysis without manual input.

### **5️⃣ User-friendly Interface**
   - Simple and intuitive UI for easy navigation.
   - Supports multiple languages (upcoming feature).

---

## **🛠 Tech Stack**
| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform mobile development |
| **Dart** | Programming language for Flutter |
| **Firebase** | Backend services (authentication, database) |
| **Google Maps API** | Location-based soil insights |
| **OpenWeather API** | Real-time weather data |
| **TensorFlow Lite** | AI model for soil analysis (planned feature) |

---

## **📥 Installation & Setup**
### **1️⃣ Prerequisites**
- Install [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Install [Android Studio](https://developer.android.com/studio) (for Android development)
- Install Xcode (for iOS development)
- Set up [Firebase](https://firebase.google.com/) for authentication and database.

### **2️⃣ Clone the Repository**
```sh
git clone https://github.com/yourusername/SoilGPT.git
cd SoilGPT
```

### **3️⃣ Install Dependencies**
```sh
flutter pub get
```

### **4️⃣ Configure Firebase**
- Create a Firebase project and add an Android/iOS app.
- Download the `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) and place it in the appropriate folder (`android/app/` or `ios/Runner/`).

### **5️⃣ Run the App**
For Android:
```sh
flutter run
```

For iOS:
```sh
flutter run --no-codesign
```

---

## **🔑 App Signing & APK Build**
### **1️⃣ Generate a Keystore File**
```sh
keytool -genkey -v -keystore ~/my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
```

### **2️⃣ Create a `keystore.properties` File**
Inside `android/`, create `keystore.properties`:
```
storeFile=your_keystore_file_path
storePassword=your_keystore_password
keyAlias=your_key_alias
keyPassword=your_key_password
```

### **3️⃣ Build the APK**
```sh
flutter build apk --release
```
or for Android App Bundle:
```sh
flutter build appbundle
```

---

## **🖥️ Project Structure**
```
SoilGPT/
│── android/           # Android-specific code
│── ios/               # iOS-specific code
│── lib/               # Main Flutter application code
│   ├── models/        # Data models
│   ├── screens/       # UI screens
│   ├── services/      # API & backend services
│   ├── widgets/       # Reusable components
│   ├── main.dart      # Entry point of the app
│── assets/            # Images, icons, and other assets
│── pubspec.yaml       # Dependencies and configuration
│── README.md          # Project documentation
```

---

## **🛣️ Future Enhancements**
- **📸 Image-based soil detection using AI**
- **🌎 Region-based crop recommendation**
- **📲 Offline support for remote farmers**
- **📊 Data visualization & soil health trends**

---

## **📩 Contributing**
We welcome contributions! 🚀  
1. Fork the repository.
2. Create a new branch: `git checkout -b feature-xyz`
3. Commit your changes: `git commit -m "Add feature XYZ"`
4. Push to the branch: `git push origin feature-xyz`
5. Create a pull request.

---

## **📝 License**
This project is licensed under the MIT License.

---

## **📧 Contact**
For queries, suggestions, or collaborations:  
📧 **Aakash Gupta** – [gzatrop@gmail.com](mailto:gzatrop@gmail.com)  
🌍 **Project Repository** – [GitHub](https://github.com/itsAakashz/SoilGPT)

---

