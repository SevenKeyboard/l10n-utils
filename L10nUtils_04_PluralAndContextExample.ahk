#Requires AutoHotkey v1.1
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
*/
msgbox % _n("%d file found.", "%d files found.", 1)     ;  "Se encontró %d archivo."
msgbox % _n("%d file found.", "%d files found.", 2)     ;  "Se encontraron %d archivos."

/*
_x(text, context[, domain]) selects a translation using both
the original text and its context.
This allows the same source string to have different translations.
*/
msgbox % _x("Save", "computer action")                  ;  "Guardar"
msgbox % _x("Save", "rescue verb")                      ;  "Salvar"

/*
_nx(single, plural, number, context[, domain]) combines plural selection
with contextual translation.
It is useful when both the number and the meaning of the source string matter.
*/