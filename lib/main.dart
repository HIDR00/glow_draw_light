import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'drawing_point.dart';
import 'glow_painter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const GlowDrawApp());
}

class GlowDrawApp extends StatelessWidget {
  const GlowDrawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glow Draw',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const DrawingScreen(),
    );
  }
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  List<DrawingPath> paths = [];
  Color currentColor = Colors.cyanAccent;
  double currentStrokeWidth = 8.0;
  double currentGlowSpread = 20.0;

  // UI Visibility State
  bool isUIVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          isUIVisible = false;
        });
      }
    });
  }

  void _showUI() {
    setState(() {
      isUIVisible = true;
    });
    _startHideTimer();
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn màu ánh sáng'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              setState(() => currentColor = color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Xong'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Drawing Canvas
          GestureDetector(
            onPanStart: (details) {
              _showUI();
              setState(() {
                paths.add(DrawingPath(
                  points: [details.localPosition],
                ));
              });
            },
            onPanUpdate: (details) {
              setState(() {
                if (paths.isNotEmpty) {
                  paths.last.points.add(details.localPosition);
                }
              });
            },
            onPanEnd: (details) {
              _startHideTimer();
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: GlowPainter(
                  paths: paths,
                  color: currentColor,
                  strokeWidth: currentStrokeWidth,
                  glowSpread: currentGlowSpread,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // Minimalist Overlay Menu
          AnimatedOpacity(
            opacity: isUIVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !isUIVisible,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Color Indicator & Picker
                          GestureDetector(
                            onTap: _pickColor,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: currentColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: currentColor.withAlpha(200),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Action Buttons
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.undo, color: Colors.white),
                                onPressed: () {
                                  if (paths.isNotEmpty) {
                                    setState(() => paths.removeLast());
                                  }
                                  _showUI();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                                onPressed: () {
                                  setState(() => paths.clear());
                                  _showUI();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      
                      // Sliders for customization
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Độ dày nét vẽ', style: TextStyle(fontSize: 12)),
                            Slider(
                              value: currentStrokeWidth,
                              min: 1.0,
                              max: 20.0,
                              activeColor: currentColor,
                              onChanged: (val) {
                                setState(() => currentStrokeWidth = val);
                                _showUI();
                              },
                            ),
                            const Text('Độ tỏa sáng (Glow)', style: TextStyle(fontSize: 12)),
                            Slider(
                              value: currentGlowSpread,
                              min: 0.0,
                              max: 50.0,
                              activeColor: currentColor,
                              onChanged: (val) {
                                setState(() => currentGlowSpread = val);
                                _showUI();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Hint for invisible UI
          if (!isUIVisible)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Chạm để hiện menu',
                  style: TextStyle(
                    color: Colors.white.withAlpha(50),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
