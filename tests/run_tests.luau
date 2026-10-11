--!strict
-- Entry point for Lune test runner
local Tests = require("./BoardLogic.spec")
local summary = Tests.runAll()

if summary.failed > 0 then
    error(string.format("Test suite failed with %d error(s)", summary.failed))
end

print("All Bloomtrail puzzle engine tests passed successfully.")
