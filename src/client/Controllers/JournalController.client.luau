--[[
	JournalController.client.luau
	Client-side Field Journal UI.
	- Listens for UpdateJournal remote to receive unlock data.
	- Builds UI dynamically from CreatureDefinitions.
	- Shows locked (silhouette + hint) vs unlocked (name + fact + timestamp) states.
	- Popup notification on new captures.
	Toggle journal with J key.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CreatureDefinitions = require(Shared:WaitForChild("CreatureDefinitions"))
local Events = require(Shared:WaitForChild("Events"))

local player = Players.LocalPlayer

-- State
local unlockedCreatures: { [string]: number } = {} -- creatureId -> timestamp
local journalOpen = false
local journalGui: ScreenGui? = nil
local creatureCards: { [string]: Frame } = {}

-- Color palette
local COLORS = {
	Background = Color3.fromRGB(20, 30, 50),
	CardLocked = Color3.fromRGB(40, 50, 70),
	CardUnlocked = Color3.fromRGB(30, 80, 60),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 190, 200),
	TextHint = Color3.fromRGB(255, 200, 100),
	Accent = Color3.fromRGB(0, 170, 200),
	Silhouette = Color3.fromRGB(20, 25, 40),
}

-- Creature display colors (for the icon placeholder)
local CREATURE_COLORS: { [string]: Color3 } = {
	marlow = Color3.fromRGB(139, 90, 43),
	luna = Color3.fromRGB(101, 67, 33),
	seahorse = Color3.fromRGB(219, 130, 163),
	redoctopus = Color3.fromRGB(210, 70, 50),
	treefish = Color3.fromRGB(200, 180, 50),
}

-- Creature emoji/icons (fallback text icons)
local CREATURE_ICONS: { [string]: string } = {
	marlow = "🦦",
	luna = "🦭",
	seahorse = "🐴",
	redoctopus = "🐙",
	treefish = "🐟",
}

-- Uploaded sprite image asset IDs (used instead of emoji when available)
local CREATURE_IMAGES: { [string]: string } = {
	seahorse = "rbxassetid://73359569792579",
	redoctopus = "rbxassetid://87341373289618",
	treefish = "rbxassetid://115187179032064",
}

local function formatTimestamp(timestamp: number): string
	local date = os.date("!%b %d, %Y %I:%M %p", timestamp)
	return tostring(date)
end

-- Build the Journal ScreenGui
local function buildJournalUI(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "JournalGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 20
	gui.Enabled = false

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.4
	overlay.BorderSizePixel = 0
	overlay.Parent = gui

	-- Main journal frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "JournalFrame"
	mainFrame.Size = UDim2.fromScale(0.7, 0.8)
	mainFrame.Position = UDim2.fromScale(0.5, 0.5)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = COLORS.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = COLORS.Accent
	mainStroke.Thickness = 2
	mainStroke.Parent = mainFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 60)
	titleBar.BackgroundTransparency = 1
	titleBar.Parent = mainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -80, 1, 0)
	titleLabel.Position = UDim2.fromOffset(20, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "📓 Mia's Field Journal"
	titleLabel.TextColor3 = COLORS.TextPrimary
	titleLabel.TextSize = 28
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Progress counter
	local progressLabel = Instance.new("TextLabel")
	progressLabel.Name = "Progress"
	progressLabel.Size = UDim2.new(0, 120, 0, 30)
	progressLabel.Position = UDim2.new(1, -140, 0, 15)
	progressLabel.BackgroundColor3 = COLORS.Accent
	progressLabel.BackgroundTransparency = 0.3
	progressLabel.TextColor3 = COLORS.TextPrimary
	progressLabel.TextSize = 16
	progressLabel.Font = Enum.Font.GothamBold
	progressLabel.Text = "0 / 5 Found"
	progressLabel.Parent = titleBar

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 8)
	progressCorner.Parent = progressLabel

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.fromOffset(40, 40)
	closeBtn.Position = UDim2.new(1, -50, 0, 10)
	closeBtn.AnchorPoint = Vector2.new(0, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = COLORS.TextPrimary
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = mainFrame

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		toggleJournal()
	end)

	-- Scrolling frame for creature cards
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "CreatureList"
	scrollFrame.Size = UDim2.new(1, -40, 1, -80)
	scrollFrame.Position = UDim2.new(0, 20, 0, 70)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = COLORS.Accent
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- auto-set
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 12)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.Parent = scrollFrame

	-- Build a card for each creature
	local orderedCreatures = { "marlow", "luna", "seahorse", "redoctopus", "treefish" }

	for _, creatureId in orderedCreatures do
		local def = CreatureDefinitions[creatureId]
		if not def then continue end

		local card = Instance.new("Frame")
		card.Name = "Card_" .. creatureId
		card.Size = UDim2.new(1, -20, 0, 120)
		card.BackgroundColor3 = COLORS.CardLocked
		card.BorderSizePixel = 0
		card.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 12)
		cardCorner.Parent = card

		-- Icon area (left side)
		local iconFrame = Instance.new("Frame")
		iconFrame.Name = "IconFrame"
		iconFrame.Size = UDim2.new(0, 90, 0, 90)
		iconFrame.Position = UDim2.fromOffset(15, 15)
		iconFrame.BackgroundColor3 = COLORS.Silhouette
		iconFrame.BorderSizePixel = 0
		iconFrame.Parent = card

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 10)
		iconCorner.Parent = iconFrame

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.fromScale(1, 1)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = "❓"
		iconLabel.TextSize = 40
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.Parent = iconFrame

		-- Image overlay (hidden by default, shown when unlocked if sprite exists)
		local iconImage = Instance.new("ImageLabel")
		iconImage.Name = "IconImage"
		iconImage.Size = UDim2.fromScale(1, 1)
		iconImage.BackgroundTransparency = 1
		iconImage.ScaleType = Enum.ScaleType.Fit
		iconImage.Image = ""
		iconImage.Visible = false
		iconImage.Parent = iconFrame

		-- Text area (right side)
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "CreatureName"
		nameLabel.Size = UDim2.new(1, -130, 0, 28)
		nameLabel.Position = UDim2.fromOffset(120, 12)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "???"
		nameLabel.TextColor3 = COLORS.TextPrimary
		nameLabel.TextSize = 22
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Description"
		descLabel.Size = UDim2.new(1, -130, 0, 40)
		descLabel.Position = UDim2.fromOffset(120, 42)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = def.HabitatHint
		descLabel.TextColor3 = COLORS.TextHint
		descLabel.TextSize = 14
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.Parent = card

		local timestampLabel = Instance.new("TextLabel")
		timestampLabel.Name = "Timestamp"
		timestampLabel.Size = UDim2.new(1, -130, 0, 18)
		timestampLabel.Position = UDim2.fromOffset(120, 88)
		timestampLabel.BackgroundTransparency = 1
		timestampLabel.Text = ""
		timestampLabel.TextColor3 = COLORS.TextSecondary
		timestampLabel.TextSize = 12
		timestampLabel.Font = Enum.Font.Gotham
		timestampLabel.TextXAlignment = Enum.TextXAlignment.Left
		timestampLabel.Parent = card

		creatureCards[creatureId] = card
	end

	gui.Parent = player.PlayerGui
	return gui
