--!strict
-- GardenService.luau: Server-authoritative garden restoration task validation

local GardenTaskRegistry
local PlayerProfileService
if typeof(script) == "Instance" and script.Parent and typeof(game) == "Instance" then
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local BloomtrailShared = ReplicatedStorage:WaitForChild("BloomtrailShared")
    GardenTaskRegistry = require(BloomtrailShared:WaitForChild("Config"):WaitForChild("GardenTaskRegistry"))
    PlayerProfileService = require(script.Parent.PlayerProfileService)
else
    GardenTaskRegistry = require("../../shared/Config/GardenTaskRegistry")
    PlayerProfileService = require("./PlayerProfileService")
end

local GardenService = {}

function GardenService.completeTask(playerOrId: any, taskId: string)
    local taskDef = GardenTaskRegistry.getTask(taskId)
    if not taskDef then
        return {
            success = false,
            message = "Task does not exist in registry",
        }
    end

    local success, updatedProfile, errMessage = PlayerProfileService.completeGardenTask(
        playerOrId,
        taskId,
        taskDef.starCost,
        taskDef.targetStage
    )

    return {
        success = success,
        updatedProfile = updatedProfile,
        message = errMessage,
    }
end

return GardenService
