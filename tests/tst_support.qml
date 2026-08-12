import QtQuick
import QtTest
import "../services/SupportIssues.js" as SupportIssues

TestCase {
    name: "FeatureSupport"

    function test_noIssuesBeforeReady() {
        compare(SupportIssues.buildIssues(
            false, true, false, "missing", [], false, ["locker"], false
        ).length, 0);
    }

    function test_explicitIntentIssues() {
        var issues = SupportIssues.buildIssues(
            true,
            true,
            false,
            "intel_backlight",
            ["amdgpu_bl1"],
            false,
            ["custom-locker"],
            false
        );
        compare(issues.length, 3);
        compare(issues[0].id, "weather-curl");
        compare(issues[1].id, "backlight-device");
        compare(issues[2].id, "power-locker");
    }

    function test_unconfiguredBacklightIsSilent() {
        var issues = SupportIssues.buildIssues(
            true, false, false, "", [], false, [], true
        );
        compare(issues.length, 0);
    }
}