end

-- Update a single creature card to locked or unlocked state
local function updateCard(creatureId: string)
	local card = creatureCards[creatureId]
	if not card then return end

	local def = CreatureDefinitions[creatureId]
	if not def then return end

	local isUnlocked = unlockedCreatures[creatureId] ~= nil

	local iconFrame = card:FindFirstChild("IconFrame")
	local iconLabel = iconFrame and iconFrame:FindFirstChild("Icon")
	local nameLabel = card:FindFirstChild("CreatureName")
	local descLabel = card:FindFirstChild("Description")
	local timestampLabel = card:FindFirstChild("Timestamp")

	local iconImage = iconFrame and iconFrame:FindFirstChild("IconImage")

	if isUnlocked then
		card.BackgroundColor3 = COLORS.CardUnlocked
		if iconFrame then
			iconFrame.BackgroundColor3 = CREATURE_COLORS[creatureId] or COLORS.Accent
		end
		-- Use sprite image if available, otherwise fall back to emoji
		if iconImage and CREATURE_IMAGES[creatureId] then
			iconImage.Image = CREATURE_IMAGES[creatureId]
			iconImage.Visible = true
			if iconLabel then iconLabel.Visible = false end
		else
			if iconImage then iconImage.Visible = false end
			if iconLabel then
				iconLabel.Visible = true
				iconLabel.Text = CREATURE_ICONS[creatureId] or "✅"
			end
		end
		if nameLabel then
			nameLabel.Text = def.Name
		end
		if descLabel then
			descLabel.Text = def.UnlockFact
			descLabel.TextColor3 = COLORS.TextPrimary
		end
		if timestampLabel then
			timestampLabel.Text = "Captured: " .. formatTimestamp(unlockedCreatures[creatureId])
		end
	else
		card.BackgroundColor3 = COLORS.CardLocked
		if iconFrame then
			iconFrame.BackgroundColor3 = COLORS.Silhouette
		end
		if iconImage then iconImage.Visible = false end
		if iconLabel then
			iconLabel.Visible = true
			iconLabel.Text = "❓"
		end
		if nameLabel then
			nameLabel.Text = "???"
		end
		if descLabel then
			descLabel.Text = def.HabitatHint
			descLabel.TextColor3 = COLORS.TextHint
		end
		if timestampLabel then
			timestampLabel.Text = ""
		end
	end
end

