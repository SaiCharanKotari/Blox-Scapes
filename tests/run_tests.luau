--!strict
-- Entry point for Lune test runner (runs BoardLogic and Progression test suites)

local BoardTests = require("./BoardLogic.spec")
local ProgressionTests = require("./Progression.spec")
local WeightedTests = require("./WeightedRandomness.spec")

local boardSummary = BoardTests.runAll()
local progSummary = ProgressionTests.runAll()
local weightedSummary = WeightedTests.runAll()

local totalFailed = boardSummary.failed + progSummary.failed + weightedSummary.failed
local totalPassed = boardSummary.passed + progSummary.passed + weightedSummary.passed
local totalTests = boardSummary.total + progSummary.total + weightedSummary.total

if totalFailed > 0 then
    error(string.format("Test suite failed with %d error(s)", totalFailed))
end

print(string.format("All Bloomtrail tests passed successfully (%d/%d tests green).", totalPassed, totalTests))
