.pragma library

function buildIssues(ready, weatherEnabled, hasCurl, configuredBacklight,
                     detectedBacklights, hasBrightnessctl, lockCommand,
                     lockerAvailable) {
    if (!ready)
        return [];

    var result = [];
    if (weatherEnabled && !hasCurl) {
        result.push({
            id: "weather-curl",
            title: "Weather unavailable",
            detail: "Weather is enabled, but curl is not installed."
        });
    }

    var requestedBacklight = String(configuredBacklight || "");
    if (requestedBacklight !== "") {
        if ((detectedBacklights || []).indexOf(requestedBacklight) === -1) {
            result.push({
                id: "backlight-device",
                title: "Backlight unavailable",
                detail: "The configured backlight device '" + requestedBacklight + "' was not found."
            });
        } else if (!hasBrightnessctl) {
            result.push({
                id: "backlight-helper",
                title: "Brightness controls unavailable",
                detail: "A backlight device is configured, but brightnessctl is not installed."
            });
        }
    }

    var locker = lockCommand && lockCommand.length > 0
        ? String(lockCommand[0] || "")
        : "";
    if (locker !== "" && !lockerAvailable) {
        result.push({
            id: "power-locker",
            title: "Screen locking unavailable",
            detail: "The configured locker '" + locker + "' could not be found."
        });
    }
    return result;
}