-- Update all cards and the progress counter
local function refreshJournal()
	local count = 0
	for creatureId, _ in creatureCards do
		updateCard(creatureId)
		if unlockedCreatures[creatureId] then
			count += 1
		end
	end

	-- Update progress label
	if journalGui then
		local journalFrame = journalGui:FindFirstChild("JournalFrame")
		if journalFrame then
			local titleBar = journalFrame:FindFirstChild("TitleBar")
			if titleBar then
				local progress = titleBar:FindFirstChild("Progress")
				if progress then
					progress.Text = count .. " / 5 Found"
				end
			end
		end
	end
end

-- Toggle journal visibility
function toggleJournal()
	journalOpen = not journalOpen
	if journalGui then
		journalGui.Enabled = journalOpen
		if journalOpen then
			refreshJournal()
		end
	end
end

-- Unlock popup notification
local function showUnlockPopup(creatureId: string)
	local def = CreatureDefinitions[creatureId]
	if not def then return end

	local popupGui = Instance.new("ScreenGui")
	popupGui.Name = "UnlockPopup"
	popupGui.ResetOnSpawn = false
	popupGui.IgnoreGuiInset = true
	popupGui.DisplayOrder = 50

	local popup = Instance.new("Frame")
	popup.Name = "Popup"
	popup.Size = UDim2.fromOffset(350, 100)
	popup.Position = UDim2.new(0.5, 0, 0, -120)
	popup.AnchorPoint = Vector2.new(0.5, 0)
	popup.BackgroundColor3 = COLORS.CardUnlocked
	popup.BorderSizePixel = 0
	popup.Parent = popupGui

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 12)
	popupCorner.Parent = popup

	local popupStroke = Instance.new("UIStroke")
	popupStroke.Color = Color3.fromRGB(100, 255, 150)
	popupStroke.Thickness = 2
	popupStroke.Parent = popup

	-- Popup icon: use image if available, otherwise emoji
	if CREATURE_IMAGES[creatureId] then
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.fromOffset(60, 60)
		icon.Position = UDim2.fromOffset(15, 20)
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Image = CREATURE_IMAGES[creatureId]
		icon.Parent = popup
	else
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.fromOffset(60, 60)
		icon.Position = UDim2.fromOffset(15, 20)
		icon.BackgroundTransparency = 1
		icon.Text = CREATURE_ICONS[creatureId] or "✅"
		icon.TextSize = 40
		icon.Font = Enum.Font.GothamBold
		icon.Parent = popup
	end

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -90, 0, 30)
	title.Position = UDim2.fromOffset(80, 15)
	title.BackgroundTransparency = 1
	title.Text = "NEW DISCOVERY!"
	title.TextColor3 = Color3.fromRGB(100, 255, 150)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = popup

	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.new(1, -90, 0, 24)
	nameText.Position = UDim2.fromOffset(80, 48)
	nameText.BackgroundTransparency = 1
	nameText.Text = def.Name .. " added to your journal!"
	nameText.TextColor3 = COLORS.TextPrimary
	nameText.TextSize = 16
	nameText.Font = Enum.Font.Gotham
	nameText.TextXAlignment = Enum.TextXAlignment.Left
	nameText.Parent = popup

	popupGui.Parent = player.PlayerGui

	-- Animate slide in
	local slideIn = TweenService:Create(popup, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 30),
	})
	slideIn:Play()

	-- Auto-dismiss after 4 seconds
	task.delay(4, function()
		local slideOut = TweenService:Create(popup, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -120),
		})
		slideOut:Play()
		slideOut.Completed:Wait()
		popupGui:Destroy()
	end)
end

-- Build the journal UI on load
journalGui = buildJournalUI()

-- Listen for journal data updates from server
task.spawn(function()
	local updateJournal = Events.WaitFor(Events.Names.UpdateJournal)
	updateJournal.OnClientEvent:Connect(function(serverUnlocks: { [string]: number })
		-- Check for newly unlocked creatures (for popup)
		for creatureId, timestamp in serverUnlocks do
			if not unlockedCreatures[creatureId] then
				-- This is a new unlock — show popup
				task.defer(showUnlockPopup, creatureId)
			end
		end

		unlockedCreatures = serverUnlocks
		refreshJournal()
	end)
end)

-- Listen for capture results to show popup immediately
task.spawn(function()
	local captureResult = Events.WaitFor(Events.Names.CaptureResult)
	captureResult.OnClientEvent:Connect(function(success: boolean, creatureId: string, _message: string)
		if success and not unlockedCreatures[creatureId] then
			-- Mark as unlocked locally for immediate feedback
			unlockedCreatures[creatureId] = os.time()
			refreshJournal()
		end
	end)
end)

-- Toggle journal with J key
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.J then
		toggleJournal()
	end
end)

print("[JournalController] Loaded. Press J to open/close the Field Journal.")
