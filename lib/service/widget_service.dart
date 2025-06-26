import 'dart:async';

import 'package:home_widget/home_widget.dart';
import 'package:sigla_na_dzis/mapper/body_mapper.dart';

import 'api_service.dart';

const String kSiglaKey = 'sigla';

Future<void> updateWidgetData() async {
  final now = DateTime.now();
  // debug
  // final now = DateTime.utc(2025, 6, 22);
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(Duration(days: 1));

  final todayKey = 'sigla_${today.toIso8601String().split('T').first}';
  final tomorrowKey = 'sigla_${tomorrow.toIso8601String().split('T').first}';

  // clear cache
  // await HomeWidget.saveWidgetData(todayKey, null);
  // await HomeWidget.saveWidgetData(tomorrowKey, null);

  try {
    String? todaySigla = await HomeWidget.getWidgetData<String>(todayKey);
    if (todaySigla == null) {
      final todayData = await fetchAndReturnFullReadings(today);
      todaySigla = mapSiglaDataToSiglaHTML(todayData);
      await HomeWidget.saveWidgetData<String>(todayKey, todaySigla);
    }

    String? tomorrowSigla = await HomeWidget.getWidgetData<String>(tomorrowKey);
    if (tomorrowSigla == null) {
      final tomorrowData = await fetchAndReturnFullReadings(tomorrow);
      tomorrowSigla = mapSiglaDataToSiglaHTML(tomorrowData);
      await HomeWidget.saveWidgetData<String>(tomorrowKey, tomorrowSigla);
    }

    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    await HomeWidget.saveWidgetData<String>(kSiglaKey, todaySigla);
    await HomeWidget.saveWidgetData<String>('last_date', today.toIso8601String());
    await HomeWidget.saveWidgetData<String>('last_update', 'Ostatnia aktualizacja: $formattedTime');

    await HomeWidget.updateWidget(name: 'ReadingsWidgetProvider');
  } catch (e) {
    final todayKey = 'sigla_${today.toIso8601String().split('T').first}';
    final fallbackSigla = await HomeWidget.getWidgetData<String>(todayKey);
    if (fallbackSigla == null) return;

    await HomeWidget.saveWidgetData<String>(kSiglaKey, fallbackSigla);
    await HomeWidget.saveWidgetData<String>('last_date', today.toIso8601String());
    await HomeWidget.saveWidgetData<String>('last_update', 'Załadowano z pamięci');
    await HomeWidget.updateWidget(name: 'ReadingsWidgetProvider');
  }
}

