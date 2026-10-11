--!strict
-- LevelTypes: Level schema and objective types for Project Bloomtrail

local BoardTypes
if typeof(script) == "Instance" and script.Parent then
    BoardTypes = require(script.Parent.BoardTypes)
else
    BoardTypes = require("./BoardTypes")
end

export type TileColor = BoardTypes.TileColor
export type BlockerType = BoardTypes.BlockerType
export type SpecialPieceType = BoardTypes.SpecialPieceType
export type Coord = BoardTypes.Coord

export type ObjectiveDefinition = 
    | { kind: "collect_color", color: TileColor, targetCount: number }
    | { kind: "clear_blocker", blocker: BlockerType, targetCount: number }
    | { kind: "reach_score", targetScore: number }

export type PreplacedSlot = {
    x: number,
    y: number,
    slotType: "color" | "blocker" | "empty",
    color: TileColor?,
    blocker: BlockerType?,
    special: SpecialPieceType?,
}

export type ObjectiveWeightConfig = {
    baseWeight: number?,
    objectiveBoost: number?,
    deficitScale: number?,
    targetObjectiveRatio: number?,
}

export type LevelDefinition = {
    id: number,
    title: string,
    width: number,
    height: number,
    moveLimit: number,
    allowedColors: { TileColor },
    objectives: { ObjectiveDefinition },
    starThresholds: { number },
    preplacedGrid: { PreplacedSlot }?,
    coinReward: number,
    starReward: number,
    objectiveWeightConfig: ObjectiveWeightConfig?,
}

return {}
