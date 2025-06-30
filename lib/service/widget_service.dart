import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sigla_na_dzis/mapper/body_mapper.dart';

import 'api_service.dart';

const String kSiglaKey = 'sigla';

@pragma("vm:entry-point")
Future<void> updateWidgetData() async {
  WidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final todayData = await fetchAndReturnFullReadings(today);
  final todaySigla = mapSiglaDataToSiglaHTML(todayData);

  final formattedTime =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

  await HomeWidget.saveWidgetData<String>(kSiglaKey, todaySigla);
  await HomeWidget.saveWidgetData<String>('last_update', 'Ostatnia aktualizacja: $formattedTime');

  await HomeWidget.updateWidget(name: 'ReadingsWidgetProvider');
}

