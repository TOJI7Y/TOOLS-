local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local tool = script.Parent
local hitRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GearHitEvent")

local swingAnimationId = "rbxassetid://95069165092191"
local idleAnimationId = "rbxassetid://113018339588993"

local mouse
local humanoid
local animator
local swingAnimation
local idleAnimation
local swingTrack
local idleTrack
local lastSwing = 0
local equipped = false

local function stopTrack(track, fadeTime)
	if track then
		pcall(function()
			track:Stop(fadeTime or 0)
		end)
	end
end

local function clearTracks()
	stopTrack(swingTrack, 0.05)
	stopTrack(idleTrack, 0.1)

	if swingTrack then
		swingTrack:Destroy()
	end
	if idleTrack then
		idleTrack:Destroy()
	end
	if swingAnimation then
		swingAnimation:Destroy()
	end
	if idleAnimation then
		idleAnimation:Destroy()
	end

	swingTrack = nil
	idleTrack = nil
	swingAnimation = nil
	idleAnimation = nil
	animator = nil
	humanoid = nil
end

local function setupTracks()
	local character = player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	swingAnimation = Instance.new("Animation")
	swingAnimation.AnimationId = swingAnimationId
	swingTrack = animator:LoadAnimation(swingAnimation)
	swingTrack.Priority = Enum.AnimationPriority.Action
	swingTrack.Looped = false

	idleAnimation = Instance.new("Animation")
	idleAnimation.AnimationId = idleAnimationId
	idleTrack = animator:LoadAnimation(idleAnimation)
	idleTrack.Priority = Enum.AnimationPriority.Action
	idleTrack.Looped = true

	return true
end

local function playIdle()
	if not equipped or not idleTrack then
		return
	end

	if swingTrack and swingTrack.IsPlaying then
		swingTrack:Stop(0.05)
	end

	idleTrack:Play(0.1)
end

local function playSwing()
	if not swingTrack then
		return
	end

	if idleTrack and idleTrack.IsPlaying then
		idleTrack:Stop(0.05)
	end

	swingTrack:Stop(0)
	swingTrack.TimePosition = 0
	swingTrack:Play(0.05)

	task.delay(math.max(swingTrack.Length, 0.1) + 0.05, function()
		if equipped and swingTrack and not swingTrack.IsPlaying then
			playIdle()
		end
	end)
end

local function getMouseTarget()
	local target = mouse and mouse.Target
	local model = target and target:FindFirstAncestorOfClass("Model")
	local targetPlayer = model and Players:GetPlayerFromCharacter(model)
	if targetPlayer ~= player then
		return targetPlayer
	end
	return nil
end

local function resolveTargetPlayer()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local bestPlayer = getMouseTarget()

	if not root then
		return bestPlayer
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { character }

	local hitboxCFrame = root.CFrame * CFrame.new(0, 0, -4)
	local bestDistance = bestPlayer
		and (bestPlayer.Character:GetPivot().Position - root.Position).Magnitude
		or math.huge

	for _, part in ipairs(Workspace:GetPartBoundsInBox(hitboxCFrame, Vector3.new(5, 5, 5), overlapParams)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local targetPlayer = model and Players:GetPlayerFromCharacter(model)
		local targetRoot = model and model:FindFirstChild("HumanoidRootPart")

		if targetPlayer and targetPlayer ~= player and targetRoot then
			local distance = (targetRoot.Position - root.Position).Magnitude
			if distance < bestDistance then
				bestPlayer = targetPlayer
				bestDistance = distance
			end
		end
	end

	return bestPlayer
end

tool.Equipped:Connect(function(equippedMouse)
	mouse = equippedMouse
	equipped = setupTracks()

	if equipped then
		playIdle()
	end
end)

tool.Unequipped:Connect(function()
	mouse = nil
	equipped = false
	clearTracks()
end)

player.CharacterRemoving:Connect(function()
	mouse = nil
	equipped = false
	clearTracks()
end)

tool.Activated:Connect(function()
	local cooldown = 0.8
	if os.clock() - lastSwing < cooldown then
		return
	end

	lastSwing = os.clock()

	local targetPlayer = resolveTargetPlayer()
	if targetPlayer then
		hitRemote:FireServer(targetPlayer)
	end

	playSwing()
end)
