#Requires AutoHotkey v1.1
#Include <L10nUtils>

/*
Call initOriginalLocale() at startup to explicitly set the original locale.
This is optional. If omitted, the default original locale is "en_US".
*/
initOriginalLocale("en_US")

/*
If the domain parameter is omitted, L10nUtils uses the default domain name "default".
For example, after switching to "ko_KR", __("Hello, world!") looks up:
    locale\ko_KR\LC_MESSAGES\default.mo

You can also pass a different domain name such as "extra".
In that case, L10nUtils will look up:
    locale\ko_KR\LC_MESSAGES\extra.mo

This allows you to split translations across multiple catalogs when needed.
*/

switchToLocale("ko_KR")

msgbox % __("Hello, world!")                ;  "안녕하세요, 세상아!"
msgbox % __("Hello, world!", "default")     ;  "안녕하세요, 세상아!"

;  Example:
;  msgbox % __("Hello, world!", "extra")
;  -> locale\ko_KR\LC_MESSAGES\extra.mo