import 'dart:convert';

import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

const String niedzielaUrl = "https://widget.niedziela.pl/liturgia_out.js.php";

Future<Map<String, String>> fetchAndReturnFullReadings(DateTime date) async {
  final dateStr =
      '${date.year.toString().padLeft(4, '0')}'
      '-${date.month.toString().padLeft(2, '0')}-'
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

  final readingsSigla = document.querySelectorAll('.nd_czytanie_sigla');
  final readingsContent = document.querySelectorAll('.nd_czytanie_tresc');

  final bool hasSecondReading = readingsContent.length > 4;

  return {
    'reading1_sigla': readingsSigla.elementAtOrNull(0)?.text.trim() ?? '',
    'reading1_content': readingsContent.elementAtOrNull(0)?.text.trim() ?? '',
    'psalm_ref': document.querySelector('.nd_psalm_refren')?.text.trim() ?? '',
    'psalm': document
        .querySelectorAll('.nd_psalm')
        .map((e) => e.text.trim())
        .join('<br><br>'),
    'reading2_sigla': hasSecondReading
        ? readingsSigla.elementAtOrNull(2)?.text.trim() ?? ''
        : '',
    'reading2_content': hasSecondReading
        ? readingsContent.elementAtOrNull(1)?.text.trim() ?? ''
        : '',
    'acl_sigla': hasSecondReading
        ? readingsSigla.elementAtOrNull(3)?.text.trim() ?? ''
        : readingsSigla.elementAtOrNull(2)?.text.trim() ?? '',
    'acl_content': hasSecondReading
        ? readingsContent.elementAtOrNull(3)?.text.trim() ?? ''
        : readingsContent.elementAtOrNull(2)?.text.trim() ?? '',
    'evangelia_sigla': hasSecondReading
        ? readingsSigla.elementAtOrNull(4)?.text.trim() ?? ''
        : readingsSigla.elementAtOrNull(3)?.text.trim() ?? '',
    'evangelia_content': hasSecondReading
        ? readingsContent.elementAtOrNull(4)?.text.trim() ?? ''
        : readingsContent.elementAtOrNull(3)?.text.trim() ?? '',
  };
}
