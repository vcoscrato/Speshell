import QtQuick
import "." as Widgets

// Speaker and microphone together; the host's WidgetLoader sets the mode.
Widgets.AudioSliderCard {
    mode: "combined"
}
