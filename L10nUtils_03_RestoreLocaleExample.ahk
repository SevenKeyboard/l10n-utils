#Requires AutoHotkey v2.0
#Include <L10nUtils>

/*
Call initOriginalLocale() at startup to explicitly set the original locale.
This is optional. If omitted, the default original locale is "en_US".
*/
initOriginalLocale("en_US")
msgbox(getLocale())         ;  "en_US"

/*
switchToLocale() pushes the new locale onto the switch stack.
The current locale is now "es_ES".
*/
switchToLocale("es_ES")
msgbox(getLocale())         ;  "es_ES"

/*
Switch again to "ja".
Because locale switches are stacked, the current locale is now "ja".
*/
switchToLocale("ja")
msgbox(getLocale())         ;  "ja"

/*
Switch once more to "ko_KR".
The current locale is now "ko_KR".
*/
switchToLocale("ko_KR")
msgbox(getLocale())         ;  "ko_KR"

/*
restorePreviousLocale() removes only the most recent locale switch.
The current locale returns from "ko_KR" to "ja".
*/
restorePreviousLocale()
msgbox(getLocale())         ;  "ja"

/*
restoreCurrentLocale() restores the original locale and clears the switch stack.
Even though "es_ES" is still in the stack, the current locale returns directly to "en_US".
*/
restoreCurrentLocale()
msgbox(getLocale())         ;  "en_US"