.pragma library
.import "../core/WidgetRegistry.js" as WidgetRegistry

var panels = WidgetRegistry.bangPanels();

function urlFromTemplate(template, query) {
    return String(template || "").replace("{query}", encodeURIComponent(String(query || "")));
}

function panelResult(panel) {
    return {
        id: "panel:" + panel.panel,
        kind: "panel",
        title: panel.title,
        subtitle: "Open the Speshell " + panel.title.toLowerCase() + " panel",
        iconName: panel.icon,
        iconSource: "",
        badge: "PANEL",
        activatable: true,
        payload: { panel: panel.panel }
    };
}

function webResult(id, title, subtitle, url) {
    return {
        id: id,
        kind: "web",
        title: title,
        subtitle: subtitle,
        iconName: "web-search",
        iconSource: "",
        badge: "WEB",
        activatable: true,
        payload: { url: url }
    };
}

function configuredBangResults(prefix, bangs) {
    var results = [];
    var names = Object.keys(bangs || ({})).sort();
    for (var i = 0; i < names.length; i++) {
        if (names[i].indexOf(prefix) !== 0)
            continue;
        results.push(webResult(
            "bang:" + names[i],
            "!" + names[i],
            "Search the configured site",
            urlFromTemplate(bangs[names[i]], "")
        ));
    }
    return results;
}

function panelAvailable(panel, availablePanelNames) {
    return Array.isArray(availablePanelNames)
        && availablePanelNames.indexOf(panel.panel) >= 0;
}

function bangResults(query, launcherConfig, availablePanelNames) {
    var raw = String(query || "").trim();
    var config = launcherConfig || ({});
    var bangs = config.bangs || ({});
    var body = raw.substring(1);
    var space = body.search(/\s/);
    var alias = (space < 0 ? body : body.substring(0, space)).toLowerCase();
    var terms = space < 0 ? "" : body.substring(space).trim();

    if (space < 0) {
        var suggestions = [];
        for (var i = 0; i < panels.length; i++) {
            if (panelAvailable(panels[i], availablePanelNames)
                    && panels[i].bang.indexOf(alias) === 0)
                suggestions.push(panelResult(panels[i]));
        }
        suggestions = suggestions.concat(configuredBangResults(alias, bangs));
        if (suggestions.length > 0 || alias === "")
            return suggestions;
    }

    for (var j = 0; j < panels.length; j++) {
        if (panels[j].bang === alias) {
            return panelAvailable(panels[j], availablePanelNames)
                ? [panelResult(panels[j])]
                : [];
        }
    }

    if (Object.prototype.hasOwnProperty.call(bangs, alias)) {
        return [webResult(
            "bang:" + alias + ":" + terms,
            "Search !" + alias + (terms !== "" ? " for “" + terms + "”" : ""),
            "Configured web bang",
            urlFromTemplate(bangs[alias], terms)
        )];
    }

    return [webResult(
        "bang:passthrough:" + body,
        "Search “" + raw + "”",
        "Pass this bang through to the configured search engine",
        urlFromTemplate(config.searchUrl, raw)
    )];
}

function searchResult(query, launcherConfig) {
    var raw = String(query || "").trim();
    var terms = raw.substring(1).trim();
    if (terms === "")
        return [];
    return [webResult(
        "search:" + terms,
        "Search the web for “" + terms + "”",
        "Open in the configured search engine",
        urlFromTemplate(launcherConfig.searchUrl, terms)
    )];
}
