.pragma library
.import "WidgetRegistry.js" as WidgetRegistry

var paletteNames = ({
    "catppuccin-frappe": true,
    "catppuccin-latte": true,
    "catppuccin-macchiato": true,
    "catppuccin-mocha": true,
    "dracula": true,
    "everforest": true,
    "gruvbox": true,
    "nord": true,
    "rose-pine": true,
    "solarized-dark": true,
    "tokyo-night": true
});

var topLevelKeys = ({
    colorScheme: true,
    panelWorkspace: true,
    panelWidth: true,
    panelMargin: true,
    launcher: true,
    powerMenu: true,
    audioQuickSwitch: true,
    audioDeviceNames: true,
    audioInputQuickSwitch: true,
    audioInputDeviceNames: true,
    backlightDevice: true,
    weatherEnabled: true,
    weatherLocation: true,
    // Accepted for upgrade compatibility only. Dashboard placement is app-owned.
    topAnchor: true,
    bottomAnchor: true,
    sidebar: true,
    sidebarSystemTray: true,
    maxVisibleNotification: true,
    maxVisibleNotifications: true
});

var launcherKeys = ({ width: true, visibleRows: true, searchUrl: true, bangs: true });
var powerMenuKeys = ({ lockCommand: true });

function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}

function hasOwn(value, key) {
    return Object.prototype.hasOwnProperty.call(value, key);
}

function error(errors, path, message) {
    errors.push({ kind: "validation", path: path, line: 0, column: 0, message: message });
}

function validateKnownKeys(value, allowed, path, errors) {
    if (!isObject(value))
        return;
    var keys = Object.keys(value);
    for (var i = 0; i < keys.length; i++) {
        if (!hasOwn(allowed, keys[i]))
            error(errors, path + "." + keys[i], "Unknown configuration property.");
    }
}

function validateString(value, path, errors, options) {
    var opts = options || ({});
    if (typeof value !== "string") {
        error(errors, path, "Expected a string.");
        return;
    }
    if (!opts.allowEmpty && value.trim() === "")
        error(errors, path, "Value must not be empty.");
    if (value.length > (opts.maxLength || 256))
        error(errors, path, "Value is longer than " + (opts.maxLength || 256) + " characters.");
}

function validateBoolean(value, path, errors) {
    if (typeof value !== "boolean")
        error(errors, path, "Expected true or false.");
}

function validateInteger(value, path, errors, minimum, maximum) {
    if (typeof value !== "number" || !isFinite(value) || Math.floor(value) !== value) {
        error(errors, path, "Expected a whole number.");
        return;
    }
    if (value < minimum || value > maximum)
        error(errors, path, "Expected a value from " + minimum + " to " + maximum + ".");
}

function validateStringList(value, path, errors) {
    if (!Array.isArray(value)) {
        error(errors, path, "Expected an array of strings.");
        return;
    }
    var seen = ({});
    for (var i = 0; i < value.length; i++) {
        var itemPath = path + "[" + i + "]";
        validateString(value[i], itemPath, errors, { maxLength: 256 });
        if (typeof value[i] === "string") {
            var key = value[i].trim();
            if (hasOwn(seen, key))
                error(errors, itemPath, "Duplicate entry '" + key + "'.");
            seen[key] = true;
        }
    }
}

function validateStringMap(value, path, errors) {
    if (!isObject(value)) {
        error(errors, path, "Expected an object containing string values.");
        return;
    }
    var keys = Object.keys(value);
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (key === "__proto__" || key === "constructor" || key === "prototype" || key.trim() === "")
            error(errors, path + "." + key, "Invalid property name.");
        if (key.length > 256)
            error(errors, path + "." + key, "Property name is longer than 256 characters.");
        validateString(value[key], path + "." + key, errors, { maxLength: 256 });
    }
}

