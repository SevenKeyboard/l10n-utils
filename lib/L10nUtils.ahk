#Requires AutoHotkey v1.1.35+
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
;   Latest supported redistributable version
;     https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-supported-redistributable-version
;   Command-line options for the redistributable packages
;     https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files?view=msvc-170#command-line-options-for-the-redistributable-packages
;
;   MoCatalog.dll (64bits) - VirusTotal
;     https://www.virustotal.com/gui/file/20849495a31ce0747993c524148b710ba8e7a06547bae382a649df9958471a74
;   MoCatalog.dll - VirusTotal
;     https://www.virustotal.com/gui/file/50ce84b453b255ed6bf8a922f8357cd83145a6636ba400bcbb6233f2bc91f243
;   boost_locale-vc143-mt-x64-1_90.dll (64bits) - VirusTotal
;     https://www.virustotal.com/gui/file/e249266f7a8c3540c3ddd99a12015f01cf7d42c2be8e9b9442fb70eec35550d3
;   boost_locale-vc143-mt-x32-1_90.dll - VirusTotal
;     https://www.virustotal.com/gui/file/805b4728ceb20c32fa2483a93cd0a850e623a6fd77cca0b1ad44ac2d9b6a1557
;==============================================================

/*
my-app/
├─ MyApp.ahk
├─ lib/
│  └─ L10nUtils.ahk
├─ dll/
│  ├─ x64/
│  │  ├─ MoCatalog.dll
│  │  └─ boost_locale-vc143-mt-x64-1_90.dll
│  └─ x86/
│     ├─ MoCatalog.dll
│     └─ boost_locale-vc143-mt-x32-1_90.dll
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
    static _ := VersionManager_L10nUtils._init()
    _init()    {
        global
        L10NUTILS_VERSION := "0.0.0"
    }
}

__(byRef text, domain := "default")    { ;  https://developer.wordpress.org/reference/functions/__/
    return _AhkL10n.getText(text, domain)
}
_n(byRef single, byRef plural, num, domain := "default")    { ;  https://developer.wordpress.org/reference/functions/_n/
    return _AhkL10n.nGetText(single, plural, num, domain)
}
_x(byRef text, context, domain := "default")    { ;  https://developer.wordpress.org/reference/functions/_x/
    return _AhkL10n.pGetText(text, context, domain)
}
_nx(byRef single, byRef plural, num, context, domain := "default")    { ;  https://developer.wordpress.org/reference/functions/_nx/
    return _AhkL10n.npGetText(single, plural, num, context, domain)
}

initOriginalLocale(locale)    {
    return _AhkLocaleSwitcher.initOriginalLocale(locale)
}
getLocale()    { ;  https://developer.wordpress.org/reference/functions/get_locale/
    return _AhkLocaleSwitcher.getLocale()
}
isLocaleSwitched()    { ;  https://developer.wordpress.org/reference/functions/is_locale_switched/
    return _AhkLocaleSwitcher.isSwitched()
}
switchToLocale(locale)    { ;  https://developer.wordpress.org/reference/functions/switch_to_locale/
    return _AhkLocaleSwitcher.switchToLocale(locale)
}
restorePreviousLocale()    { ;  https://developer.wordpress.org/reference/functions/restore_previous_locale/
    return _AhkLocaleSwitcher.restorePreviousLocale()
}
restoreCurrentLocale()    { ;  https://developer.wordpress.org/reference/functions/restore_current_locale/
    return _AhkLocaleSwitcher.restoreCurrentLocale() ;  Restores the original locale and clears the switch stack.
}

class _AhkL10n
{
    ;  WARNING: Backward compatibility is not guaranteed for any methods or properties in this class.
    static _dllDir              := _AhkL10n._getFullPathName(A_ScriptDir . "\dll" . (A_PtrSize == 8 ? "\x64" : "\x86"))
        ,_moCatalogDllPath      := _AhkL10n._dllDir . "\MoCatalog.dll" ;  https://github.com/SevenKeyboard/mo-catalog
        ,_boostLocaleDllPath    := _AhkL10n._dllDir . (A_PtrSize == 8
            ? "\boost_locale-vc143-mt-x64-1_90.dll"     ;  vcpkg\installed\x64-windows\bin\boost_locale-vc143-mt-x64-1_90.dll
            : "\boost_locale-vc143-mt-x32-1_90.dll")    ;  vcpkg\installed\x86-windows\bin\boost_locale-vc143-mt-x32-1_90.dll
        ,_hMoCatalogMod         := 0
        ,_hBoostLocaleMod       := 0
        ,_moCatalogProcTable    := {}
        ,_objbmOnExiting        := objBindMethod(_AhkL10n, "_onExiting")
        ,_                      := _AhkL10n._init()
    _init()    {
        if (this._Ready)
            return true
        this._freeLibraries()
        return this._loadLibraries()
    }
    _Ready    {
        get  {
            return !!(this._hMoCatalogMod && this._hBoostLocaleMod)
        }
    }
    _loadLibraries()    {
        local
        this._clearMoCatalogProcs()
        this._hBoostLocaleMod:= this._hMoCatalogMod:= 0
        if (!fileExist(this._moCatalogDllPath) || !fileExist(this._boostLocaleDllPath))
            return false
        this._hBoostLocaleMod := dllCall("Kernel32.dll\LoadLibraryW", "WStr",this._boostLocaleDllPath, "Ptr")
        if (this._hBoostLocaleMod)    {
            this._hMoCatalogMod := dllCall("Kernel32.dll\LoadLibraryW", "WStr",this._moCatalogDllPath, "Ptr")
            if (!this._hMoCatalogMod)    {
                hMod := this._hBoostLocaleMod, this._hBoostLocaleMod := 0
                dllCall("Kernel32.dll\FreeLibrary", "Ptr",hMod), hMod := 0
            }
        }
        ok := !!(this._hMoCatalogMod && this._hBoostLocaleMod)
        if (ok)    {
            ok := this._resolveMoCatalogProcs(this._hMoCatalogMod)
            if (!ok)
                this._freeLibraries()
        }
        if (ok)
            onExit(this._objbmOnExiting)
        return ok
    }
    _freeLibraries(isExiting := false)    {
        if (!isExiting)
            onExit(this._objbmOnExiting, 0)
        this._destroyAllHCatalogs()
        this._clearMoCatalogProcs()
        if (this._hMoCatalogMod)    {
            hMod := this._hMoCatalogMod, this._hMoCatalogMod := 0
            dllCall("Kernel32.dll\FreeLibrary", "Ptr",hMod), hMod := 0
        }
        if (this._hBoostLocaleMod)    {
            hMod := this._hBoostLocaleMod, this._hBoostLocaleMod := 0
            dllCall("Kernel32.dll\FreeLibrary", "Ptr",hMod), hMod := 0
        }
    }
    _resolveMoCatalogProcs(hMod)    {
        local
        this._moCatalogProcTable := {}
        for _,procName in ["MoCatalogCreate"
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
            this._moCatalogProcTable[procName] := address
        }
        return true
    }
    _clearMoCatalogProcs()    {
        this._moCatalogProcTable := {}
    }
    _onExiting(exitReason, exitCode)    {
        this._freeLibraries(true)
    }
    ;-------------------------------------------------------------------------------------------
    static _localeDir := A_ScriptDir . "\locale"
    _LocaleDirUtf8Ptr    {
        get  {
            local
            static ptr := 0
            if (!ptr)    {
                localeDir := this._localeDir
                this.setCapacity("_localeDirUtf8", byteSize := strPut(localeDir, "UTF-8"))
                ptr := this.getAddress("_localeDirUtf8")
                dllCall("Ntdll.dll\RtlFillMemory", "Ptr",ptr, "UPtr",byteSize, "Int",0)
                strPut(localeDir, ptr + 0, "UTF-8")
            }
            return ptr
        }
    }
    _LocaleName    {
        get  {
            /*
            All input and output strings of the DLL API are UTF-8 encoded narrow strings.
            localeName must specify a UTF-8 locale (for example, ko_KR.UTF-8).
            Translation catalogs are expected to use UTF-8.
            */
            return _AhkLocaleSwitcher.getLocale() . ".UTF-8"
        }
    }
    static _hCatalogTable := object()
    _ensureHCatalog(localeName, domain)    {
        local
        if (!this._hCatalogTable.hasKey(localeName))
            this._hCatalogTable[localeName] := object()
        if (!this._hCatalogTable[localeName].hasKey(domain))    {
            varSetCapacity(localeNamePtr, strPut(localeName, "UTF-8"), 0)
            strPut(localeName, &localeNamePtr, "UTF-8")
            varSetCapacity(domainPtr, strPut(domain, "UTF-8"), 0)
            strPut(domain, &domainPtr, "UTF-8")
            this._hCatalogTable[localeName][domain] := dllCall(this._moCatalogProcTable.MoCatalogCreate
                ,"Ptr",this._LocaleDirUtf8Ptr
                ,"Ptr",&localeNamePtr
                ,"Ptr",&domainPtr
                ,"Ptr")
        }
        return this._hCatalogTable[localeName][domain]
    }
    _destroyHCatalogsOfLocale(localeName)    {
        local
        if (!this._hCatalogTable.hasKey(localeName))
            return
        hLocaleCatalogTable := this._hCatalogTable[localeName].clone()
        this._hCatalogTable.delete(localeName)
        for domain,hCatalog in hLocaleCatalogTable    {
            if (hCatalog)
                dllCall(this._moCatalogProcTable.MoCatalogDestroy, "Ptr",hCatalog)
        }
    }
    _destroyAllHCatalogs()    {
        local
        hCatalogTable := this._simpleDeepClone(this._hCatalogTable)
        this._hCatalogTable := object()
        for localeName,hLocaleCatalogTable in hCatalogTable    {
            for domain,hCatalog in hLocaleCatalogTable    {
                if (hCatalog)
                    dllCall(this._moCatalogProcTable.MoCatalogDestroy, "Ptr",hCatalog)
            }
        }
    }
    ;-------------------------------------------------------------------------------------------
    getText(byRef text, domain := "default")    {
        local
        if (!this._Ready)
            return text
        hCatalog := this._ensureHCatalog(this._LocaleName, domain)
        if (!hCatalog)
            return text
        varSetCapacity(msgIdPtr, strPut(text, "UTF-8"), 0)
        strPut(text, &msgIdPtr, "UTF-8")
        requiredSize := dllCall(this._moCatalogProcTable.MoCatalogGetText
            ,"Ptr",hCatalog
            ,"Ptr",&msgIdPtr
            ,"Ptr",0
            ,"UPtr",0
            ,"UPtr")
        if (requiredSize)    {
            varSetCapacity(translatedPtr, requiredSize, 0)
            requiredSize := dllCall(this._moCatalogProcTable.MoCatalogGetText
                ,"Ptr",hCatalog
                ,"Ptr",&msgIdPtr
                ,"Ptr",&translatedPtr
                ,"UPtr",requiredSize
                ,"UPtr")
            if (requiredSize)
                return strGet(&translatedPtr, requiredSize, "UTF-8")
        }
        return text
    }
    nGetText(byRef single, byRef plural, num, domain := "default")    {
        local
        if (!this._Ready)
            return (num == 1 ? single : plural)
        hCatalog := this._ensureHCatalog(this._LocaleName, domain)
        if (!hCatalog)
            return (num == 1 ? single : plural)
        varSetCapacity(singlePtr, strPut(single, "UTF-8"), 0)
        strPut(single, &singlePtr, "UTF-8")
        varSetCapacity(pluralPtr, strPut(plural, "UTF-8"), 0)
        strPut(plural, &pluralPtr, "UTF-8")
        requiredSize := dllCall(this._moCatalogProcTable.MoCatalogNGetText
            ,"Ptr",hCatalog
            ,"Ptr",&singlePtr
            ,"Ptr",&pluralPtr
            ,"Int",num
            ,"Ptr",0
            ,"UPtr",0
            ,"UPtr")
        if (requiredSize)    {
            varSetCapacity(translatedPtr, requiredSize, 0)
            requiredSize := dllCall(this._moCatalogProcTable.MoCatalogNGetText
                ,"Ptr",hCatalog
                ,"Ptr",&singlePtr
                ,"Ptr",&pluralPtr
                ,"Int",num
                ,"Ptr",&translatedPtr
                ,"UPtr",requiredSize
                ,"UPtr")
            if (requiredSize)
                return strGet(&translatedPtr, requiredSize, "UTF-8")
        }
        return (num == 1 ? single : plural)
    }
    pGetText(byRef text, context, domain := "default")    {
        local
        if (!this._Ready)
            return text
        hCatalog := this._ensureHCatalog(this._LocaleName, domain)
        if (!hCatalog)
            return text
        varSetCapacity(contextPtr, strPut(context, "UTF-8"), 0)
        strPut(context, &contextPtr, "UTF-8")
        varSetCapacity(msgIdPtr, strPut(text, "UTF-8"), 0)
        strPut(text, &msgIdPtr, "UTF-8")
        requiredSize := dllCall(this._moCatalogProcTable.MoCatalogPGetText
            ,"Ptr",hCatalog
            ,"Ptr",&contextPtr
            ,"Ptr",&msgIdPtr
            ,"Ptr",0
            ,"UPtr",0
            ,"UPtr")
        if (requiredSize)    {
            varSetCapacity(translatedPtr, requiredSize, 0)
            requiredSize := dllCall(this._moCatalogProcTable.MoCatalogPGetText
                ,"Ptr",hCatalog
                ,"Ptr",&contextPtr
                ,"Ptr",&msgIdPtr
                ,"Ptr",&translatedPtr
                ,"UPtr",requiredSize
                ,"UPtr")
            if (requiredSize)
                return strGet(&translatedPtr, requiredSize, "UTF-8")
        }
        return text
    }
    npGetText(byRef single, byRef plural, num, context, domain := "default")    {
        local
        if (!this._Ready)
            return (num == 1 ? single : plural)
        hCatalog := this._ensureHCatalog(this._LocaleName, domain)
        if (!hCatalog)
            return (num == 1 ? single : plural)
        varSetCapacity(contextPtr, strPut(context, "UTF-8"), 0)
        strPut(context, &contextPtr, "UTF-8")
        varSetCapacity(singlePtr, strPut(single, "UTF-8"), 0)
        strPut(single, &singlePtr, "UTF-8")
        varSetCapacity(pluralPtr, strPut(plural, "UTF-8"), 0)
        strPut(plural, &pluralPtr, "UTF-8")
        requiredSize := dllCall(this._moCatalogProcTable.MoCatalogNPGetText
            ,"Ptr",hCatalog
            ,"Ptr",&contextPtr
            ,"Ptr",&singlePtr
            ,"Ptr",&pluralPtr
            ,"Int",num
            ,"Ptr",0
            ,"UPtr",0
            ,"UPtr")
        if (requiredSize)    {
            varSetCapacity(translatedPtr, requiredSize, 0)
            requiredSize := dllCall(this._moCatalogProcTable.MoCatalogNPGetText
                ,"Ptr",hCatalog
                ,"Ptr",&contextPtr
                ,"Ptr",&singlePtr
                ,"Ptr",&pluralPtr
                ,"Int",num
                ,"Ptr",&translatedPtr
                ,"UPtr",requiredSize
                ,"UPtr")
            if (requiredSize)
                return strGet(&translatedPtr, requiredSize, "UTF-8")
        }
        return (num == 1 ? single : plural)
    }
    ;-------------------------------------------------------------------------------------------
    _getFullPathName(fileName)    {
        local
        neededChars := dllCall("Kernel32.dll\GetFullPathNameW", "WStr",fileName, "UInt",0, "Ptr",0, "Ptr",0, "UInt")
        if (!neededChars)
            return fileName
        varSetCapacity(fullPathName, neededChars * 2, 0)
        copiedChars := dllCall("Kernel32.dll\GetFullPathNameW", "WStr",fileName, "UInt",neededChars, "Ptr",&fullPathName, "Ptr",0, "UInt")
        if (!copiedChars)
            return fileName
        return strGet(&fullPathName, copiedChars, "UTF-16")
    }
    _simpleDeepClone(obj)    {
        local
        nobj := obj.clone()
        for k,v in obj    {
            if (isObject(v))
                nobj[k] := this._simpleDeepClone(v)
        }
        return nobj
    }
}

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
    initOriginalLocale(locale)    {
        if (this._originalLocale !== locale)    {
            this._originalLocale := locale
            this._localeStack := []
        }
        return locale
    }
    /*
    _changeLocale(locale)    { ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/change_locale/
        ;  Nothing to implement for now.
    }
    */
    ;-------------------------------------------------------------------------------------------
    getLocale()    {
        return this._localeStack.maxIndex()
            ? this._localeStack[this._localeStack.maxIndex()]
            : this._originalLocale
    }
    isSwitched()    { ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/is_switched/
        return !!this._localeStack.maxIndex()
    }
    getSwitchedLocale()    { ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/get_switched_locale/
        return this._localeStack.maxIndex()
            ? this._localeStack[this._localeStack.maxIndex()]
            : false
    }
    ;-------------------------------------------------------------------------------------------
    switchToLocale(locale)    { ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/switch_to_locale/
        local
        currentLocale := this.getLocale()
        if (currentLocale == locale)
            return false
        this._localeStack.push(locale)
        ;  this._changeLocale(locale)
        return true
    }
    restorePreviousLocale()    { ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/restore_previous_locale/
        local
        if (!this._localeStack.maxIndex())
            return false
        this._localeStack.pop()
        locale := this.getLocale()
        ;  this._changeLocale(locale)
        return locale
    }
    restoreCurrentLocale()    { ;  https://developer.wordpress.org/reference/classes/wp_locale_switcher/restore_current_locale/
        if (!this._localeStack.maxIndex())
            return false
        this._localeStack := [this._originalLocale]
        return this.restorePreviousLocale()
    }
}