import QtQuick
import QtTest
import "../services/CalculatorProvider.js" as Calculator

TestCase {
    name: "CalculatorProvider"

    function test_ignoresPlainApplicationQueries() {
        var result = Calculator.evaluate("firefox");
        verify(!result.candidate);
    }

    function test_operatorPrecedenceAndFunctions() {
        compare(Calculator.evaluate("2 * (8 + 4)").result, "24");
        compare(Calculator.evaluate("= sqrt(144)").result, "12");
        compare(Calculator.evaluate("max(2, 5, 3) ^ 2").result, "25");
    }

    function test_constantsAndFormatting() {
        compare(Calculator.evaluate("round(pi * 100) / 100").result, "3.14");
        compare(Calculator.evaluate("0.1 + 0.2").result, "0.3");
    }

    function test_reportsInvalidExpressions() {
        var division = Calculator.evaluate("1 / 0");
        verify(division.candidate);
        verify(!division.ok);
        verify(division.error.indexOf("Division by zero") >= 0);

        var incomplete = Calculator.evaluate("=");
        verify(incomplete.candidate);
        verify(!incomplete.ok);
        verify(incomplete.error.indexOf("after '='") >= 0);
    }
}
