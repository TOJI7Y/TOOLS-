local ServerStorage = game:GetService("ServerStorage")

local PickaxeService = {}

local PICKAXE_FOLDER_NAME = "Pickaxes"
local DEFAULT_PICKAXE_NAME = "WoodPickaxe"

local function getPickaxeFolder()
	local toolsFolder = ServerStorage:FindFirstChild("Tools")
	return toolsFolder and toolsFolder:FindFirstChild(PICKAXE_FOLDER_NAME)
end

local function getTemplate(toolName)
	local folder = getPickaxeFolder()
	local template = folder and folder:FindFirstChild(toolName)
	if template and template:IsA("Tool") then
		return template
	end
	return nil
end

local function removeExistingPickaxes(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	for _, container in ipairs({ backpack, character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute("IsRaidPickaxe") == true then
					child:Destroy()
				end
			end
		end
	end
end

function PickaxeService.GetTemplate(toolName)
	return getTemplate(toolName or DEFAULT_PICKAXE_NAME)
end

function PickaxeService.Grant(player, toolName)
	local template = getTemplate(toolName or DEFAULT_PICKAXE_NAME)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not template or not backpack then
		return nil
	end

	removeExistingPickaxes(player)
	local tool = template:Clone()
	tool.Parent = backpack
	return tool
end

function PickaxeService.GrantDefault(player)
	return PickaxeService.Grant(player, DEFAULT_PICKAXE_NAME)
end

return PickaxeService
