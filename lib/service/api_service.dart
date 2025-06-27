import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

const String niedzielaUrl = "https://widget.niedziela.pl/liturgia_out.js.php";

Future<Map<String, String>> fetchAndReturnFullReadings(DateTime date) async {
  final dateStr =
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  final response = await http.get(
    Uri.parse('$niedzielaUrl?data=$dateStr&kodowanie=utf-8'),
  );
  if (response.statusCode != 200) throw Exception("Błąd pobierania danych");

  final bodyString = utf8.decode(response.bodyBytes);
  final start =
      bodyString.indexOf("document.write('") + "document.write('".length;
  final end = bodyString.indexOf("');", start);
  final rawHtml = bodyString.substring(start, end);
  final cleanedHtml = HtmlUnescape().convert(rawHtml);
  final document = parse(cleanedHtml);

  final psalmRef =
      document.querySelector('.nd_psalm_refren')?.text.trim() ?? '';
  final psalmContent = document
      .querySelectorAll('.nd_psalm')
      .map((e) => e.text.trim())
      .join('<br><br>');

  final readings = _extractUniqueReadingsFromDocument(document);

  String getReadingContent(String type, [int occurrence = 0]) {
    final found = readings.where((r) => r['type'] == type).toList();
    return (found.length > occurrence)
        ? found[occurrence]['content'] ?? ''
        : '';
  }
  String getReadingSigla(String type, [int occurrence = 0]) {
    final found = readings.where((r) => r['type'] == type).toList();
    return (found.length > occurrence) ? found[occurrence]['sigla'] ?? '' : '';
  }

  final acl1Sigla = getReadingSigla('aklamacja', 0);
  final acl1Content = getReadingContent('aklamacja', 0);
  final acl2Sigla = getReadingSigla('aklamacja', 1);
  final acl2Content = getReadingContent('aklamacja', 1);

  return {
    'reading1_sigla': getReadingSigla('1. czytanie'),
    'reading1_content': getReadingContent('1. czytanie'),
    'psalm_ref': psalmRef,
    'psalm': psalmContent,
    'reading2_sigla': getReadingSigla('2. czytanie'),
    'reading2_content': getReadingContent('2. czytanie'),
    'acl_sigla': acl1Sigla,
    'acl_content': acl1Content,
    'acl2_sigla': acl2Sigla,
    'acl2_content': acl2Content,
    'evangelia_sigla': getReadingSigla('ewangelia'),
    'evangelia_content': getReadingContent('ewangelia'),
  };
}

List<Map<String, String>> _extractUniqueReadingsFromDocument(
  Document document,
) {
  final sections = document.querySelectorAll('#nd_liturgia_czytania > *');
  final readings = <Map<String, String>>[];
  String? currentType;
  String? currentSigla;
  String? currentContent;

  for (var element in sections) {
    final className = element.className;

    if (className == 'nd_czytanie_nazwa') {
      if (currentType != null &&
          currentSigla != null &&
          currentContent != null) {
        readings.add({
          'type': currentType,
          'sigla': currentSigla,
          'content': currentContent,
        });
      }
      if (element.text.trim().toLowerCase() != "wersja dłuższa" &&
          element.text.trim().toLowerCase() != "wersja krótsza") {
        currentType = element.text.trim().toLowerCase();
      }
      currentSigla = null;
      currentContent = null;
    } else if (className == 'nd_czytanie_sigla') {
      currentSigla = element.text.trim();
    } else if (className == 'nd_czytanie_tresc') {
      currentContent = element.text.trim();
    }
  }

  if (currentType != null && currentSigla != null && currentContent != null) {
    readings.add({
      'type': currentType,
      'sigla': currentSigla,
      'content': currentContent,
    });
  }

  return readings;
}
