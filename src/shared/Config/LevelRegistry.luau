--!strict
-- LevelRegistry: Registered data-driven levels for Project Bloomtrail

local LevelTypes
if typeof(script) == "Instance" and script.Parent then
    LevelTypes = require(script.Parent.Parent.Types.LevelTypes)
else
    LevelTypes = require("../Types/LevelTypes")
end
type LevelDefinition = LevelTypes.LevelDefinition

local Levels: { [number]: LevelDefinition } = {
    [1] = {
        id = 1,
        title = "First Blooms",
        width = 8,
        height = 8,
        moveLimit = 25,
        allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop" },
        objectives = {
            { kind = "collect_color", color = "Leaf", targetCount = 8 },
            { kind = "collect_color", color = "Berry", targetCount = 6 },
        },
        starThresholds = { 1000, 2000, 3000 },
        coinReward = 50,
        starReward = 1,
        objectiveWeightConfig = {
            baseWeight = 1.0,
            objectiveBoost = 0.5,
            deficitScale = 0.5,
            targetObjectiveRatio = 0.60, -- 60% total across unfinished objectives (30% Leaf, 30% Berry baseline)
        },
    },
    [2] = {
        id = 2,
        title = "Tangled Vines",
        width = 8,
        height = 8,
        moveLimit = 22,
        allowedColors = { "Berry", "Leaf", "Blossom", "Dewdrop", "Plum" },
        objectives = {
            { kind = "clear_blocker", blocker = "Ivy", targetCount = 8 },
            { kind = "collect_color", color = "Dewdrop", targetCount = 12 },
        },
        starThresholds = { 1200, 2400, 3600 },
        preplacedGrid = {
            { x = 1, y = 7, slotType = "blocker", blocker = "Ivy", color = "Berry" },
            { x = 2, y = 7, slotType = "blocker", blocker = "Ivy", color = "Leaf" },
            { x = 7, y = 7, slotType = "blocker", blocker = "Ivy", color = "Blossom" },
            { x = 8, y = 7, slotType = "blocker", blocker = "Ivy", color = "Dewdrop" },
            { x = 3, y = 8, slotType = "blocker", blocker = "Ivy", color = "Plum" },
            { x = 4, y = 8, slotType = "blocker", blocker = "Ivy", color = "Berry" },
            { x = 5, y = 8, slotType = "blocker", blocker = "Ivy", color = "Leaf" },
            { x = 6, y = 8, slotType = "blocker", blocker = "Ivy", color = "Dewdrop" },
        },
        coinReward = 50,
        starReward = 1,
    },
}

local LevelRegistry = {}

function LevelRegistry.getLevel(id: number): LevelDefinition?
    return Levels[id]
end

return LevelRegistry
