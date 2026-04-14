import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'drawing_point.dart';
import 'glow_painter.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      home: ShowCaseWidget(
        builder: (context) => const DrawingScreen(),
      ),
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

  // Showcase Keys
  final GlobalKey _keyCanvas = GlobalKey();
  final GlobalKey _keyColorPicker = GlobalKey();
  final GlobalKey _keyUndo = GlobalKey();
  final GlobalKey _keyClear = GlobalKey();
  final GlobalKey _keySettings = GlobalKey();

  // UI Visibility State
  bool isUIVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _startHideTimer();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('is_first_run') ?? true;
    if (isFirstRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          isUIVisible = true;
        });
        _hideTimer?.cancel(); // Don't hide during showcase
        ShowCaseWidget.of(context).startShowCase([
          _keyCanvas,
          _keyColorPicker,
          _keyUndo,
          _keyClear,
          _keySettings,
        ]);
      });
      await prefs.setBool('is_first_run', false);
    }
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
          Showcase(
            key: _keyCanvas,
            title: 'Vùng vẽ',
            description: 'Chạm và di chuyển để vẽ ánh sáng rực rỡ.',
            child: GestureDetector(
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
                          Showcase(
                            key: _keyColorPicker,
                            title: 'Chọn màu',
                            description: 'Thay đổi màu sắc của ánh sáng.',
                            targetShapeBorder: const CircleBorder(),
                            child: GestureDetector(
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
                          ),

                          // Action Buttons
                          Row(
                            children: [
                                Showcase(
                                  key: _keyUndo,
                                  title: 'Hoàn tác',
                                  description: 'Xóa nét vẽ vừa rồi.',
                                  child: IconButton(
                                    icon: const Icon(Icons.undo, color: Colors.white),
                                    onPressed: () {
                                      if (paths.isNotEmpty) {
                                        setState(() => paths.removeLast());
                                      }
                                      _showUI();
                                    },
                                  ),
                                ),
                                Showcase(
                                  key: _keyClear,
                                  title: 'Xóa sạch',
                                  description: 'Xóa toàn bộ màn hình để bắt đầu lại.',
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_sweep, color: Colors.white),
                                    onPressed: () {
                                      setState(() => paths.clear());
                                      _showUI();
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      
                      // Sliders for customization
                      Showcase(
                        key: _keySettings,
                        title: 'Tùy chỉnh',
                        description: 'Điều chỉnh độ dày và độ tỏa sáng của nét vẽ.',
                        child: Container(
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
