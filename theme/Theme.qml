pragma Singleton
import QtQuick
import "." as ThemeModule

QtObject {
    id: root

    // Active palette name — loaded from config
    property string paletteName: "gruvbox"

    // Resolve palette
    readonly property var _p: ThemeModule.Palettes.getPalette(paletteName)

    // ── Colors ──────────────────────────────────────────────
    readonly property color bg:        _p.base
    readonly property color mantle:    _p.mantle
    readonly property color crust:     _p.crust
    readonly property color card:      _p.surface0
    readonly property color cardHover: _p.surface1
    readonly property color surface2:  _p.surface2
    readonly property color overlay:   _p.overlay0

    readonly property color text:      _p.text
    readonly property color subtext:   _p.subtext0
    readonly property color subtextBright: _p.subtext1

    readonly property color accent: {
        switch(paletteName) {
            case "nord": return _p.blue;
            case "dracula": return _p.pink;
            case "gruvbox": return _p.peach;
            case "tokyo-night": return _p.blue;
            case "rose-pine": return _p.rosewater;
            case "solarized-dark": return _p.yellow;
            case "everforest": return _p.green;
            default: return _p.lavender;
        }
    }
    
    readonly property color accentAlt: {
        switch(paletteName) {
            case "nord": return _p.sky;
            case "dracula": return _p.lavender;
            case "gruvbox": return _p.yellow;
            case "tokyo-night": return _p.sky;
            case "rose-pine": return _p.pink;
            case "solarized-dark": return _p.peach;
            case "everforest": return _p.blue;
            default: return _p.mauve;
        }
    }
    readonly property color pink:      _p.pink

    readonly property color success:   _p.green
    readonly property color warning:   _p.yellow
    readonly property color error:     _p.red

    readonly property color teal:      _p.teal
    readonly property color sky:       _p.sky
    readonly property color blue:      _p.blue
    readonly property color peach:     _p.peach
    readonly property color yellow:    _p.yellow
    readonly property color rosewater: _p.rosewater

    // ── Typography ──────────────────────────────────────────
    readonly property string fontFamily: "Inter, Segoe UI, Roboto, sans-serif"
    readonly property int fontSizeSmall:  11
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge:  16
    readonly property int fontSizeXL:     24
    readonly property int fontSizeHuge:   40

    // ── Spacing ─────────────────────────────────────────────
    readonly property int spacingTiny:   4
    readonly property int spacingSmall:  8
    readonly property int spacingMedium: 12
    readonly property int spacingLarge:  16
    readonly property int spacingXL:     24

    // ── Geometry ────────────────────────────────────────────
    readonly property int borderRadius:      4
    readonly property int borderRadiusSmall: 3
    readonly property int surfaceCornerCut:  16
    readonly property int borderWidth:       1
    readonly property int cardElevation:     2

    // ── Animation ───────────────────────────────────────────
    readonly property int animDuration:     200
    readonly property int animDurationSlow: 350

    // ── Layout ──────────────────────────────────────────────
    readonly property int sidebarWidth:       60
    readonly property int sidebarIconSize:    52
    readonly property int reservedBottomPanelHeight: 256
    readonly property int separatorThickness: 1
    readonly property color separator:        Qt.rgba(surface2.r, surface2.g, surface2.b, 0.72)

    // ── Helpers ─────────────────────────────────────────────
    function toneColor(tone) {
        if (tone === "success") return root.success;
        if (tone === "warning") return root.warning;
        if (tone === "error") return root.error;
        if (tone === "info") return root.sky;
        return root.overlay;
    }
}