function validateCommand(value, path, errors) {
    if (!Array.isArray(value) || value.length === 0) {
        error(errors, path, "Expected a non-empty command array.");
        return;
    }
    if (value.length > 32)
        error(errors, path, "Command may contain at most 32 arguments.");
    for (var i = 0; i < value.length; i++)
        validateString(value[i], path + "[" + i + "]", errors, { maxLength: 1024 });
}

function validateUrlTemplate(value, path, errors) {
    validateString(value, path, errors, { maxLength: 2048 });
    if (typeof value !== "string")
        return;
    if (!/^https:\/\//i.test(value))
        error(errors, path, "URL templates must use HTTPS.");
    var first = value.indexOf("{query}");
    if (first < 0 || value.indexOf("{query}", first + 1) >= 0)
        error(errors, path, "URL templates must contain exactly one {query} placeholder.");
}

function validateBangs(value, path, errors) {
    if (!isObject(value)) {
        error(errors, path, "Expected an object mapping bang names to URL templates.");
        return;
    }
    var keys = Object.keys(value);
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (!/^[a-z0-9][a-z0-9-]{0,31}$/.test(key))
            error(errors, path + "." + key, "Bang names must use lowercase letters, digits, or hyphens.");
        if (WidgetRegistry.panelForBang(key) !== "")
            error(errors, path + "." + key, "Bang '" + key + "' is reserved for a Speshell panel.");
        validateUrlTemplate(value[key], path + "." + key, errors);
    }
}

function validate(input) {
    var errors = [];
    if (!isObject(input)) {
        error(errors, "$", "The configuration root must be an object.");
        return errors;
    }

    validateKnownKeys(input, topLevelKeys, "$", errors);
    if (hasOwn(input, "colorScheme")) {
        validateString(input.colorScheme, "$.colorScheme", errors, { maxLength: 64 });
        if (typeof input.colorScheme === "string" && !hasOwn(paletteNames, input.colorScheme))
            error(errors, "$.colorScheme", "Unknown color scheme '" + input.colorScheme + "'.");
    }
    if (hasOwn(input, "panelWorkspace")) validateString(input.panelWorkspace, "$.panelWorkspace", errors, { maxLength: 128 });
    if (hasOwn(input, "panelWidth")) validateInteger(input.panelWidth, "$.panelWidth", errors, 240, 1200);
    if (hasOwn(input, "panelMargin")) validateInteger(input.panelMargin, "$.panelMargin", errors, 0, 128);

    if (hasOwn(input, "launcher")) {
        if (!isObject(input.launcher)) {
            error(errors, "$.launcher", "Expected an object.");
        } else {
            validateKnownKeys(input.launcher, launcherKeys, "$.launcher", errors);
            if (hasOwn(input.launcher, "width")) validateInteger(input.launcher.width, "$.launcher.width", errors, 280, 1200);
            if (hasOwn(input.launcher, "visibleRows")) validateInteger(input.launcher.visibleRows, "$.launcher.visibleRows", errors, 1, 20);
            if (hasOwn(input.launcher, "searchUrl")) validateUrlTemplate(input.launcher.searchUrl, "$.launcher.searchUrl", errors);
            if (hasOwn(input.launcher, "bangs")) validateBangs(input.launcher.bangs, "$.launcher.bangs", errors);
        }
    }

    if (hasOwn(input, "powerMenu")) {
        if (!isObject(input.powerMenu)) {
            error(errors, "$.powerMenu", "Expected an object.");
        } else {
            validateKnownKeys(input.powerMenu, powerMenuKeys, "$.powerMenu", errors);
            if (hasOwn(input.powerMenu, "lockCommand")) validateCommand(input.powerMenu.lockCommand, "$.powerMenu.lockCommand", errors);
        }
    }

    if (hasOwn(input, "audioQuickSwitch")) validateStringList(input.audioQuickSwitch, "$.audioQuickSwitch", errors);
    if (hasOwn(input, "audioDeviceNames")) validateStringMap(input.audioDeviceNames, "$.audioDeviceNames", errors);
    if (hasOwn(input, "audioInputQuickSwitch")) validateStringList(input.audioInputQuickSwitch, "$.audioInputQuickSwitch", errors);
    if (hasOwn(input, "audioInputDeviceNames")) validateStringMap(input.audioInputDeviceNames, "$.audioInputDeviceNames", errors);
    if (hasOwn(input, "backlightDevice")) validateString(input.backlightDevice, "$.backlightDevice", errors, { allowEmpty: true, maxLength: 128 });
    if (hasOwn(input, "weatherEnabled")) validateBoolean(input.weatherEnabled, "$.weatherEnabled", errors);
    if (hasOwn(input, "weatherLocation")) validateString(input.weatherLocation, "$.weatherLocation", errors, { allowEmpty: true, maxLength: 200 });
    if (hasOwn(input, "maxVisibleNotification") && hasOwn(input, "maxVisibleNotifications"))
        error(errors, "$.maxVisibleNotifications", "Use only maxVisibleNotification; both aliases were provided.");
    var notificationKey = hasOwn(input, "maxVisibleNotification") ? "maxVisibleNotification"
        : (hasOwn(input, "maxVisibleNotifications") ? "maxVisibleNotifications" : "");
    if (notificationKey !== "") {
        var limit = input[notificationKey];
        if (limit !== -1)
            validateInteger(limit, "$." + notificationKey, errors, 1, 50);
    }

    return errors;
}

