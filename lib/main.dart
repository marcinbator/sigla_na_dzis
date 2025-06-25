import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sigla_na_dzis/mapper/body_mapper.dart';
import 'package:sigla_na_dzis/service/api_service.dart';
import 'package:sigla_na_dzis/service/widget_service.dart';
import 'package:workmanager/workmanager.dart';

@pragma("vm:entry-point")
void widgetRefreshTask() {
  Workmanager().executeTask((task, inputData) async {
    await updateWidgetData();
    return Future.value(true);
  });
}

@pragma("vm:entry-point")
FutureOr<void> widgetCallback(Uri? uri) async {
  if (uri?.host == 'refresh') {
    await updateWidgetData();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(widgetCallback);

  await Workmanager().initialize(widgetRefreshTask);
  await Workmanager().registerPeriodicTask(
    "1",
    "dailySiglaUpdate",
    frequency: Duration(hours: 1),
    initialDelay: Duration(seconds: 1),
    constraints: Constraints(networkType: NetworkType.connected),
  );
  await updateWidgetData();

  runApp(SiglaApp());
}

class SiglaApp extends StatelessWidget {
  const SiglaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/icon.png', height: 32, width: 32),
              SizedBox(width: 8),
              Text(
                'Czytania - ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
              ),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, String>>(
          future: fetchAndReturnFullReadings(now),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Błąd: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Brak danych'));
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Html(
                data: mapSiglaDataToSiglaAndContentHTML(snapshot.data!),
                style: {
                  "b": Style(
                    fontWeight: FontWeight.bold,
                    fontSize: FontSize(18),
                  ),
                  "body": Style(fontSize: FontSize(16)),
                  "br": Style(),
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
