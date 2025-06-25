String mapSiglaDataToSiglaAndContentHTML(Map<String, String> data) {
  return '''
    <b>CZYTANIE 1</b><br>
    <span style="color:#666666; font-style: italic;">${data['reading1_sigla']}</span><br>
    ${data['reading1_content']}<br><br><br>
    
    <b>PSALM</b><br>
    <span>ref. ${data['psalm_ref']}</span><br><br>
    ${data['psalm']}<br><br><br>
    
    ${data['reading2_sigla'] != null && data['reading2_sigla'] != "" ? '''
    <b>CZYTANIE 2</b><br>
    <span style="color:#666666; font-style: italic;">${data['reading2_sigla']}</span><br>
    ${data['reading2_content']}<br><br><br>
    ''' : ''}
    
    <b>AKLAMACJA</b><br>
    <span style="color:#666666; font-style: italic;">${data['acl_sigla']}</span><br>${data['acl_content']}<br><br><br>
    
    <b>EWANGELIA</b><br>
    <span style="color:#666666; font-style: italic;">${data['evangelia_sigla']}</span><br>
    ${data['evangelia_content']}<br>
    ''';
}

String mapSiglaDataToSiglaHTML(Map<String, String> data) {
  return [
    if (data['reading1_sigla'] != null)
      '<b>1. czytanie:</b> ${data['reading1_sigla']}',
    if (data['reading2_sigla'] != null && data['reading2_sigla'] != "")
      '<b>2. czytanie:</b> ${data['reading2_sigla']}',
    if (data['evangelia_sigla'] != null)
      '<b>Ewangelia:</b> ${data['evangelia_sigla']}',
  ].join('<br><br>');
}
