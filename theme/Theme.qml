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
    property real textScale: 1.0
    readonly property int fontSizeMicro:      Math.round(9 * root.textScale)
    readonly property int fontSizeCaption:    Math.round(10 * root.textScale)
    readonly property int fontSizeSmall:      Math.round(11 * root.textScale)
    readonly property int fontSizeSupporting: Math.round(12 * root.textScale)
    readonly property int fontSizeNormal:     Math.round(13 * root.textScale)
    readonly property int fontSizeEmphasis:   Math.round(14 * root.textScale)
    readonly property int fontSizeLarge:      Math.round(16 * root.textScale)
    readonly property int fontSizeTitle:      Math.round(20 * root.textScale)
    readonly property int fontSizeHuge:       Math.round(40 * root.textScale)

    // Icons are geometry, not typography. Keep them stable when only text scales.
    readonly property int iconSizeTiny:   12   // inline markers, chevrons, chip icons
    readonly property int iconSizeSmall:  14   // card headers, compact buttons
    readonly property int iconSizeMedium: 18   // row icons, standard buttons
    readonly property int iconSizeLarge:  24   // sidebar, OSDs, primary actions

    // ── Spacing ─────────────────────────────────────────────
    readonly property int spacingMicro:  2     // stacked title/subtitle lines
    readonly property int spacingTiny:   4
    readonly property int spacingSmall:  8
    readonly property int spacingMedium: 12
    readonly property int spacingLarge:  16
    readonly property int spacingXL:     24
    readonly property int panelPadding:  root.spacingMedium

    // ── Controls ────────────────────────────────────────────
    // Floors: controls holding text still grow with textScale.
    readonly property int controlHeightSmall: 24   // tabs, compact and header buttons
    readonly property int controlHeight:      32   // rows, fields, sliders, buttons

    // ── Geometry ────────────────────────────────────────────
    readonly property int borderRadius:      4
    readonly property int borderRadiusSmall: 3
    readonly property int surfaceCornerCut:  16
    readonly property int borderWidth:       1

    // ── Interaction states ──────────────────────────────────
    // Neutral controls rest on controlFill/controlBorder and use cardHover on hover.
    // Tone-colored controls tint their tone: tintSubtle at rest, tintStrong when
    // hovered, armed, or selected among filled siblings, tintOutline for borders
    // (tintOutlineStrong when armed or selected).
    readonly property real tintSubtle:  0.12
    readonly property real tintStrong:  0.2
    readonly property real tintOutline: 0.45
    readonly property real tintOutlineStrong: 0.85
    readonly property real disabledOpacity: 0.45
    readonly property color controlFill:    root.alpha(root.overlay, root.tintSubtle)
    readonly property color controlBorder:  root.alpha(root.overlay, 0.24)
    readonly property color selectedFill:   root.alpha(root.accent, root.tintSubtle)
    readonly property color selectedBorder: root.alpha(root.accent, root.tintOutline)

    // ── Animation ───────────────────────────────────────────
    readonly property int animDurationFast: 100
    readonly property int animDuration:     200
    readonly property int animDurationSlow: 350
    readonly property int animEasing:       Easing.OutCubic

    // ── Layout ──────────────────────────────────────────────
    readonly property int sidebarWidth:       60
    readonly property int sidebarIconSize:    52
    readonly property int reservedBottomPanelHeight: 256
    readonly property int separatorThickness: 1
    readonly property color separator:        root.alpha(root.surface2, 0.72)

    // ── Helpers ─────────────────────────────────────────────
    function alpha(color, value) {
        return Qt.rgba(color.r, color.g, color.b, value);
    }

    function toneColor(tone) {
        if (tone === "success") return root.success;
        if (tone === "warning") return root.warning;
        if (tone === "error") return root.error;
        if (tone === "info") return root.sky;
        return root.overlay;
    }
}
