--!strict
-- GardenTaskRegistry.luau: Registered garden restoration tasks for Project Bloomtrail

export type GardenTask = {
    id: string,
    title: string,
    area: string,
    starCost: number,
    targetStage: number,
    description: string,
}

local Tasks: { [string]: GardenTask } = {
    ["task_restore_fountain"] = {
        id = "task_restore_fountain",
        title = "Restore Fountain Basin",
        area = "CourtyardFountain",
        starCost = 1,
        targetStage = 1,
        description = "Clean away cracked stone and overgrowth to restore the courtyard fountain.",
    },
    ["task_restore_pipes"] = {
        id = "task_restore_pipes",
        title = "Restore Water Plumbing",
        area = "CourtyardFountain",
        starCost = 2,
        targetStage = 2,
        description = "Install polished brass water fixtures and activate the central fountain spouts.",
    },
    ["task_plant_flowerbeds"] = {
        id = "task_plant_flowerbeds",
        title = "Plant Courtyard Flowerbeds",
        area = "CourtyardFountain",
        starCost = 2,
        targetStage = 3,
        description = "Surround the fountain with radiant pink hydrangeas and fragrant roses.",
    },
}

local GardenTaskRegistry = {}

function GardenTaskRegistry.getTask(id: string): GardenTask?
    return Tasks[id]
end

function GardenTaskRegistry.getAllTasks(): { GardenTask }
    local list = {}
    table.insert(list, Tasks["task_restore_fountain"])
    table.insert(list, Tasks["task_restore_pipes"])
    table.insert(list, Tasks["task_plant_flowerbeds"])
    return list
end

return GardenTaskRegistry
