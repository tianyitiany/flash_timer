import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

// 英雄位置名称（可自行修改）
const List<String> positions = ['上单', '打野', '中单', 'ADC', '辅助'];

// 闪现冷却时间（秒）
const int flashCD = 300;

void main() {
  runApp(const FlashTimerApp());
}

class FlashTimerApp extends StatelessWidget {
  const FlashTimerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '闪现计时器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 每个英雄的剩余秒数，null 表示就绪
  final List<int?> _remaining = List<int?>.filled(5, null);
  // 每个英雄对应的 Timer 对象
  final List<Timer?> _timers = List<Timer?>.filled(5, null);
  // 语音引擎
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    // 初始化 TTS，设置中文
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  // 开始计时
  void _startTimer(int index) {
    // 如果已有计时器，先取消
    if (_timers[index] != null) {
      _timers[index]!.cancel();
    }
    setState(() {
      _remaining[index] = flashCD;
    });
    // 启动每秒更新
    _timers[index] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining[index] == null) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remaining[index]! > 0) {
          _remaining[index] = _remaining[index]! - 1;
        }
        if (_remaining[index]! <= 0) {
          // 倒计时结束
          _remaining[index] = null;
          timer.cancel();
          _timers[index] = null;
          _speakReady(index);
        }
      });
    });
  }

  // 重置计时
  void _resetTimer(int index) {
    if (_timers[index] != null) {
      _timers[index]!.cancel();
      _timers[index] = null;
    }
    setState(() {
      _remaining[index] = null;
    });
  }

  // 全部重置
  void _resetAll() {
    for (int i = 0; i < 5; i++) {
      _resetTimer(i);
    }
  }

  // 语音播报
  Future<void> _speakReady(int index) async {
    try {
      await _tts.speak('敌方${positions[index]}闪现已好');
    } catch (e) {
      // 如果语音失败，忽略
    }
  }

  // 测试语音
  Future<void> _testVoice() async {
    await _tts.speak('测试语音');
  }

  // 格式化剩余时间 mm:ss
  String _formatTime(int? seconds) {
    if (seconds == null) return '就绪';
    int mm = seconds ~/ 60;
    int ss = seconds % 60;
    return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  // 获取显示颜色
  Color _getColor(int? seconds) {
    if (seconds == null) return Colors.green;
    if (seconds > 60) return Colors.black87;
    if (seconds > 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('闪现计时器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: _testVoice,
            tooltip: '测试语音',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAll,
            tooltip: '全部重置',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // 英雄名称
                    Expanded(
                      flex: 2,
                      child: Text(
                        positions[index],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 倒计时显示
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatTime(_remaining[index]),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _getColor(_remaining[index]),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // 操作按钮
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => _startTimer(index),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('开始'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _resetTimer(index),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('重置'),
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
    );
  }
}
