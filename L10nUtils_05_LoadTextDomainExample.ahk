#Requires AutoHotkey v1.1
#Include <L10nUtils>

/*
Measure the execution time of a callback in milliseconds using
QueryPerformanceCounter().
*/
dllCall("Kernel32.dll\QueryPerformanceFrequency", "Int64*",freq, "Int")
measureMs(funcObj, freq, byRef result := "") {
    dllCall("Kernel32.dll\QueryPerformanceCounter", "Int64*",before, "Int")
    result := funcObj.call()
    dllCall("Kernel32.dll\QueryPerformanceCounter", "Int64*",after, "Int")
    return round((after - before) / freq * 1000, 3)
}

/*
Without preloading, the first lookup for a locale may include
the initial MO catalog load.

In practice, the largest one-time cost usually occurs during
the first lookup performed by the process as a whole.
*/
switchToLocale("ja")
elapsedJa1 := measureMs(func("__").bind("Hello, world!"), freq)     ;  ~70 ms
elapsedJa2 := measureMs(func("__").bind("Hello, world!"), freq)     ;  ~0.04 ms
elapsedJa3 := measureMs(func("__").bind("Hello, world!"), freq)     ;  ~0.04 ms

/*
loadTextDomain(domain[, localeName]) preloads and caches the MO catalog
for the given domain and locale before the first translation lookup.

This can help reduce the first-lookup delay for that locale.
*/
switchToLocale("ko_KR")
elapsedPreloadKo := measureMs(func("loadTextDomain").bind(), freq)  ;  ~0.7 ms
elapsedKo1 := measureMs(func("__").bind("Hello, world!"), freq)     ;  ~0.04 ms
elapsedKo2 := measureMs(func("__").bind("Hello, world!"), freq)     ;  ~0.04 ms
elapsedKo3 := measureMs(func("__").bind("Hello, world!"), freq)     ;  ~0.04 ms

msgBox % "ja 1st lookup`t" elapsedJa1 " ms`n"
    . "ja 2nd lookup`t" elapsedJa2 " ms`n"
    . "ja 3rd lookup`t" elapsedJa3 " ms`n"
    . "`n"
    . "ko_KR preload`t" elapsedPreloadKo " ms`n"
    . "ko_KR 1st lookup`t" elapsedKo1 " ms`n"
    . "ko_KR 2nd lookup`t" elapsedKo2 " ms`n"
    . "ko_KR 3rd lookup`t" elapsedKo3 " ms`n"