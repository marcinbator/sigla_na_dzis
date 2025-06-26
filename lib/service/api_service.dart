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

  final readings = _extractUniqueReadingsFromDocument(document);
  final psalmRef =
      document.querySelector('.nd_psalm_refren')?.text.trim() ?? '';
  final psalmContent = document
      .querySelectorAll('.nd_psalm')
      .map((e) => e.text.trim())
      .join('<br><br>');

  String getSigla(int index) =>
      readings.length > index ? readings[index]['sigla'] ?? '' : '';
  String getContent(int index) =>
      readings.length > index ? readings[index]['content'] ?? '' : '';

  final hasSecondReading = readings.length > 3;

  return {
    'reading1_sigla': getSigla(0),
    'reading1_content': getContent(0),
    'psalm_ref': psalmRef,
    'psalm': psalmContent,
    'reading2_sigla': hasSecondReading ? getSigla(1) : '',
    'reading2_content': hasSecondReading ? getContent(1) : '',
    'acl_sigla': getSigla(hasSecondReading ? 2 : 1),
    'acl_content': getContent(hasSecondReading ? 2 : 1),
    'evangelia_sigla': getSigla(hasSecondReading ? 3 : 2),
    'evangelia_content': getContent(hasSecondReading ? 3 : 2),
  };
}

List<Map<String, String>> _extractUniqueReadingsFromDocument(
  Document document,
) {
  final siglaElements = document.querySelectorAll('.nd_czytanie_sigla');
  final contentElements = document.querySelectorAll('.nd_czytanie_tresc');

  final readings = <Map<String, String>>[];

  for (int i = 0; i < siglaElements.length && i < contentElements.length; i++) {
    final siglaText = siglaElements[i].text.trim();
    final contentText = contentElements[i].text.trim();

    if (siglaText.startsWith('Ps ')) continue;

    final alreadyExists = readings.any(
      (r) =>
          r['sigla'] == siglaText ||
          r['content'] == contentText ||
          r['content']!.contains(contentText) ||
          contentText.contains(r['content']!),
    );
    if (alreadyExists) continue;

    readings.add({'sigla': siglaText, 'content': contentText});
  }

  return readings;
}
