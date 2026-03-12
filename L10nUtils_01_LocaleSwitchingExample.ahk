#Requires AutoHotkey v2.0
#Include <L10nUtils>

/*
Call initOriginalLocale() at startup to explicitly set the original locale.
This is optional. If omitted, the default original locale is "en_US".
*/
initOriginalLocale("en_US")

msgbox(__("Hello, world!"))                             ;  "Hello, world!"
msgbox(_n("%d file found.", "%d files found.", 1))      ;  "%d file found."
msgbox(_n("%d file found.", "%d files found.", 2))      ;  "%d files found."
msgbox(_x("Save", "computer action"))                   ;  "Save"
msgbox(_x("Save", "rescue verb"))                       ;  "Save"

switchToLocale("es_ES")

msgbox(__("Hello, world!"))                             ;  "¡Hola, mundo!"
msgbox(_n("%d file found.", "%d files found.", 1))      ;  "Se encontró %d archivo."
msgbox(_n("%d file found.", "%d files found.", 2))      ;  "Se encontraron %d archivos."
msgbox(_x("Save", "computer action"))                   ;  "Guardar"
msgbox(_x("Save", "rescue verb"))                       ;  "Salvar"

switchToLocale("ja")

msgbox(__("Hello, world!"))                             ;  "こんにちは、世界！"
msgbox(_n("%d file found.", "%d files found.", 1))      ;  "%d 件のファイルが見つかりました。"
msgbox(_n("%d file found.", "%d files found.", 2))      ;  "%d 件のファイルが見つかりました。"
msgbox(_x("Save", "computer action"))                   ;  "保存"
msgbox(_x("Save", "rescue verb"))                       ;  "救う"

switchToLocale("ko_KR")

msgbox(__("Hello, world!"))                             ;  "안녕하세요, 세상아!"
msgbox(_n("%d file found.", "%d files found.", 1))      ;  "파일 %d개를 찾았습니다."
msgbox(_n("%d file found.", "%d files found.", 2))      ;  "파일 %d개를 찾았습니다."
msgbox(_x("Save", "computer action"))                   ;  "저장"
msgbox(_x("Save", "rescue verb"))                       ;  "구하다"

switchToLocale("zh_CN")

msgbox(__("Hello, world!"))                             ;  "你好，世界！"
msgbox(_n("%d file found.", "%d files found.", 1))      ;  "已找到 %d 个文件。"
msgbox(_n("%d file found.", "%d files found.", 2))      ;  "已找到 %d 个文件。"
msgbox(_x("Save", "computer action"))                   ;  "保存"
msgbox(_x("Save", "rescue verb"))                       ;  "拯救"