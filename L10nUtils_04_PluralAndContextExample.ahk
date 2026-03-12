#Requires AutoHotkey v2.0
#Include <L10nUtils>

/*
Call initOriginalLocale() at startup to explicitly set the original locale.
This is optional. If omitted, the default original locale is "en_US".
*/
initOriginalLocale("en_US")

/*
Switch to Spanish so that the plural and context examples produce visible translations.
*/
switchToLocale("es_ES")

/*
_n(single, plural, number[, domain]) selects the singular or plural translation
based on the given number.

For more conventional formatted output, consider using sprintf()
to produce the same translated results with format specifiers handled:
    #Include <sprintf> ;  https://github.com/SevenKeyboard/sprintf/blob/main-ahkv2.0/sprintf.ahk

    n := 1
    msgbox(sprintf(_n("%d file found.", "%d files found.", n), n))

    n := 2
    msgbox(sprintf(_n("%d file found.", "%d files found.", n), n))
*/
n := 1
msgbox(strReplace(_n("%d file found.", "%d files found.", n), "%d", n))     ;  "Se encontró 1 archivo."

n := 2
msgbox(strReplace(_n("%d file found.", "%d files found.", n), "%d", n))     ;  "Se encontraron 2 archivos."

/*
_x(text, context[, domain]) selects a translation using both
the original text and its context.
This allows the same source string to have different translations.
*/
msgbox(_x("Save", "computer action"))                   ;  "Guardar"
msgbox(_x("Save", "rescue verb"))                       ;  "Salvar"

/*
_nx(single, plural, number, context[, domain]) combines plural selection
with contextual translation.
It is useful when both the number and the meaning of the source string matter.
*/