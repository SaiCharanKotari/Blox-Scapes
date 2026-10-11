--!strict
-- BoardTypes: Core type definitions for Project Bloomtrail's match-3 puzzle engine

export type TileColor = "Berry" | "Leaf" | "Blossom" | "Dewdrop" | "Plum"
export type BlockerType = "Ivy" | "Stone"
export type SpecialPieceType = "BlossomBomb" | "LineClearHorizontal" | "LineClearVertical"

export type Coord = {
    x: number,
    y: number,
}

export type Tile = {
    id: string,
    color: TileColor?,
    blocker: BlockerType?,
    special: SpecialPieceType?,
    isMatched: boolean?,
}

-- Internal grid representation: [y][x], 1-indexed (row-major)
export type Grid = { [number]: { [number]: Tile? } }

export type BoardDimensions = {
    width: number,
    height: number,
}

export type MatchGroup = {
    color: TileColor,
    coords: { Coord },
    isSpecial: boolean,
    specialType: SpecialPieceType?,
    spawnCoord: Coord?,
}

export type CascadeStep = {
    clearedTiles: { Coord },
    spawnedSpecials: { { coord: Coord, specialType: SpecialPieceType } },
    shiftMoves: { { from: Coord, to: Coord, tile: Tile } },
    refilledTiles: { { coord: Coord, tile: Tile } },
}

export type SwapResult = {
    valid: boolean,
    matchGroups: { MatchGroup }?,
    cascadeSteps: { CascadeStep }?,
    movesRemaining: number,
    reshuffled: boolean?,
}

export type MoveEvaluation = {
    from: Coord,
    to: Coord,
    potentialMatches: number,
}

export type GameStatus = "InProgress" | "Won" | "Lost"

export type ObjectiveState = {
    kind: string,
    color: TileColor?,
    blocker: BlockerType?,
    targetCount: number,
    currentCount: number,
    completed: boolean,
}

return {}
