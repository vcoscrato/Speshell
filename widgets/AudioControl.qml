import QtQuick
import "." as Widgets
import "../services" as Services

Widgets.AudioSliderCard {
    mode: (Services.ConfigService.config && Services.ConfigService.config.audioPanelMode === "separate")
        ? "output"
        : "combined"
}
