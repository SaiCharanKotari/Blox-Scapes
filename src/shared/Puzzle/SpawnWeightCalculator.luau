--!strict
-- SpawnWeightCalculator.luau: Objective-aware weighted randomness engine for match-3 tile generation
-- Dynamically adapts color spawn probabilities to remaining objective deficits and completion states
-- Pure Luau with zero external or engine dependencies

local BoardTypes
local LevelTypes
if typeof(script) == "Instance" and script.Parent then
    BoardTypes = require(script.Parent.Parent.Types.BoardTypes)
    LevelTypes = require(script.Parent.Parent.Types.LevelTypes)
else
    BoardTypes = require("../Types/BoardTypes")
    LevelTypes = require("../Types/LevelTypes")
end

type TileColor = BoardTypes.TileColor
type ObjectiveState = BoardTypes.ObjectiveState
type ObjectiveWeightConfig = LevelTypes.ObjectiveWeightConfig

local SpawnWeightCalculator = {}

-- Calculates normalized spawn weights for all allowed colors based on current objective progress
function SpawnWeightCalculator.calculateWeights(
    allowedColors: { TileColor },
    objectives: { ObjectiveState },
    config: ObjectiveWeightConfig?
): { [TileColor]: number }
    local totalColors = #allowedColors
    local weights: { [TileColor]: number } = {}

    if totalColors == 0 then
        return weights
    end

    -- 1. Identify active (unfinished) collect_color objectives for allowed colors
    local unfinishedObjectives: { [TileColor]: { deficit: number, target: number } } = {}
    local totalDeficit = 0
    local unfinishedCount = 0

    for _, obj in ipairs(objectives) do
        if not obj.completed and obj.kind == "collect_color" and obj.color then
            -- Verify objective color is in allowedColors
            if table.find(allowedColors, obj.color) then
                local deficit = math.max(0, obj.targetCount - obj.currentCount)
                if deficit > 0 then
                    unfinishedObjectives[obj.color] = {
                        deficit = deficit,
                        target = obj.targetCount,
                    }
                    totalDeficit += deficit
                    unfinishedCount += 1
                end
            end
        end
    end

    -- 2. If no unfinished color objectives, distribute uniformly across all allowed colors
    if unfinishedCount == 0 or totalDeficit == 0 then
        local uniformWeight = 1.0 / totalColors
        for _, color in ipairs(allowedColors) do
            weights[color] = uniformWeight
        end
        return weights
    end

    -- 3. Determine target probability pool for unfinished objectives
    local cfg = config or {}
    local deficitScale = cfg.deficitScale or 0.5
    local baseRatio = cfg.targetObjectiveRatio or 0.60

    -- Scale target objective ratio smoothly based on how many objectives remain unfinished
    local targetObjectiveRatio: number
    if unfinishedCount >= 2 then
        targetObjectiveRatio = math.clamp(baseRatio, 0.40, 0.85)
    else
        -- If only 1 objective remains unfinished, scale pool down so other colors aren't starved
        targetObjectiveRatio = math.clamp(baseRatio * 0.65, 0.30, 0.50)
    end

    -- If all allowed colors are objectives, pool is 1.0
    if unfinishedCount == totalColors then
        targetObjectiveRatio = 1.0
    end

    local nonObjectiveColorsCount = totalColors - unfinishedCount
    local targetNonObjectiveRatio = math.max(0, 1.0 - targetObjectiveRatio)
    local nonObjectiveWeightPerColor = if nonObjectiveColorsCount > 0
        then targetNonObjectiveRatio / nonObjectiveColorsCount
        else 0

    -- 4. Assign weights to unfinished objective colors with deficit scaling
    for _, color in ipairs(allowedColors) do
        local objData = unfinishedObjectives[color]
        if objData then
            local baseShare = 1.0 / unfinishedCount
            local deficitShare = if totalDeficit > 0 then (objData.deficit / totalDeficit) else baseShare
            -- Blended weight: combination of equal baseline share and deficit proportional share
            local normalizedObjectiveShare = (baseShare * (1.0 - deficitScale)) + (deficitShare * deficitScale)
            weights[color] = targetObjectiveRatio * normalizedObjectiveShare
        else
            -- Ordinary or completed objective colors receive the non-objective baseline weight
            weights[color] = nonObjectiveWeightPerColor
        end
    end

    -- 5. Normalize weights strictly so sum = 1.0
    local sum = 0
    for _, color in ipairs(allowedColors) do
        sum += (weights[color] or 0)
    end

    if sum > 0 then
        for _, color in ipairs(allowedColors) do
            weights[color] = (weights[color] or 0) / sum
        end
    else
        local uniform = 1.0 / totalColors
        for _, color in ipairs(allowedColors) do
            weights[color] = uniform
        end
    end

    return weights
end

-- Selects a color from validColors using pre-calculated weights and an injectable PRNG
function SpawnWeightCalculator.pickWeightedColor(
    validColors: { TileColor },
    weights: { [TileColor]: number }?,
    rng: any
): TileColor
    local numValid = #validColors
    if numValid == 0 then
        error("pickWeightedColor called with empty validColors list")
    end
    if numValid == 1 or not weights then
        local idx = if rng and rng.NextInteger then rng:NextInteger(1, numValid) else math.random(1, numValid)
        return validColors[idx]
    end

    -- Calculate total weight among the valid subset
    local totalWeight = 0
    for _, color in ipairs(validColors) do
        totalWeight += (weights[color] or 0)
    end

    if totalWeight <= 0.00001 then
        local idx = if rng and rng.NextInteger then rng:NextInteger(1, numValid) else math.random(1, numValid)
        return validColors[idx]
    end

    -- Deterministic weighted sample using NextNumber()
    local roll: number
    if rng and rng.NextNumber then
        roll = rng:NextNumber() * totalWeight
    else
        roll = math.random() * totalWeight
    end

    local accumulated = 0
    for i = 1, numValid do
        local color = validColors[i]
        accumulated += (weights[color] or 0)
        if roll <= accumulated or i == numValid then
            return color
        end
    end

    return validColors[numValid]
end

return SpawnWeightCalculator
