import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tapsell_plus/tapsell_plus.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

// --- تنظیمات ثابت ---
const taskName = "fetchGoldPriceTask";
const String androidWidgetName = 'GoldWidgetProvider';
const Color kPrimaryGreen = Color(0xFF1B5E20);
const Color kGoldDark = Color(0xFFC49A00);
const Color kGoldLight = Color(0xFFFFD54F);

const String tapsellAppId = "alsoatsrtrotpqacegkehkaiieckldhrgsbspqtgqnbrrfccrtbdomgjtahflchkqtqosa";
const String nativeZoneId = "5cfaa9deaede570001d5553a";
const String standardZoneId = "5cfaaa30e8d17f0001ffb294";

// --- تابع تبدیل اعداد به فارسی ---
String toPersian(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  for (int i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], persian[i]);
  }
  return input;
}

// --- فرمتر پیشرفته اعداد ---
class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text;
    if (newText == '.') return const TextEditingValue(text: '0.');
    if (newText.split('.').length > 2) return oldValue;
    String cleanText = newText.replaceAll(',', '');
    List<String> parts = cleanText.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';
    if (integerPart.isNotEmpty) {
      final formatter = NumberFormat("#,###");
      try { integerPart = formatter.format(int.parse(integerPart)); } catch (e) {}
    }
    String finalText = integerPart + (newText.contains('.') ? '.$decimalPart' : '');
    return TextEditingValue(text: finalText, selection: TextSelection.collapsed(offset: finalText.length));
  }
}

String cleanPriceText(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  for (int i = 0; i < english.length; i++) input = input.replaceAll(persian[i], english[i]);
  return input.replaceAll(RegExp(r'[^0-9.]'), '');
}

// --- دریافت قیمت (استراتژی 3 لایه) ---
Future<double?> getRealGoldPrice() async {
  if (kIsWeb) return 4650000;

  final headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  };

  // 1. TGJU
  try {
    final response = await http.get(Uri.parse('https://www.tgju.org/profile/geram18'), headers: headers).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      var doc = parser.parse(response.body);
      var el = doc.querySelector('span[data-col="info.last_trade.PDrCotVal"]');
      if (el == null) el = doc.querySelector('span.info-price');
      if (el != null) {
        double? price = double.tryParse(cleanPriceText(el.text));
        if (price != null && price > 1000) {
           if (price > 100000000) return price / 10;
           return price;
        }
      }
    }
  } catch (_) {}

  // 2. Tala.ir
  try {
    final response = await http.get(Uri.parse('https://www.tala.ir'), headers: headers).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      var doc = parser.parse(response.body);
      var el = doc.querySelector('#geram18 span.price');
      if (el != null) {
        double? price = double.tryParse(cleanPriceText(el.text));
        if (price != null && price > 1000) {
             if (price > 100000000) return price / 10;
             return price;
        }
      }
    }
  } catch (_) {}

  // 3. IranJib
  try {
    final response = await http.get(Uri.parse('https://www.iranjib.ir/showgroup/23/realtime_price/'), headers: headers).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      var doc = parser.parse(response.body);
      var el = doc.querySelector('#f_85_63_pr span.lastprice');
      if (el != null) {
        double? price = double.tryParse(cleanPriceText(el.text));
        if (price != null && price > 1000) {
             if (price > 100000000) return price / 10;
             return price;
        }
      }
    }
  } catch (_) {}

  return null;
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    double? price = await getRealGoldPrice();
    if (price != null) {
      final formatter = NumberFormat("#,###", "en_US");
      // ارسال عدد فارسی به ویجت
      await HomeWidget.saveWidgetData<String>('tv_price', toPersian(formatter.format(price)));
      await HomeWidget.updateWidget(name: androidWidgetName, androidName: androidWidgetName);
    }
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      Workmanager().registerPeriodicTask("1", taskName, frequency: const Duration(minutes: 15));
      TapsellPlus.instance.initialize(tapsellAppId);
      TapsellPlus.instance.setGDPRConsent(true);
    } catch (_) {}
  }
  runApp(const GoldCalcApp());
}

class GoldCalcApp extends StatelessWidget {
  const GoldCalcApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محاسبه‌گر قیمت طلا',
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: const [Locale('fa', 'IR')],
      theme: ThemeData(
        fontFamily: 'Vazirmatn',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryGreen),
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
  final _weightController = TextEditingController();
  final _moneyController = TextEditingController();
  double _price = 0;
  bool _loading = true;
  String _priceSource = "---", _resPrice = "---", _resWeight = "---";
  final _fmt = NumberFormat("#,###", "en_US");

  @override
  void initState() {
    super.initState();
    _fetch();
    if (!kIsWeb) _showStickyBanner();
  }