function copyArray(value) {
    return value ? value.slice() : [];
}

function isPaletteName(value) {
    return typeof value === "string" && hasOwn(paletteNames, value);
}

function normalize(value) {
    var input = isObject(value) ? value : ({});
    var launcher = isObject(input.launcher) ? input.launcher : ({});
    var powerMenu = isObject(input.powerMenu) ? input.powerMenu : ({});
    var notificationLimit = hasOwn(input, "maxVisibleNotification")
        ? input.maxVisibleNotification
        : (hasOwn(input, "maxVisibleNotifications") ? input.maxVisibleNotifications : 3);

    return {
        colorScheme: hasOwn(input, "colorScheme") ? input.colorScheme : "gruvbox",
        panelWorkspace: hasOwn(input, "panelWorkspace") ? input.panelWorkspace.trim() : "special:term",
        panelWidth: hasOwn(input, "panelWidth") ? input.panelWidth : 420,
        panelMargin: hasOwn(input, "panelMargin") ? input.panelMargin : 16,
        launcher: {
            width: hasOwn(launcher, "width") ? launcher.width : 540,
            visibleRows: hasOwn(launcher, "visibleRows") ? launcher.visibleRows : 5,
            searchUrl: hasOwn(launcher, "searchUrl") ? launcher.searchUrl : "https://duckduckgo.com/?q={query}",
            bangs: hasOwn(launcher, "bangs") ? launcher.bangs : ({})
        },
        powerMenu: {
            lockCommand: hasOwn(powerMenu, "lockCommand") ? copyArray(powerMenu.lockCommand) : ["hyprlock"]
        },
        audioQuickSwitch: hasOwn(input, "audioQuickSwitch") ? copyArray(input.audioQuickSwitch) : [],
        audioDeviceNames: hasOwn(input, "audioDeviceNames") ? input.audioDeviceNames : ({}),
        audioInputQuickSwitch: hasOwn(input, "audioInputQuickSwitch") ? copyArray(input.audioInputQuickSwitch) : [],
        audioInputDeviceNames: hasOwn(input, "audioInputDeviceNames") ? input.audioInputDeviceNames : ({}),
        backlightDevice: hasOwn(input, "backlightDevice") ? input.backlightDevice.trim() : "",
        weatherEnabled: hasOwn(input, "weatherEnabled") ? input.weatherEnabled : false,
        weatherLocation: hasOwn(input, "weatherLocation") ? input.weatherLocation.trim() : "",
        maxVisibleNotification: notificationLimit
    };
}

