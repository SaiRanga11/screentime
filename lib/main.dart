import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ScreenTimeTracker extends StatefulWidget {
  const ScreenTimeTracker({super.key});

  @override
  State<ScreenTimeTracker> createState() => _ScreenTimeTrackerState();
}

class _ScreenTimeTrackerState extends State<ScreenTimeTracker>
    with WidgetsBindingObserver {
  DateTime? _lastLockTime;
  final Map<DateTime, Duration> _screenTimeData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChannels.lifecycle.setMessageHandler((message) {
      if (message == AppLifecycleState.resumed.toString()) {
        _trackUnlockTime();
      }
      return Future<String?>.value(null);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _trackLockTime();
    }
  }

  void _trackLockTime() {
    _lastLockTime = DateTime.now();
  }

  void _trackUnlockTime() {
    if (_lastLockTime != null) {
      final unlockTime = DateTime.now();
      final duration = unlockTime.difference(_lastLockTime!);
      final date = DateTime(unlockTime.year, unlockTime.month, unlockTime.day);
      setState(() {
        _screenTimeData[date] =
            (_screenTimeData[date] ?? Duration.zero) + duration;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time Tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_screenTimeData.isNotEmpty)
              Expanded(
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(),
                  series: <CartesianSeries>[
                    LineSeries<ChartData, String>(
                      dataSource: _screenTimeData.entries.map((entry) {
                        final dateString =
                            DateFormat('dd MMM').format(entry.key);
                        final totalSeconds = entry.value.inSeconds;
                        final minutes = (totalSeconds / 60).floor();
                        return ChartData(dateString, minutes);
                      }).toList(),
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                    ),
                  ],
                ),
              )
            else
              const Text('No screen time data yet'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _screenTimeData.clear();
                });
              },
              child: const Text('Reset Data'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String x;
  final int y;

  ChartData(this.x, this.y);
}
