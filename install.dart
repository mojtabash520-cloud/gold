import 'dart:io';

// --- تنظیمات پروژه ---
const projectName = 'gold_calc_shagraf';

void main() async {
  print('🚀 Starting Automated Setup for $projectName...');

  // تشخیص سیستم عامل برای اجرای صحیح دستور
  String flutterCmd = Platform.isWindows ? 'flutter.bat' : 'flutter';
  
  // 1. Create Flutter Project
  print('📦 Creating Flutter project (using $flutterCmd)...');
  
  // نکته: استفاده از runInShell برای سازگاری بهتر با ویندوز
  final result = await Process.run(
    flutterCmd, 
    ['create', '--org', 'com.example', '--project-name', projectName, '.'],
    runInShell: true
  );
  
  if (result.exitCode != 0) {
    print('❌ Error creating project via CLI: ${result.stderr}');
    print('⚠️ نگران نباشید! تلاش می‌کنیم ساختار را دستی بسازیم...');
    // اگر دستور شکست خورد، پوشه‌های ضروری را دستی می‌سازیم
    await _createDir('lib');
    await _createDir('test'); 
    await _createDir('android/app/src/main');
    await _createDir('web');
  } else {
    print('✅ Flutter project created successfully.');
  }

  // 2. Create Directory Structure
  print('📂 Creating folder structure...');
  await _createDir('.github/workflows');
  await _createDir('assets/fonts');
  await _createDir('assets/images');
  
  // 3. Write Files
  print('📝 Writing configuration files...');
  
  // -- pubspec.yaml --
  await _writeFile('pubspec.yaml', r'''
name: gold_calc_shagraf
description: A luxury gold calculator application.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  tapsell_plus: ^2.2.0
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/images/icon.png"
  min_sdk_android: 21

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/fonts/
  fonts:
    - family: Vazirmatn
      fonts:
        - asset: assets/fonts/Vazirmatn.ttf
''');

  // -- GitHub Workflow --
  await _writeFile('.github/workflows/build.yml', r'''
name: Build Android APK
on:
  push:
    branches: [ "main", "master" ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      - name: Install Dependencies
        run: flutter pub get
      - name: Generate Icons
        run: flutter pub run flutter_launcher_icons
      - name: Build APK
        run: flutter build apk --release --split-per-abi --no-tree-shake-icons
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: gold-calculator-apk
          path: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
''');

  // -- Web Index --
  await _writeFile('web/index.html', r'''
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Gold Calculator">
  <title>محاسبه‌گر طلا شگرف</title>
  <link rel="manifest" href="manifest.json">
  <script type="text/javascript">
    window.flutterWebRenderer = "html";
  </script>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
''');

  // -- Android Build Gradle --
  await _writeFile('android/app/build.gradle', r'''
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace "com.example.gold_calc_shagraf"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.gold_calc_shagraf"
        minSdkVersion 21
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}
''');

  // -- Android Manifest --
  await _writeFile('android/app/src/main/AndroidManifest.xml', r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <application
        android:label="محاسبه‌گر طلا شگرف"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''');

  // -- MAIN.DART --
  await _writeFile('lib/main.dart', r'''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tapsell_plus/tapsell_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const appId = "YOUR_APP_KEY_HERE"; 
  TapsellPlus.instance.initialize(appId);
  runApp(const GoldCalcApp());
}

class GoldCalcApp extends StatelessWidget {
  const GoldCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محاسبه‌گر طلا شگرف',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'IR'),
      ],
      theme: ThemeData(
        fontFamily: 'Vazirmatn',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF004D40),
          primary: const Color(0xFF004D40),
          secondary: const Color(0xFFFFD700),
          surface: const Color(0xFFF5F5F5),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _goldPricePerGram = 4500000;
  String _result = "0";
  bool _isConvertingToMoney = true;
  String _zoneIdBanner = "YOUR_ZONE_ID_HERE";
  final NumberFormat _currencyFormat = NumberFormat("#,###", "en_US");

  @override
  void initState() {
    super.initState();
    _fetchGoldPrice();
  }

  Future<void> _fetchGoldPrice() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _goldPricePerGram = 4650000; 
      });
      _calculate();
    }
  }

  void _calculate() {
    if (_amountController.text.isEmpty) {
      setState(() => _result = "0");
      return;
    }
    String cleanInput = _amountController.text.replaceAll(',', '');
    double inputVal = double.tryParse(cleanInput) ?? 0;
    double calcResult;
    if (_isConvertingToMoney) {
      calcResult = inputVal * _goldPricePerGram;
      setState(() {
        _result = "${_currencyFormat.format(calcResult)} تومان";
      });
    } else {
      calcResult = inputVal / _goldPricePerGram;
      setState(() {
        _result = "${calcResult.toStringAsFixed(3)} گرم";
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isConvertingToMoney = !_isConvertingToMoney;
      _amountController.clear();
      _result = "0";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("محاسبه‌گر طلا شگرف", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
            onPressed: _fetchGoldPrice,
            tooltip: "بروزرسانی",
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text("قیمت لحظه‌ای طلای ۱۸ عیار", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics, color: Color(0xFFFFD700)),
                    const SizedBox(width: 8),
                    Text(
                      "${_currencyFormat.format(_goldPricePerGram)} تومان",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isConvertingToMoney ? "تبدیل طلا به تومان" : "تبدیل تومان به طلا",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              onPressed: _toggleMode,
                              icon: const Icon(Icons.swap_vert_circle, size: 32),
                              color: Theme.of(context).colorScheme.primary,
                            )
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _calculate(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: _isConvertingToMoney ? "وزن طلا (گرم)" : "مبلغ (تومان)",
                            suffixIcon: Icon(
                              _isConvertingToMoney ? Icons.balance : Icons.monetization_on,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text("نتیجه محاسبه:", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1), 
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            _result,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("محل نمایش بنر تبلیغاتی تپسل", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
''');

  print('✨ Project setup complete! Now you just need to add assets.');
}

Future<void> _createDir(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
    print('   Created directory: $path');
  }
}

Future<void> _writeFile(String path, String content) async {
  final file = File(path);
  // اطمینان از وجود پوشه والد قبل از نوشتن فایل
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
  print('   Updated file: $path');
}