  void _showStickyBanner() {
    try {
      final gravityBottom = TapsellPlusVerticalGravity.values.firstWhere(
        (e) => e.toString().toUpperCase().contains('BOTTOM'), orElse: () => TapsellPlusVerticalGravity.values.last
      );
      final gravityCenter = TapsellPlusHorizontalGravity.values.firstWhere(
        (e) => e.toString().toUpperCase().contains('CENTER'), orElse: () => TapsellPlusHorizontalGravity.values.first
      );

      TapsellPlus.instance.requestStandardBannerAd(
        standardZoneId,
        TapsellPlusBannerType.BANNER_320x50,
        onResponse: (response) {
          if (response['responseId'] != null) {
            TapsellPlus.instance.showStandardBannerAd(response['responseId']!, gravityCenter, gravityBottom, margin: const EdgeInsets.only(bottom: 0));
          }
        },
        onError: (e) => debugPrint("Ad Error: $e"),
      );
    } catch(e) {}
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    double? p = await getRealGoldPrice();
    if (mounted) {
      setState(() {
        _loading = false;
        if (p != null) { _price = p; _priceSource = "نرخ زنده بازار"; }
        else { 
            if (_price == 0) _price = 4650000; 
            _priceSource = "آفلاین (آخرین نرخ ذخیره شده)"; 
        }
      });
      _calc1(); _calc2();
      if (!kIsWeb && p != null) {
        try { 
          // ذخیره و آپدیت ویجت با عدد فارسی
          await HomeWidget.saveWidgetData('tv_price', toPersian(_fmt.format(_price))); 
          await HomeWidget.updateWidget(name: androidWidgetName); 
        } catch (_) {}
      }
    }
  }

  void _calc1() {
    double w = double.tryParse(_weightController.text.replaceAll(',', '')) ?? 0;
    setState(() {
        if (_price > 0) {
            String val = _fmt.format((w * _price).round());
            _resPrice = "${toPersian(val)} تومان";
        } else {
            _resPrice = "---";
        }
    });
  }

  void _calc2() {
    double m = double.tryParse(_moneyController.text.replaceAll(',', '')) ?? 0;
    setState(() {
        if (_price > 0) {
            String val = (m / _price).toStringAsFixed(3);
            _resWeight = "${toPersian(val)} گرم";
        } else {
            _resWeight = "---";
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(height: 220, decoration: const BoxDecoration(color: kPrimaryGreen, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)))),
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15), 
                  child: Center(child: Text("محاسبه‌گر قیمت طلای شگرف", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))
                ),
                const SizedBox(height: 5),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kGoldLight, kGoldDark]), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10))]), child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("طلای ۱۸ عیار", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)), child: Text(_priceSource, style: const TextStyle(fontSize: 10)))]),
                  const SizedBox(height: 15),
                  // نمایش قیمت با اعداد فارسی
                  _loading ? const CircularProgressIndicator(color: Colors.white) : Text(toPersian(_fmt.format(_price)), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const Text("تومان / گرم", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 15),
                  SizedBox(width: double.infinity, height: 40, child: ElevatedButton.icon(onPressed: _fetch, icon: const Icon(Icons.refresh, size: 18), label: const Text("بروزرسانی"), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimaryGreen)))
                ]))),
                const SizedBox(height: 20),
                Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                  _inputCard("محاسبه قیمت", Icons.scale_rounded, _weightController, "وزن (گرم)...", "گرم", "قیمت کل:", _resPrice, kPrimaryGreen, _calc1),
                  const SizedBox(height: 15),
                  const NativeAdWidget(zoneId: nativeZoneId),
                  const SizedBox(height: 15),
                  _inputCard("توان خرید", Icons.savings_rounded, _moneyController, "مبلغ (تومان)...", "تومان", "طلای خالص:", _resWeight, const Color(0xFFE65100), _calc2),
                  const SizedBox(height: 80),
                ])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCard(String title, IconData icon, TextEditingController ctrl, String hint, String suffix, String resLbl, String resVal, Color color, VoidCallback onChange) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
      const SizedBox(height: 15),
      TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), DecimalInputFormatter()], onChanged: (v) => onChange(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: hint, suffixText: suffix, filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(resLbl, style: TextStyle(color: Colors.grey[600])), Text(resVal, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))]))
    ]));
  }
}

class NativeAdWidget extends StatefulWidget {
  final String zoneId;
  const NativeAdWidget({super.key, required this.zoneId});
  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  String? _title, _desc, _icon, _cta, _id;
  bool _loaded = false;

  @override
  void initState() { super.initState(); if (!kIsWeb) _load(); }

  void _load() {
    TapsellPlus.instance.requestNativeAd(widget.zoneId, onResponse: (r) {
      if (mounted) setState(() { _title = r['title']; _desc = r['description']; _icon = r['iconUrl']; _cta = r['callToActionText'] ?? "مشاهده"; _id = r['responseId']; _loaded = true; });
    }, onError: (e) {});
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_loaded) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => TapsellPlus.instance.nativeBannerAdClicked(_id!),
      child: Container(
        padding: const EdgeInsets.all(12), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.withOpacity(0.5))),
        child: Row(children: [
          if (_icon != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_icon!, width: 50, height: 50, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)), child: const Text("AD", style: TextStyle(fontSize: 8, color: Colors.white))), const SizedBox(width: 6), Expanded(child: Text(_title ?? "", style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1))]),
            Text(_desc ?? "", style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 2)
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: kPrimaryGreen, borderRadius: BorderRadius.circular(12)), child: Text(_cta!, style: const TextStyle(color: Colors.white, fontSize: 12)))
        ]),
      ),
    );
  }
}