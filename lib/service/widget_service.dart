import 'dart:async';

import 'package:home_widget/home_widget.dart';
import 'package:sigla_na_dzis/mapper/body_mapper.dart';

import 'api_service.dart';

const String kSiglaKey = 'sigla';

Future<void> updateWidgetData() async {
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime tomorrow = today.add(Duration(days: 1));

  try {
    final cachedToday = await HomeWidget.getWidgetData<String>('sigla_today');
    final cachedTodayDateStr = await HomeWidget.getWidgetData<String>(
      'sigla_today_date',
    );
    final cachedTomorrow = await HomeWidget.getWidgetData<String>(
      'sigla_tomorrow',
    );
    final cachedTomorrowDateStr = await HomeWidget.getWidgetData<String>(
      'sigla_tomorrow_date',
    );

    final isTodayCached =
        cachedToday != null && cachedTodayDateStr == today.toIso8601String();
    final isTomorrowCached =
        cachedTomorrow != null &&
        cachedTomorrowDateStr == tomorrow.toIso8601String();

    String todaySiglaString =
        cachedToday ??
        mapSiglaDataToSiglaHTML(await fetchAndReturnFullReadings(today));
    String tomorrowSiglaString =
        cachedTomorrow ??
        mapSiglaDataToSiglaHTML(await fetchAndReturnFullReadings(tomorrow));

    if (!isTodayCached) {
      await HomeWidget.saveWidgetData<String>('sigla_today', todaySiglaString);
      await HomeWidget.saveWidgetData<String>(
        'sigla_today_date',
        today.toIso8601String(),
      );
    }
    if (!isTomorrowCached) {
      await HomeWidget.saveWidgetData<String>(
        'sigla_tomorrow',
        tomorrowSiglaString,
      );
      await HomeWidget.saveWidgetData<String>(
        'sigla_tomorrow_date',
        tomorrow.toIso8601String(),
      );
    }

    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    await HomeWidget.saveWidgetData<String>(kSiglaKey, todaySiglaString);
    await HomeWidget.saveWidgetData<String>(
      'last_date',
      today.toIso8601String(),
    );
    await HomeWidget.saveWidgetData<String>(
      'last_update',
      'Ostatnia aktualizacja: $formattedTime',
    );
    await HomeWidget.updateWidget(name: 'ReadingsWidgetProvider');
  } catch (e) {
    final lastSavedDateStr = await HomeWidget.getWidgetData<String>(
      'last_date',
    );
    if (lastSavedDateStr == null) return;
    final lastSavedDate = DateTime.tryParse(lastSavedDateStr);
    if (lastSavedDate == null) return;

    final nowDateOnly = DateTime(now.year, now.month, now.day);
    final diff = nowDateOnly.difference(lastSavedDate).inDays;
    if (diff != 1) return;

    final fallbackSigla = await HomeWidget.getWidgetData<String>(
      'sigla_tomorrow',
    );
    if (fallbackSigla == null) return;

    await HomeWidget.saveWidgetData<String>(kSiglaKey, fallbackSigla);
    await HomeWidget.saveWidgetData<String>(
      'last_date',
      nowDateOnly.toIso8601String(),
    );
    await HomeWidget.saveWidgetData<String>(
      'last_update',
      'Załadowano z zapasu na jutro',
    );
    await HomeWidget.updateWidget(name: 'ReadingsWidgetProvider');
  }
}
