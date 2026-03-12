#Requires AutoHotkey v2.0
#Include <L10nUtils>

/*
Measure the execution time of a callback in milliseconds using
QueryPerformanceCounter().
*/
dllCall("Kernel32.dll\QueryPerformanceFrequency", "Int64*",&(freq := 0), "Int")
measureMs(callback, freq, &result := unset) {
    dllCall("Kernel32.dll\QueryPerformanceCounter", "Int64*",&(before := 0), "Int")
    result := callback()
    dllCall("Kernel32.dll\QueryPerformanceCounter", "Int64*",&(after := 0), "Int")
    return round((after - before) / freq * 1000, 3)
}

/*
Without preloading, the first lookup for a locale may include
the initial MO catalog load.

In practice, the largest one-time cost usually occurs during
the first lookup performed by the process as a whole.
*/
switchToLocale("ja")
elapsedJa1 := measureMs(() => __("Hello, world!"), freq)    ;  ~50 ms
elapsedJa2 := measureMs(() => __("Hello, world!"), freq)    ;  ~0.02 ms
elapsedJa3 := measureMs(() => __("Hello, world!"), freq)    ;  ~0.02 ms

/*
loadTextDomain(domain[, localeName]) preloads and caches the MO catalog
for the given domain and locale before the first translation lookup.

This can help reduce the first-lookup delay for that locale.
*/
switchToLocale("ko_KR")
elapsedPreloadKo := measureMs(() => loadTextDomain(), freq) ;  ~0.5 ms
elapsedKo1 := measureMs(() => __("Hello, world!"), freq)    ;  ~0.02 ms
elapsedKo2 := measureMs(() => __("Hello, world!"), freq)    ;  ~0.02 ms
elapsedKo3 := measureMs(() => __("Hello, world!"), freq)    ;  ~0.02 ms

msgBox('ja 1st lookup`t' elapsedJa1 ' ms`n'
    . 'ja 2nd lookup`t' elapsedJa2 ' ms`n'
    . 'ja 3rd lookup`t' elapsedJa3 ' ms`n'
    . '`n'
    . 'ko_KR preload`t' elapsedPreloadKo ' ms`n'
    . 'ko_KR 1st lookup`t' elapsedKo1 ' ms`n'
    . 'ko_KR 2nd lookup`t' elapsedKo2 ' ms`n'
    . 'ko_KR 3rd lookup`t' elapsedKo3 ' ms`n')