function stripComments(text) {
    var output = "";
    var inString = false;
    var inLineComment = false;
    var inBlockComment = false;
    for (var i = 0; i < text.length; i++) {
        var ch = text[i];
        var next = i + 1 < text.length ? text[i + 1] : "";
        if (inLineComment) {
            if (ch === "\n") {
                inLineComment = false;
                output += ch;
            } else {
                output += " ";
            }
        } else if (inBlockComment) {
            if (ch === "*" && next === "/") {
                output += "  ";
                inBlockComment = false;
                i++;
            } else {
                output += ch === "\n" ? "\n" : " ";
            }
        } else if (inString) {
            output += ch;
            if (ch === "\\" && i + 1 < text.length)
                output += text[++i];
            else if (ch === "\"")
                inString = false;
        } else if (ch === "/" && next === "/") {
            output += "  ";
            inLineComment = true;
            i++;
        } else if (ch === "/" && next === "*") {
            output += "  ";
            inBlockComment = true;
            i++;
        } else {
            if (ch === "\"")
                inString = true;
            output += ch;
        }
    }
    return output;
}

function stripTrailingCommas(text) {
    var output = "";
    var inString = false;
    for (var i = 0; i < text.length; i++) {
        var ch = text[i];
        if (inString) {
            output += ch;
            if (ch === "\\" && i + 1 < text.length)
                output += text[++i];
            else if (ch === "\"")
                inString = false;
        } else if (ch === "\"") {
            inString = true;
            output += ch;
        } else if (ch === ",") {
            var nextIndex = i + 1;
            while (nextIndex < text.length && /\s/.test(text[nextIndex]))
                nextIndex++;
            output += nextIndex < text.length && (text[nextIndex] === "}" || text[nextIndex] === "]") ? " " : ch;
        } else {
            output += ch;
        }
    }
    return output;
}

function lineAndColumn(text, position) {
    var line = 1;
    var column = 1;
    for (var i = 0; i < position && i < text.length; i++) {
        if (text[i] === "\n") {
            line++;
            column = 1;
        } else {
            column++;
        }
    }
    return { line: line, column: column };
}

function syntaxDiagnostic(errorValue, normalizedText) {
    var message = String(errorValue && errorValue.message ? errorValue.message : errorValue);
    var position = -1;
    var positionMatch = message.match(/position\s+(\d+)/i);
    if (positionMatch)
        position = parseInt(positionMatch[1], 10);
    var location = position >= 0 ? lineAndColumn(normalizedText, position) : { line: 0, column: 0 };
    var lineMatch = message.match(/line\s+(\d+)/i);
    var columnMatch = message.match(/column\s+(\d+)/i);
    if (lineMatch) location.line = parseInt(lineMatch[1], 10);
    if (columnMatch) location.column = parseInt(columnMatch[1], 10);
    return { kind: "syntax", path: "$", line: location.line, column: location.column, message: message };
}

function parseAndValidate(text) {
    var source = String(text || "");
    if (source.trim() === "")
        return { ok: false, config: null, errors: [{ kind: "syntax", path: "$", line: 1, column: 1, message: "The configuration file is empty." }] };

    var normalizedText = stripTrailingCommas(stripComments(source));
    var parsed = null;
    try {
        parsed = JSON.parse(normalizedText);
    } catch (parseError) {
        return { ok: false, config: null, errors: [syntaxDiagnostic(parseError, normalizedText)] };
    }

    var errors = validate(parsed);
    return errors.length > 0
        ? { ok: false, config: null, errors: errors }
        : { ok: true, config: normalize(parsed), errors: [] };
}

function parse(text) {
    var result = parseAndValidate(text);
    if (!result.ok)
        throw new Error(result.errors.length > 0 ? result.errors[0].message : "Invalid configuration.");
    return result.config;
}
