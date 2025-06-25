import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:home_widget/home_widget.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

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

Future<Map<String, String>> fetchAndReturnFullReadings() async {
  final now = DateTime.now();
  final dateStr =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final response = await http.get(
    Uri.parse(
      'https://widget.niedziela.pl/liturgia_out.js.php?data=$dateStr&kodowanie=utf-8',
    ),
  );

  final bodyString = utf8.decode(response.bodyBytes);

  final start =
      bodyString.indexOf("document.write('") + "document.write('".length;
  final end = bodyString.indexOf("');", start);
  final rawHtml = bodyString.substring(start, end);
  final cleanedHtml = HtmlUnescape().convert(rawHtml);
  final document = parse(cleanedHtml);

  final czytanieSigla = document.querySelectorAll('.nd_czytanie_sigla');
  final czytanieTresci = document.querySelectorAll('.nd_czytanie_tresc');

  final bool hasSecondReading = czytanieTresci.length > 4;

  final Map<String, String> data = {
    'czytanie1_sigla': czytanieSigla.elementAtOrNull(0)?.text.trim() ?? '',
    'czytanie1_tresc': czytanieTresci.elementAtOrNull(0)?.text.trim() ?? '',
    'psalm_refren':
        document.querySelector('.nd_psalm_refren')?.text.trim() ?? '',
    'psalm': document
        .querySelectorAll('.nd_psalm')
        .map((e) => e.text.trim())
        .join('<br><br>'),

    'czytanie2_sigla': hasSecondReading
        ? czytanieSigla.elementAtOrNull(2)?.text.trim() ?? ''
        : '',
    'czytanie2_tresc': hasSecondReading
        ? czytanieTresci.elementAtOrNull(1)?.text.trim() ?? ''
        : '',

    'aklamacja_sigla': hasSecondReading
        ? czytanieSigla.elementAtOrNull(3)?.text.trim() ?? ''
        : czytanieSigla.elementAtOrNull(2)?.text.trim() ?? '',

    'aklamacja': hasSecondReading
        ? czytanieTresci.elementAtOrNull(3)?.text.trim() ?? ''
        : czytanieTresci.elementAtOrNull(2)?.text.trim() ?? '',

    'ewangelia_sigla': hasSecondReading
        ? czytanieSigla.elementAtOrNull(4)?.text.trim() ?? ''
        : czytanieSigla.elementAtOrNull(3)?.text.trim() ?? '',

    'ewangelia_tresc': hasSecondReading
        ? czytanieTresci.elementAtOrNull(4)?.text.trim() ?? ''
        : czytanieTresci.elementAtOrNull(3)?.text.trim() ?? '',
  };

  return data;
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
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

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

  Future<Map<String, String>> getFullReadings() async {
    final data = await fetchAndReturnFullReadings();
    print(data.entries);
    return data;
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
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/icon.png',
                height: 32,
                width: 32,
              ),
              SizedBox(width: 8),
              Text('Czytania - ${getFormattedDate()}'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, String>>(
          future: getFullReadings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Błąd: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Brak danych'));
            }

            final data = snapshot.data!;
            final hasSecondReading =
                (data['czytanie2_sigla']?.isNotEmpty ?? false) &&
                (data['czytanie2_tresc']?.isNotEmpty ?? false);

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Html(
                data:
                    '''
<b>CZYTANIE 1</b><br>
<span style="color:#666666; font-style: italic;">${data['czytanie1_sigla']}</span><br>
${data['czytanie1_tresc']}<br><br><br>

<b>PSALM</b><br>
<span>ref. ${data['psalm_refren']}</span><br><br>
${data['psalm']}<br><br><br>

${hasSecondReading ? '''
<b>CZYTANIE 2</b><br>
<span style="color:#666666; font-style: italic;">${data['czytanie2_sigla']}</span><br>
${data['czytanie2_tresc']}<br><br><br>
''' : ''}

<b>AKLAMACJA</b><br>
<span style="color:#666666; font-style: italic;">${data['aklamacja_sigla']}</span><br>${data['aklamacja']}<br><br><br>

<b>EWANGELIA</b><br>
<span style="color:#666666; font-style: italic;">${data['ewangelia_sigla']}</span><br>
${data['ewangelia_tresc']}<br>
''',
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
