import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'package:flutter_html/flutter_html.dart';

const String kSiglaKey = 'sigla';
const String taskName = "dailySiglaUpdate";

@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await fetchAndUpdateWidgetData();
    return Future.value(true);
  });
}

Future<void> scheduleDailyUpdate() async {
  await Workmanager().registerPeriodicTask(
    "1",
    taskName,
    frequency: Duration(minutes: 20),
    initialDelay: Duration(seconds: 1),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

Future<void> fetchAndUpdateWidgetData() async {
  final now = DateTime.now();
  final dateStr =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final response = await http.get(
    Uri.parse(
      'https://widget.niedziela.pl/liturgia_out.js.php?data=$dateStr&kodowanie=utf-8',
    ),
  );
  final decodedBody = utf8.decode(response.bodyBytes);

  if (response.statusCode != 200) return;
  final document = parse(decodedBody);

  final siglaElements = document.querySelectorAll('p.nd_wstep > span.nd_sigla');

  String pierwsze = '';
  String drugie = '';
  String ewangelia = '';

  for (var el in siglaElements) {
    final text = el.text.trim();
    if (el.parent!.text.contains('1. czytanie')) {
      pierwsze = text;
    } else if (el.parent!.text.contains('2. czytanie')) {
      drugie = text;
    } else if (el.parent!.text.contains('Ewangelia')) {
      ewangelia = text;
    }
  }

  final allSigla = [
    if (pierwsze.isNotEmpty) '<b>1. czytanie:</b> $pierwsze',
    if (drugie.isNotEmpty) '<b>2. czytanie:</b> $drugie',
    if (ewangelia.isNotEmpty) '<b>Ewangelia:</b> $ewangelia',
  ].join('<br><br>');

  final formattedTime =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  await HomeWidget.saveWidgetData<String>(kSiglaKey, allSigla);
  await HomeWidget.saveWidgetData<String>(
    'last_update',
    'Ostatnia aktualizacja: $formattedTime',
  );
  await HomeWidget.updateWidget(name: 'ReadingsWidgetProvider');
}

@pragma("vm:entry-point")
FutureOr<void> backgroundCallback(Uri? uri) async {
  if (kDebugMode) {
    print("refresh callback");
  }
  if (uri?.host == 'refresh') {
    await fetchAndUpdateWidgetData();
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HomeWidget.registerInteractivityCallback(backgroundCallback);

  await Workmanager().initialize(callbackDispatcher);
  await scheduleDailyUpdate();

  await fetchAndUpdateWidgetData();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> getSigla() async {
    return await HomeWidget.getWidgetData<String>(kSiglaKey) ?? 'Brak danych';
  }

  String getFormattedDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text('Czytania - ${getFormattedDate()}')),
        body: FutureBuilder<String>(
          future: getSigla(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Html(
                data: snapshot.data!,
                style: {
                  "b": Style(
                    fontWeight: FontWeight.bold,
                    fontSize: FontSize(18),
                  ),
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

