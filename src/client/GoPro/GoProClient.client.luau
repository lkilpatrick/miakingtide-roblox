--[[
	GoProClient.client.luau
	Client-side GoPro tool logic.
	When equipped: shows a crosshair UI.
	On click: raycasts forward, checks for "CreatureCollectible" tag within 40 studs.
	If hit: plays shutter sound, fires RequestCapture to server.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Events = require(Shared:WaitForChild("Events"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local MAX_CAPTURE_DISTANCE = 40
local COOLDOWN_TIME = 1.5

-- State
local isEquipped = false
local isCooldown = false
local crosshairGui: ScreenGui? = nil

-- Shutter sound setup
local shutterSound: Sound
do
	shutterSound = Instance.new("Sound")
	shutterSound.Name = "ShutterClick"
	shutterSound.SoundId = "rbxassetid://160715357" -- camera shutter sound
	shutterSound.Volume = 0.8
	shutterSound.Parent = SoundService
end

-- Flash effect
local function playFlashEffect()
	local flash = Instance.new("Frame")
	flash.Name = "CameraFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.Position = UDim2.fromScale(0, 0)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0
	flash.BorderSizePixel = 0
	flash.ZIndex = 100
	flash.Parent = crosshairGui

	-- Fade out
	task.spawn(function()
		for i = 0, 10 do
			flash.BackgroundTransparency = i / 10
			task.wait(0.03)
		end
		flash:Destroy()
	end)
end

-- Create crosshair UI
local function createCrosshairUI()
	if crosshairGui then return end

	crosshairGui = Instance.new("ScreenGui")
	crosshairGui.Name = "GoProCrosshair"
	crosshairGui.ResetOnSpawn = false
	crosshairGui.IgnoreGuiInset = true
	crosshairGui.DisplayOrder = 10

	-- Crosshair container
	local container = Instance.new("Frame")
	container.Name = "Crosshair"
	container.Size = UDim2.fromOffset(60, 60)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = crosshairGui

	-- Crosshair lines
	local lineData = {
		{ size = UDim2.fromOffset(2, 20), pos = UDim2.fromScale(0.5, 0), anchor = Vector2.new(0.5, 0) },    -- top
		{ size = UDim2.fromOffset(2, 20), pos = UDim2.fromScale(0.5, 1), anchor = Vector2.new(0.5, 1) },    -- bottom
		{ size = UDim2.fromOffset(20, 2), pos = UDim2.fromScale(0, 0.5), anchor = Vector2.new(0, 0.5) },    -- left
		{ size = UDim2.fromOffset(20, 2), pos = UDim2.fromScale(1, 0.5), anchor = Vector2.new(1, 0.5) },    -- right
	}

	for _, data in lineData do
		local line = Instance.new("Frame")
		line.Size = data.size
		line.Position = data.pos
		line.AnchorPoint = data.anchor
		line.BackgroundColor3 = Color3.new(1, 1, 1)
		line.BorderSizePixel = 0
		line.Parent = container
	end

	-- Center dot
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(4, 4)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BackgroundColor3 = Color3.new(1, 0.3, 0.3)
	dot.BorderSizePixel = 0
	dot.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = dot

	-- "GoPro" label
	local label = Instance.new("TextLabel")
	label.Name = "GoProLabel"
	label.Size = UDim2.fromOffset(120, 24)
	label.Position = UDim2.new(0.5, 0, 0.5, 40)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.BackgroundTransparency = 1
	label.Text = "GoPro Ready"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.Parent = crosshairGui

	crosshairGui.Parent = player.PlayerGui
end

local function destroyCrosshairUI()
	if crosshairGui then
		crosshairGui:Destroy()
		crosshairGui = nil
	end
end

-- Find the creature ID from a hit instance by walking up the hierarchy
local function getCreatureIdFromHit(hitInstance: Instance): string?
	local current: Instance? = hitInstance
	while current and current ~= workspace do
		if CollectionService:HasTag(current, "CreatureCollectible") then
			-- The creature ID is stored as an attribute on the tagged model
			local creatureId = current:GetAttribute("CreatureId")
			if creatureId then
				return creatureId
			end
			-- Fallback: use the model name (lowercase)
			return string.lower(current.Name)
		end
		current = current.Parent
	end
	return nil
end

-- Perform the capture raycast
local function attemptCapture()
	if isCooldown then return end
	if not isEquipped then return end

	isCooldown = true

	local ray = camera:ScreenPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character }

	local result = workspace:Raycast(ray.Origin, ray.Direction * MAX_CAPTURE_DISTANCE, raycastParams)

	if result and result.Instance then
		local creatureId = getCreatureIdFromHit(result.Instance)
		if creatureId then
			-- Valid creature hit!
			shutterSound:Play()
			playFlashEffect()

			local requestCapture = Events.WaitFor(Events.Names.RequestCapture)
			requestCapture:FireServer(creatureId, result.Instance)

			print("[GoPro] Capture attempt sent for:", creatureId)
		else
			print("[GoPro] No creature detected in crosshair.")
		end
	else
		print("[GoPro] Nothing in range.")
	end

	task.delay(COOLDOWN_TIME, function()
		isCooldown = false
	end)
end

-- Listen for capture results from server
task.spawn(function()
	local captureResult = Events.WaitFor(Events.Names.CaptureResult)
	captureResult.OnClientEvent:Connect(function(success: boolean, creatureId: string, message: string)
		if success then
			print("[GoPro] Capture successful:", creatureId)
		else
			print("[GoPro] Capture failed:", message)
		end
	end)
end)

-- Equipment handling via Tool (if using a Tool object)
-- For now, we use a keybind toggle: press E to equip/unequip
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		isEquipped = not isEquipped
		if isEquipped then
			createCrosshairUI()
			print("[GoPro] Equipped!")
		else
			destroyCrosshairUI()
			print("[GoPro] Unequipped!")
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 and isEquipped then
		attemptCapture()
	end
end)

-- Also support touch/tap for mobile
UserInputService.TouchTap:Connect(function(_positions: { Vector2 }, gameProcessed: boolean)
	if gameProcessed then return end
	if isEquipped then
		attemptCapture()
	end
end)

print("[GoProClient] Loaded. Press E to equip/unequip the GoPro.")
