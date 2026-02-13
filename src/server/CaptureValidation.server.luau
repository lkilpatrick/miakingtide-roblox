--[[
	CaptureValidation.server.luau
	Server-side validation for creature capture attempts.
	Validates distance, creature validity, and duplicate captures.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CreatureDefinitions = require(Shared:WaitForChild("CreatureDefinitions"))
local Events = require(Shared:WaitForChild("Events"))

local MAX_CAPTURE_DISTANCE = 50 -- slightly more generous than client to account for latency
local RATE_LIMIT_SECONDS = 1

-- Rate limiting per player
local lastCaptureTime: { [number]: number } = {}

-- Get the PlayerDataHandler module via the registry
local function getPlayerDataHandler()
	local registry = ServerStorage:WaitForChild("ModuleRegistry", 10)
	if not registry then
		warn("[CaptureValidation] ModuleRegistry not found!")
		return nil
	end
	local bindable = registry:WaitForChild("GetPlayerDataHandler", 10)
	if not bindable then
		warn("[CaptureValidation] GetPlayerDataHandler bindable not found!")
		return nil
	end
	return bindable:Invoke()
end

-- Validate that the target instance is a tagged creature
local function validateCreatureTarget(target: Instance?): (boolean, string?)
	if not target then
		return false, "No target provided"
	end

	-- Walk up hierarchy to find the tagged model
	local current: Instance? = target
	while current and current ~= workspace do
		if CollectionService:HasTag(current, "CreatureCollectible") then
			local creatureId = current:GetAttribute("CreatureId")
			if not creatureId then
				creatureId = string.lower(current.Name)
			end
			if CreatureDefinitions.IsValid(creatureId) then
				return true, creatureId
			else
				return false, "Unknown creature: " .. tostring(creatureId)
			end
		end
		current = current.Parent
	end

	return false, "Target is not a creature"
end

-- Validate distance between player and target
local function validateDistance(player: Player, target: Instance): boolean
	local character = player.Character
	if not character then return false end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end

	-- Find the position of the target (use PrimaryPart if Model, or Position if BasePart)
	local targetPos: Vector3
	if target:IsA("Model") then
		local primary = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
		if not primary then return false end
		targetPos = primary.Position
	elseif target:IsA("BasePart") then
		targetPos = target.Position
	else
		return false
	end

	local distance = (humanoidRootPart.Position - targetPos).Magnitude
	return distance <= MAX_CAPTURE_DISTANCE
end

-- Listen for capture requests
task.spawn(function()
	local requestCapture = Events.WaitFor(Events.Names.RequestCapture)
	local captureResult = Events.WaitFor(Events.Names.CaptureResult)

	requestCapture.OnServerEvent:Connect(function(player: Player, creatureId: string, targetInstance: Instance?)
		-- Rate limiting
		local now = os.clock()
		if lastCaptureTime[player.UserId] and (now - lastCaptureTime[player.UserId]) < RATE_LIMIT_SECONDS then
			captureResult:FireClient(player, false, creatureId, "Too fast! Wait a moment.")
			return
		end
		lastCaptureTime[player.UserId] = now

		-- Validate creature target
		local isValidCreature, resolvedId = validateCreatureTarget(targetInstance)
		if not isValidCreature then
			captureResult:FireClient(player, false, creatureId, resolvedId or "Invalid target")
			return
		end

		-- Validate distance
		if targetInstance and not validateDistance(player, targetInstance) then
			captureResult:FireClient(player, false, resolvedId, "Too far away!")
			return
		end

		-- Attempt unlock via PlayerDataHandler
		local handler = getPlayerDataHandler()
		if not handler then
			captureResult:FireClient(player, false, resolvedId, "Server error")
			return
		end

		local data = handler.GetData(player)
		if not data then
			captureResult:FireClient(player, false, resolvedId, "Data not loaded")
			return
		end

		-- Check if already unlocked
		if data.UnlockedCreatures[resolvedId] then
			captureResult:FireClient(player, false, resolvedId, "Already captured!")
			return
		end

		-- Unlock!
		local success = handler.UnlockCreature(player, resolvedId)
		if success then
			captureResult:FireClient(player, true, resolvedId, "Captured!")
			print("[CaptureValidation]", player.Name, "captured", resolvedId)
		else
			captureResult:FireClient(player, false, resolvedId, "Capture failed")
		end
	end)
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player: Player)
	lastCaptureTime[player.UserId] = nil
end)

print("[CaptureValidation] Server validation loaded.")
