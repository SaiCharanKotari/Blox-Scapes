--!strict
-- App.luau: Root React-Lua component for Project Bloomtrail client UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local PuzzleScreen = require(script.Parent.Components.Puzzle.PuzzleScreen)

local function App()
    return React.createElement(PuzzleScreen, {
        levelId = 1,
    })
end

return App
