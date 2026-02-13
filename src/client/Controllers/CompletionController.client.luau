--[[
	CompletionController.client.luau
	Handles the "Game Complete" celebration when all 5 creatures are found.
	Listens for the GameCompleted remote event from the server.
	Shows confetti particles and a "Monterey Bay Expert" badge UI.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Events = require(Shared:WaitForChild("Events"))

local player = Players.LocalPlayer

-- Confetti particle emitter attached to the camera
local function createConfetti(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "ConfettiGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100

	-- Spawn confetti pieces
	local colors = {
		Color3.fromRGB(255, 100, 100),
		Color3.fromRGB(100, 255, 100),
		Color3.fromRGB(100, 100, 255),
		Color3.fromRGB(255, 255, 100),
		Color3.fromRGB(255, 150, 50),
		Color3.fromRGB(200, 100, 255),
		Color3.fromRGB(100, 255, 255),
	}

	for i = 1, 60 do
		local confetti = Instance.new("Frame")
		confetti.Name = "Confetti_" .. i
		confetti.Size = UDim2.fromOffset(math.random(6, 14), math.random(6, 14))
		confetti.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, -0.05, 0)
		confetti.BackgroundColor3 = colors[math.random(1, #colors)]
		confetti.BorderSizePixel = 0
		confetti.Rotation = math.random(0, 360)
		confetti.Parent = gui

		if math.random() > 0.5 then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = confetti
		end

		-- Animate falling
		local duration = math.random(20, 40) / 10 -- 2-4 seconds
		local endX = confetti.Position.X.Scale + (math.random() - 0.5) * 0.2
		local tween = TweenService:Create(confetti, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Position = UDim2.new(endX, 0, 1.1, 0),
			Rotation = confetti.Rotation + math.random(-360, 360),
		})

		task.delay(math.random() * 1.5, function()
			tween:Play()
		end)
	end

	return gui
end

-- Build the celebration badge UI
local function showCelebration()
	-- Confetti
	local confettiGui = createConfetti()
	confettiGui.Parent = player.PlayerGui

	-- Badge overlay
	local badgeGui = Instance.new("ScreenGui")
	badgeGui.Name = "CompletionBadge"
	badgeGui.ResetOnSpawn = false
	badgeGui.IgnoreGuiInset = true
	badgeGui.DisplayOrder = 99

	-- Dim overlay
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = badgeGui

	-- Badge card
	local card = Instance.new("Frame")
	card.Name = "BadgeCard"
	card.Size = UDim2.fromOffset(420, 320)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(15, 25, 50)
	card.BorderSizePixel = 0
	card.Parent = badgeGui

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 20)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(255, 215, 0) -- Gold
	cardStroke.Thickness = 3
	cardStroke.Parent = card

	-- Star icon
	local star = Instance.new("TextLabel")
	star.Size = UDim2.fromOffset(80, 80)
	star.Position = UDim2.new(0.5, 0, 0, 25)
	star.AnchorPoint = Vector2.new(0.5, 0)
	star.BackgroundTransparency = 1
	star.Text = "⭐"
	star.TextSize = 60
	star.Font = Enum.Font.GothamBold
	star.Parent = card

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 40)
	title.Position = UDim2.new(0.5, 0, 0, 110)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.BackgroundTransparency = 1
	title.Text = "MONTEREY BAY EXPERT"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.Parent = card

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -40, 0, 30)
	subtitle.Position = UDim2.new(0.5, 0, 0, 155)
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "You found all 5 sea creatures!"
	subtitle.TextColor3 = Color3.fromRGB(200, 210, 230)
	subtitle.TextSize = 18
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = card

	-- Creature list
	local creatures = "🦦 Marlow  •  🦭 Luna  •  🐴 Seahorse\n🐙 Red Octopus  •  🐟 Treefish"
	local creatureList = Instance.new("TextLabel")
	creatureList.Size = UDim2.new(1, -40, 0, 50)
	creatureList.Position = UDim2.new(0.5, 0, 0, 195)
	creatureList.AnchorPoint = Vector2.new(0.5, 0)
	creatureList.BackgroundTransparency = 1
	creatureList.Text = creatures
	creatureList.TextColor3 = Color3.fromRGB(180, 190, 200)
	creatureList.TextSize = 16
	creatureList.Font = Enum.Font.Gotham
	creatureList.Parent = card

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(160, 40)
	closeBtn.Position = UDim2.new(0.5, 0, 1, -20)
	closeBtn.AnchorPoint = Vector2.new(0.5, 1)
	closeBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 200)
	closeBtn.Text = "Amazing!"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = 18
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = card

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 10)
	closeBtnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		-- Fade out
		local fadeOut = TweenService:Create(overlay, TweenInfo.new(0.5), {
			BackgroundTransparency = 1,
		})
		local cardFade = TweenService:Create(card, TweenInfo.new(0.5), {
			Position = UDim2.new(0.5, 0, 0.5, 50),
			BackgroundTransparency = 1,
		})
		fadeOut:Play()
		cardFade:Play()
		cardFade.Completed:Wait()
		badgeGui:Destroy()
	end)

	badgeGui.Parent = player.PlayerGui

	-- Animate card entrance
	card.Position = UDim2.new(0.5, 0, 0.5, 50)
	card.BackgroundTransparency = 1
	local entrance = TweenService:Create(card, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0,
	})
	entrance:Play()

	-- Remove confetti after 6 seconds
	task.delay(6, function()
		if confettiGui and confettiGui.Parent then
			confettiGui:Destroy()
		end
	end)
end

-- Listen for GameCompleted event
task.spawn(function()
	local gameCompleted = Events.WaitFor(Events.Names.GameCompleted)
	gameCompleted.OnClientEvent:Connect(function()
		print("[CompletionController] All creatures found! Showing celebration!")
		showCelebration()
	end)
end)

print("[CompletionController] Loaded. Waiting for game completion...")
