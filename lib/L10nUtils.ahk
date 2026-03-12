#Requires AutoHotkey v2.0.0+
;==============================================================
; L10nUtils — Localization helpers with WordPress-style locale switching and MO catalog loading
;
; GitHub: https://github.com/SevenKeyboard/l10n-utils
; Author: SevenKeyboard Ltd. (2026)
; License: MIT License
;
; Documentation / References:
;   MoCatalog
;     https://github.com/SevenKeyboard/mo-catalog
;   Boost.Locale
;     https://www.boost.org/doc/libs/latest/libs/locale/doc/html/index.html
;
;   __()
;     https://developer.wordpress.org/reference/functions/__/
;   _n()
;     https://developer.wordpress.org/reference/functions/_n/
;   _x()
;     https://developer.wordpress.org/reference/functions/_x/
;   _nx()
;     https://developer.wordpress.org/reference/functions/_nx/
;
;   MoCatalog.dll (64bits) - VirusTotal
;     https://www.virustotal.com/gui/file/e7a5f2ad906d017cc4a39fe9d5b26ae5cbf7d35bcde2b7495b3607e819e5b77a
;   MoCatalog.dll - VirusTotal
;     https://www.virustotal.com/gui/file/f19c6db712433871edc003224d491bcc89b50e23e3e9bf1f2cfbc4f3f9195e2a
;==============================================================
/*
my-app/
├─ MyApp.ahk
├─ lib/
│  └─ L10nUtils.ahk
├─ dll/
│  ├─ x64/
│     └─ MoCatalog.dll
│  └─ x86/
│     └─ MoCatalog.dll
└─ locale/
   ├─ en_US/
   │  └─ LC_MESSAGES/
   │     ├─ default.mo
   │     ├─ extra.mo
   │     └─ ...
   ├─ es_ES/
   │  └─ LC_MESSAGES/
   │     ├─ default.mo
   │     ├─ extra.mo
   │     └─ ...
   ├─ ja/
   │  └─ LC_MESSAGES/
   │     ├─ default.mo
   │     ├─ extra.mo
   │     └─ ...
   └─ ...
*/
class VersionManager_L10nUtils
{
    static _ := this._init()
    static _init()    {
        global
        L10NUTILS_VERSION := "1.0.0"
    }
}
;=======================================================================================================================
__(text, domain := "default")    { ;  https://developer.wordpress.org/reference/functions/__/
    return _AhkL10n.getText(text is VarRef ? text : &text
        ,domain)
}
_n(single, plural, num, domain := "default")    { ;  https://developer.wordpress.org/reference/functions/_n/
    return _AhkL10n.nGetText(single is VarRef ? single : &single
        ,plural is VarRef ? plural : &plural
        ,num
        ,domain)
}
_x(text, context, domain := "default")    { ;  https://developer.wordpress.org/reference/functions/_x/
    return _AhkL10n.pGetText(text is VarRef ? text : &text
        ,context
        ,domain)
}
_nx(single, plural, num, context, domain := "default")    { ;  https://developer.wordpress.org/reference/functions/_nx/
    return _AhkL10n.npGetText(single is VarRef ? single : &single
        ,plural is VarRef ? plural : &plural
        ,num
        ,context
        ,domain)
}
;-------------------------------------------------------------------------------------------
loadTextDomain(domain := "default", locale?) => _AhkL10n.loadTextDomain(domain, locale?) ;  https://developer.wordpress.org/reference/functions/load_textdomain/
;-------------------------------------------------------------------------------------------
initOriginalLocale(locale)  => _AhkLocaleSwitcher.initOriginalLocale(locale)
getLocale()                 => _AhkLocaleSwitcher.getLocale()                   ;  https://developer.wordpress.org/reference/functions/get_locale/
isLocaleSwitched()          => _AhkLocaleSwitcher.isSwitched()                  ;  https://developer.wordpress.org/reference/functions/is_locale_switched/
switchToLocale(locale)      => _AhkLocaleSwitcher.switchToLocale(locale)        ;  https://developer.wordpress.org/reference/functions/switch_to_locale/
restorePreviousLocale()     => _AhkLocaleSwitcher.restorePreviousLocale()       ;  https://developer.wordpress.org/reference/functions/restore_previous_locale/
restoreCurrentLocale()      => _AhkLocaleSwitcher.restoreCurrentLocale()        ;  https://developer.wordpress.org/reference/functions/restore_current_locale/
;=======================================================================================================================
class _AhkL10n
{
    ;  WARNING: Backward compatibility is not guaranteed for any methods or properties in this class.
    static _dllDir              := this._getFullPathName(A_ScriptDir . "\dll" . (A_PtrSize == 8 ? "\x64" : "\x86"))
        ,_moCatalogDllPath      := this._dllDir . "\MoCatalog.dll" ;  https://github.com/SevenKeyboard/mo-catalog
        ,_hMoCatalogMod         := 0
        ,_moCatalogProcTable    := {}
        ,_objbmOnExiting        := objBindMethod(this, "_onExiting")
    static __new()    {
        if (!this._Ready)    {
            this._freeLibraries()
            this._loadLibraries()
        }
    }
    static _Ready => !!(this._hMoCatalogMod)
    static _loadLibraries()    {
        this._clearMoCatalogProcs()
        this._hMoCatalogMod := 0
        if (!fileExist(this._moCatalogDllPath))
            return false
        this._hMoCatalogMod := dllCall("Kernel32.dll\LoadLibraryW", "WStr",this._moCatalogDllPath, "Ptr")
        ok := !!(this._hMoCatalogMod)
        if (ok)    {
            ok := this._resolveMoCatalogProcs(this._hMoCatalogMod)
            if (!ok)
                this._freeLibraries()
        }
        if (ok)
            onExit(this._objbmOnExiting)
        return ok
    }
    static _freeLibraries(isExiting := false)    {
        if (!isExiting)
            onExit(this._objbmOnExiting, 0)
        this._destroyAllHCatalogs()
        this._clearMoCatalogProcs()
        if (this._hMoCatalogMod)    {
            hMod := this._hMoCatalogMod, this._hMoCatalogMod := 0
            dllCall("Kernel32.dll\FreeLibrary", "Ptr",hMod), hMod := 0
        }
    }
    static _resolveMoCatalogProcs(hMod)    {
        this._moCatalogProcTable := {}
        for procName in ["MoCatalogCreate"
            ,"MoCatalogDestroy"
            ,"MoCatalogGetText"
            ,"MoCatalogNGetText"
            ,"MoCatalogPGetText"
            ,"MoCatalogNPGetText"]    {
            address := dllCall("Kernel32.dll\GetProcAddress", "Ptr",hMod, "AStr",procName, "Ptr")
            if (!address)    {
                this._moCatalogProcTable := {}
                return false
            }
            this._moCatalogProcTable.%procName% := address
        }
        return true
    }
    static _clearMoCatalogProcs()    {
        this._moCatalogProcTable := {}
    }
    static _onExiting(exitReason, exitCode)    {
        this._freeLibraries(true)
    }
    ;-------------------------------------------------------------------------------------------
    static _localeDir := A_ScriptDir . "\locale"
    static _LocaleDirUtf8Ptr    {
        get  {
            static ptr := 0
            if (!ptr)    {
                localeDir := this._localeDir
                this._localeDirUtf8 := buffer(byteSize := strPut(localeDir, "UTF-8"), 0)
                strPut(localeDir, this._localeDirUtf8, "UTF-8")
                ptr := this._localeDirUtf8.Ptr
            }
            return ptr
        }
    }
    /*
    All input and output strings of the DLL API are UTF-8 encoded narrow strings.
    localeName must specify a UTF-8 locale (for example, ko_KR.UTF-8).
    Translation catalogs are expected to use UTF-8.
    */
    static _LocaleName => _AhkLocaleSwitcher.getLocale() . ".UTF-8"
    static _hCatalogTable := map()
    static _ensureHCatalog(localeName, domain)    {
        if (!this._hCatalogTable.has(localeName))
            this._hCatalogTable[localeName] := map()
        if (!this._hCatalogTable[localeName].has(domain))    {
            bufLocaleName := buffer(strPut(localeName, "UTF-8"), 0)
            strPut(localeName, bufLocaleName, "UTF-8")
            bufDomain := buffer(strPut(domain, "UTF-8"), 0)
            strPut(domain, bufDomain, "UTF-8")
            this._hCatalogTable[localeName][domain] := dllCall(this._moCatalogProcTable.MoCatalogCreate
                ,"Ptr",this._LocaleDirUtf8Ptr
                ,"Ptr",bufLocaleName.Ptr
                ,"Ptr",bufDomain.Ptr
                ,"Ptr")
        }
        return this._hCatalogTable[localeName][domain]
    }
    static _destroyHCatalogsOfLocale(localeName)    {
        if (!this._hCatalogTable.has(localeName))
            return
        hLocaleCatalogTable := this._hCatalogTable[localeName].clone()
        this._hCatalogTable.delete(localeName)
        for domain,hCatalog in hLocaleCatalogTable    {
            if (hCatalog)
                dllCall(this._moCatalogProcTable.MoCatalogDestroy, "Ptr",hCatalog)
        }
    }
    static _destroyAllHCatalogs()    {
        hCatalogTable := this._simpleDeepClone(this._hCatalogTable)
        this._hCatalogTable := map()
        for localeName,hLocaleCatalogTable in hCatalogTable    {
            for domain,hCatalog in hLocaleCatalogTable    {
                if (hCatalog)
                    dllCall(this._moCatalogProcTable.MoCatalogDestroy, "Ptr",hCatalog)
            }
        }
    }
    ;-------------------------------------------------------------------------------------------
    static getText(&text, domain := "default")    {
        if (!this._Ready)
            return text
        hCatalog := this._ensureHCatalog(this._LocaleName, domain)
        if (!hCatalog)
            return text
        bufMsgId := buffer(strPut(text, "UTF-8"), 0)
        strPut(text, bufMsgId, "UTF-8")
        requiredSize := dllCall(this._moCatalogProcTable.MoCatalogGetText
            ,"Ptr",hCatalog
            ,"Ptr",bufMsgId.Ptr
            ,"Ptr",0
            ,"UPtr",0
            ,"UPtr")
        if (requiredSize)    {
            bufTranslated := buffer(requiredSize, 0)
            requiredSize := dllCall(this._moCatalogProcTable.MoCatalogGetText
                ,"Ptr",hCatalog
                ,"Ptr",bufMsgId.Ptr
                ,"Ptr",bufTranslated.Ptr
                ,"UPtr",requiredSize
                ,"UPtr")     
            if (requiredSize)
                return strGet(bufTranslated, requiredSize, "UTF-8")
        }
        return text
    }
    static nGetText(&single, &plural, num, domain := "default")    {
        num := this._clampInt32(num)
        if (!this._Ready)
            return (num == 1 ? single : plural)
        hCatalog := this._ensureHCatalog(this._LocaleName, domain)
        if (!hCatalog)
            return (num == 1 ? single : plural)
        bufSingle := buffer(strPut(single, "UTF-8"), 0)
        strPut(single, bufSingle, "UTF-8")
        bufPlural := buffer(strPut(plural, "UTF-8"), 0)
        strPut(plural, bufPlural, "UTF-8")
        requiredSize := dllCall(this._moCatalogProcTable.MoCatalogNGetText
            ,"Ptr",hCatalog
            ,"Ptr",bufSingle.Ptr
            ,"Ptr",bufPlural.Ptr
            ,"Int",num
            ,"Ptr",0
            ,"UPtr",0
            ,"UPtr")
        if (requiredSize)    {
            bufTranslated := buffer(requiredSize, 0)
            requiredSize := dllCall(this._moCatalogProcTable.MoCatalogNGetText
                ,"Ptr",hCatalog
                ,"Ptr",bufSingle.Ptr
                ,"Ptr",bufPlural.Ptr
                ,"Int",num
                ,"Ptr",bufTranslated.Ptr
                ,"UPtr",requiredSize
                ,"UPtr")
            if (requiredSize)
                return strGet(bufTranslated, requiredSize, "UTF-8")
        }
        return (num == 1 ? single : plural)
    }
    static pGetText(&text, context, domain := "default")    {
        if (!this._Ready)
            return text
        hCatalog := this._ensureHCatalog(this._LocaleName, domain)
        if (!hCatalog)
            return text
        bufContext := buffer(strPut(context, "UTF-8"), 0)
        strPut(context, bufContext, "UTF-8")
        bufMsgId := buffer(strPut(text, "UTF-8"), 0)
        strPut(text, bufMsgId, "UTF-8")
        requiredSize := dllCall(this._moCatalogProcTable.MoCatalogPGetText
            ,"Ptr",hCatalog
            ,"Ptr",bufContext.Ptr
            ,"Ptr",bufMsgId.Ptr
            ,"Ptr",0
            ,"UPtr",0
            ,"UPtr")
        if (requiredSize)    {
            bufTranslated := buffer(requiredSize, 0)
            requiredSize := dllCall(this._moCatalogProcTable.MoCatalogPGetText
                ,"Ptr",hCatalog
                ,"Ptr",bufContext.Ptr
                ,"Ptr",bufMsgId.Ptr
                ,"Ptr",bufTranslated.Ptr
                ,"UPtr",requiredSize
                ,"UPtr")
            if (requiredSize)
                return strGet(bufTranslated, requiredSize, "UTF-8")
        }
        return text
    }
    static npGetText(&single, &plural, num, context, domain := "default")    {
        num := this._clampInt32(num)
        if (!this._Ready)
            return (num == 1 ? single : plural)
        hCatalog := this._ensureHCatalog(this._LocaleName, domain)
        if (!hCatalog)
            return (num == 1 ? single : plural)
        bufContext := buffer(strPut(context, "UTF-8"), 0)
        strPut(context, bufContext, "UTF-8")
        bufSingle := buffer(strPut(single, "UTF-8"), 0)
        strPut(single, bufSingle, "UTF-8")
        bufPlural := buffer(strPut(plural, "UTF-8"), 0)
        strPut(plural, bufPlural, "UTF-8")
        requiredSize := dllCall(this._moCatalogProcTable.MoCatalogNPGetText
            ,"Ptr",hCatalog
            ,"Ptr",bufContext.Ptr
            ,"Ptr",bufSingle.Ptr
            ,"Ptr",bufPlural.Ptr
            ,"Int",num
            ,"Ptr",0
            ,"UPtr",0
            ,"UPtr")
        if (requiredSize)    {
            bufTranslated := buffer(requiredSize, 0)
            requiredSize := dllCall(this._moCatalogProcTable.MoCatalogNPGetText
                ,"Ptr",hCatalog
                ,"Ptr",bufContext.Ptr
                ,"Ptr",bufSingle.Ptr
                ,"Ptr",bufPlural.Ptr
                ,"Int",num
                ,"Ptr",bufTranslated.Ptr
                ,"UPtr",requiredSize
                ,"UPtr")
            if (requiredSize)
                return strGet(bufTranslated, requiredSize, "UTF-8")
        }
        return (num == 1 ? single : plural)
    }
    static loadTextDomain(domain := "default", locale?)    {
        if (!this._Ready)
            return false
        return !!this._ensureHCatalog(isSet(locale)? locale . ".UTF-8" : this._LocaleName, domain)
    }
    ;-------------------------------------------------------------------------------------------
    static _getFullPathName(fileName)    {
        neededChars := dllCall("Kernel32.dll\GetFullPathNameW", "WStr",fileName, "UInt",0, "Ptr",0, "Ptr",0, "UInt")
        if (!neededChars)
            return fileName
        fullPathName := buffer(neededChars * 2, 0)
        copiedChars := dllCall("Kernel32.dll\GetFullPathNameW", "WStr",fileName, "UInt",neededChars, "Ptr",fullPathName.Ptr, "Ptr",0, "UInt")
        if (!copiedChars)
            return fileName
        return strGet(fullPathName, copiedChars, "UTF-16")
    }
    static _simpleDeepClone(obj)    {
        nobj := obj.clone()
        for k,v in obj    {
            if (isObject(v))
                nobj[k] := this._simpleDeepClone(v)
        }
        return nobj
    }
    static _clampInt32(n) => n > 2147483647 ? 2147483647 : n < -2147483648 ? -2147483648 : n
}
;=======================================================================================================================
class _AhkLocaleSwitcher
{
    ;  WARNING: Backward compatibility is not guaranteed for any methods or properties in this class.
    static _originalLocale  := "en_US"
        ,_localeStack       := []
    ;-------------------------------------------------------------------------------------------
    /*
    AHK-specific initializer.
    WordPress stores the original locale in WP_Locale_Switcher::__construct()
    based on the current determined locale, whereas this implementation
    explicitly initializes that baseline from the outside.
    */
    static initOriginalLocale(locale)    {
        if (this._originalLocale !== locale)    {
            this._originalLocale := locale
            this._localeStack := []
        }
        return locale
    }
    /*
    static _changeLocale(locale)    { ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/change_locale/
        ;  Nothing to implement for now.
    }
    */
    ;-------------------------------------------------------------------------------------------
    static getLocale()          => (this._localeStack.Length ? this._localeStack[this._localeStack.Length] : this._originalLocale)
    static isSwitched()         => (!!this._localeStack.Length) ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/is_switched/
    static getSwitchedLocale()  => (this._localeStack.Length ? this._localeStack[this._localeStack.Length] : false) ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/get_switched_locale/
    ;-------------------------------------------------------------------------------------------
    static switchToLocale(locale)    { ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/switch_to_locale/
        currentLocale := this.getLocale()
        if (currentLocale == locale)
            return false
        this._localeStack.push(locale)
        ;  this._changeLocale(locale)
        return true
    }
    static restorePreviousLocale()    { ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/restore_previous_locale/
        if (!this._localeStack.Length)
            return false
        this._localeStack.pop()
        locale := this.getLocale()
        ;  this._changeLocale(locale)
        return locale
    }
    static restoreCurrentLocale()    { ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/restore_current_locale/
        if (!this._localeStack.Length)
            return false
        this._localeStack := [this._originalLocale]
        return this.restorePreviousLocale()
    }
}