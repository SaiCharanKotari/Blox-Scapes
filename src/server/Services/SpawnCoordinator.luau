--!strict
-- SpawnCoordinator.luau: Server-authoritative 12-player spawn pad assignment and collision prevention
-- Distributes joining players and respawns across 12 designated safe arrival positions

local Players: Players? = nil
local Workspace: Workspace? = nil

if typeof(game) == "Instance" then
    Players = game:GetService("Players")
    Workspace = game:GetService("Workspace")
end

local SpawnCoordinator = {}

local MAX_SPAWNS = 12
local playerSpawnAssignments: { [any]: number } = {}
local spawnLocations: { [number]: any } = {}

-- Cache the 12 arrival spawn pads from Workspace
function SpawnCoordinator.init()
    if not Workspace or not Players then return end

    local arrivalPlaza = Workspace:FindFirstChild("ArrivalPlaza", true)
    if arrivalPlaza then
        for i = 1, MAX_SPAWNS do
            local pad = arrivalPlaza:FindFirstChild("SpawnPad_" .. i)
            if pad and pad:IsA("SpawnLocation") then
                spawnLocations[i] = pad
            end
        end
    end

    Players.PlayerAdded:Connect(SpawnCoordinator.onPlayerAdded)
    Players.PlayerRemoving:Connect(SpawnCoordinator.onPlayerRemoving)

    -- Handle existing players (e.g. in test runner or Studio quick play)
    for _, player in ipairs(Players:GetPlayers()) do
        SpawnCoordinator.onPlayerAdded(player)
    end
end

-- Allocates the next free spawn index (1..12), with safe round-robin fallback
function SpawnCoordinator.allocateSpawnIndex(player: any): number
    local occupied = {}
    for _, idx in pairs(playerSpawnAssignments) do
        occupied[idx] = true
    end

    for i = 1, MAX_SPAWNS do
        if not occupied[i] then
            return i
        end
    end

    -- Server at or above capacity fallback: round-robin
    local activeCount = 0
    for _ in pairs(playerSpawnAssignments) do
        activeCount += 1
    end
    return (activeCount % MAX_SPAWNS) + 1
end

function SpawnCoordinator.onPlayerAdded(player: any)
    if not playerSpawnAssignments[player] then
        playerSpawnAssignments[player] = SpawnCoordinator.allocateSpawnIndex(player)
    end

    if player.CharacterAdded then
        player.CharacterAdded:Connect(function(character)
            task.defer(function()
                local spawnIdx = playerSpawnAssignments[player] or 1
                local pad = spawnLocations[spawnIdx]
                local root = character:WaitForChild("HumanoidRootPart", 5)
                
                if root and pad then
                    -- Place character safely on top of pad, facing down the estate avenue toward the manor (Z = 25)
                    local targetLook = Vector3.new(0, pad.Position.Y, 25)
                    local targetCFrame = CFrame.new(pad.Position + Vector3.new(0, 3.5, 0), targetLook)
                    root.CFrame = targetCFrame
                end
            end)
        end)
    end
end

function SpawnCoordinator.onPlayerRemoving(player: any)
    playerSpawnAssignments[player] = nil
end

function SpawnCoordinator.getAssignedSpawn(player: any): number?
    return playerSpawnAssignments[player]
end

function SpawnCoordinator.getSpawnCount(): number
    local count = 0
    for _ in pairs(spawnLocations) do
        count += 1
    end
    return count
end

function SpawnCoordinator._clearAllAssignments()
    table.clear(playerSpawnAssignments)
end

return SpawnCoordinator
