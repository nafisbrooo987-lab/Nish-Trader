import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:http/http.dart' as http;

const String apiKey = "f8acf1f3b7f0469795f1fd7546a5de88";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Overlay Entry Point
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FloatingWidget(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text("TR Signal Bot Launcher")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  bool status = await FlutterOverlayWindow.isPermissionGranted();
                  if (!status) {
                    await FlutterOverlayWindow.requestPermission();
                  } else {
                    await FlutterOverlayWindow.showOverlay(
                      height: 500,
                      width: 350,
                      alignment: OverlayAlignment.center,
                      visibility: NotificationVisibility.visibilitySecret,
                    );
                  }
                },
                child: const Text("Start Floating Bot Window"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FloatingWidget extends StatefulWidget {
  const FloatingWidget({super.key});

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget> {
  bool isExpanded = false;
  bool isScanning = false;
  String selectedPair = "EUR/USD";
  String signalResult = "TAP TO SCAN";
  Color signalColor = Colors.cyanAccent;

  final List<String> pairs = ["EUR/USD", "GBP/JPY", "USD/JPY"];

  Future<void> fetchSignal() async {
    setState(() {
      isScanning = true;
      signalResult = "SCANNING MARKET...";
      signalColor = Colors.amber;
    });

    try {
      final url = Uri.parse(
          "https://api.twelvedata.com/time_series?symbol=$selectedPair&interval=1min&outputsize=30&apikey=$apiKey");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['values'] != null) {
          List values = data['values'];
          List<double> closePrices = values
              .map<double>((e) => double.parse(e['close'].toString()))
              .toList()
              .reversed
              .toList();

          double rsi = calculateRSI(closePrices, 14);

          setState(() {
            if (rsi < 35) {
              signalResult = "CALL / UP 🟢\n(RSI: ${rsi.toStringAsFixed(1)})";
              signalColor = Colors.greenAccent;
            } else if (rsi > 65) {
              signalResult = "PUT / DOWN 🔴\n(RSI: ${rsi.toStringAsFixed(1)})";
              signalColor = Colors.redAccent;
            } else {
              signalResult = "WAIT / NO TRADE 🟡\n(RSI: ${rsi.toStringAsFixed(1)})";
              signalColor = Colors.yellowAccent;
            }
          });
        } else {
          setState(() {
            signalResult = "API LIMIT / ERROR";
            signalColor = Colors.orange;
          });
        }
      }
    } catch (e) {
      setState(() {
        signalResult = "CONNECTION ERROR";
        signalColor = Colors.red;
      });
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  double calculateRSI(List<double> prices, int period) {
    if (prices.length < period + 1) return 50.0;
    double gains = 0.0;
    double losses = 0.0;

    for (int i = 1; i <= period; i++) {
      double diff = prices[i] - prices[i - 1];
      if (diff >= 0) {
        gains += diff;
      } else {
        losses += diff.abs();
      }
    }

    double avgGain = gains / period;
    double avgLoss = losses / period;

    if (avgLoss == 0) return 100.0;
    double rs = avgGain / avgLoss;
    return 100.0 - (100.0 / (1.0 + rs));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: isExpanded
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121826).withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: signalColor, width: 2),
                boxShadow: [
                  BoxShadow(color: signalColor.withOpacity(0.3), blurRadius: 10)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TR BOT v1.0",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => isExpanded = false),
                      )
                    ],
                  ),
                  DropdownButton<String>(
                    value: selectedPair,
                    dropdownColor: const Color(0xFF1A233A),
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    items: pairs.map((String pair) {
                      return DropdownMenuItem<String>(
                        value: pair,
                        child: Text(pair),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedPair = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 80,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      signalResult,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: signalColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
ElevatedButton(
  onPressed: () async {
    bool status = await FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      await FlutterOverlayWindow.requestPermission();
    }
    
    // পারমিশন পাওয়ার পর ওভারলে অন করবে
    if (await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.showOverlay(
        height: 500,
        width: 350,
        alignment: OverlayAlignment.center,
        enableDrag: true,
      );
    }
  },
  child: const Text("Start Floating Bot Window"),
                  )
                ],
              ),
            )
          : GestureDetector(
              onTap: () => setState(() => isExpanded = true),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF121826),
                  border: Border.all(color: Colors.greenAccent, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.greenAccent, blurRadius: 8)
                  ],
                ),
                child: const Center(
                  child: Text("TR",
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
              ),
            ),
    );
  }
}
