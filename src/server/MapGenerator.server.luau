--[[
	MapGenerator.server.luau
	Automatically generates habitat zones and creature models when the game starts.
	Skips generation if creatures already exist in workspace.
]]

local CollectionService = game:GetService("CollectionService")

local TAG = "CreatureCollectible"

-- Skip if creatures already exist (e.g. manually placed in Studio)
if #CollectionService:GetTagged(TAG) > 0 then
	print("[MapGenerator] Creatures already exist, skipping generation.")
	return
end

print("[MapGenerator] Generating habitats and creatures...")

------------------------------------------------------------------------
-- HABITATS
------------------------------------------------------------------------

local function createHabitats(): Folder
	local existing = workspace:FindFirstChild("Habitats")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Habitats"
	folder.Parent = workspace

	local zones = {
		{
			Name = "KelpForest",
			Position = Vector3.new(50, 2, 50),
			Size = Vector3.new(80, 4, 80),
			Color = Color3.fromRGB(34, 139, 34),
			Material = Enum.Material.Grass,
		},
		{
			Name = "RockyOutcrop",
			Position = Vector3.new(-60, 4, 30),
			Size = Vector3.new(60, 8, 60),
			Color = Color3.fromRGB(128, 128, 128),
			Material = Enum.Material.Slate,
		},
		{
			Name = "SandyBottom",
			Position = Vector3.new(0, 0, -80),
			Size = Vector3.new(100, 2, 80),
			Color = Color3.fromRGB(237, 201, 175),
			Material = Enum.Material.Sand,
		},
		{
			Name = "Pier",
			Position = Vector3.new(-30, 3, -30),
			Size = Vector3.new(20, 6, 80),
			Color = Color3.fromRGB(139, 90, 43),
			Material = Enum.Material.Wood,
		},
		{
			Name = "RockyCrevice",
			Position = Vector3.new(80, 3, -40),
			Size = Vector3.new(50, 12, 50),
			Color = Color3.fromRGB(80, 80, 80),
			Material = Enum.Material.Rock,
		},
	}

	for _, zone in zones do
		local part = Instance.new("Part")
		part.Name = zone.Name
		part.Size = zone.Size
		part.Position = zone.Position
		part.Color = zone.Color
		part.Material = zone.Material
		part.Anchored = true
		part.CanCollide = true
		part.Transparency = 0.3
		part.Parent = folder

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(200, 50)
		billboard.StudsOffset = Vector3.new(0, zone.Size.Y / 2 + 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = part

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = zone.Name
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = billboard
	end

	print("[MapGenerator] Created", #zones, "habitat zones.")
	return folder
end

------------------------------------------------------------------------
-- HELPER: Create a basic part
------------------------------------------------------------------------

type PartConfig = {
	Name: string,
	Size: Vector3,
	Position: Vector3,
	Color: Color3,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
	Rotation: Vector3?,
	Anchored: boolean?,
	CanCollide: boolean?,
}

local function makePart(config: PartConfig, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = config.Name
	part.Size = config.Size
	part.Position = config.Position
	part.Color = config.Color
	part.Material = config.Material or Enum.Material.SmoothPlastic
	part.Anchored = if config.Anchored ~= nil then config.Anchored else true
	part.CanCollide = if config.CanCollide ~= nil then config.CanCollide else false

	if config.Shape then
		part.Shape = config.Shape
	end
	if config.Rotation then
		part.Rotation = config.Rotation
	end

	part.Parent = parent
	return part
end

------------------------------------------------------------------------
-- CREATURE BUILDERS
------------------------------------------------------------------------

local function createMarlow(parent: Instance)
	local bp = Vector3.new(60, 7, 60)
	local brown = Color3.fromRGB(139, 90, 43)
	local lightBrown = Color3.fromRGB(194, 154, 108)
	local dark = Color3.fromRGB(40, 20, 20)
	local black = Color3.fromRGB(20, 20, 20)

	local mdl = Instance.new("Model")
	mdl.Name = "Marlow"
	mdl:SetAttribute("CreatureId", "marlow")

	local body = makePart({
		Name = "Body", Size = Vector3.new(3, 2.5, 5),
		Position = bp, Color = brown,
	}, mdl)

	local head = makePart({
		Name = "Head", Size = Vector3.new(2.8, 2.5, 2.5),
		Position = bp + Vector3.new(0, 0.5, 3.2), Color = brown,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "Nose", Size = Vector3.new(1, 0.8, 1),
		Position = head.Position + Vector3.new(0, -0.3, 1.2), Color = dark,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "Belly", Size = Vector3.new(2.6, 1.8, 4),
		Position = bp + Vector3.new(0, -0.5, 0), Color = lightBrown,
	}, mdl)

	makePart({
		Name = "Tail", Size = Vector3.new(1.8, 1, 2.5),
		Position = bp + Vector3.new(0, -0.3, -3.5), Color = brown,
	}, mdl)

	makePart({
		Name = "LeftPaw", Size = Vector3.new(1.2, 0.5, 1.5),
		Position = bp + Vector3.new(-1.5, -1, 1), Color = brown,
	}, mdl)

	makePart({
		Name = "RightPaw", Size = Vector3.new(1.2, 0.5, 1.5),
		Position = bp + Vector3.new(1.5, -1, 1), Color = brown,
	}, mdl)

	makePart({
		Name = "LeftEye", Size = Vector3.new(0.5, 0.5, 0.3),
		Position = head.Position + Vector3.new(-0.6, 0.4, 1), Color = black,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "RightEye", Size = Vector3.new(0.5, 0.5, 0.3),
		Position = head.Position + Vector3.new(0.6, 0.4, 1), Color = black,
		Shape = Enum.PartType.Ball,
	}, mdl)

	mdl.PrimaryPart = body
	CollectionService:AddTag(mdl, TAG)
	mdl.Parent = parent
	print("[MapGenerator] Placed Marlow the Sea Otter in Kelp Forest.")
end

local function createLuna(parent: Instance)
	local bp = Vector3.new(-55, 12, 35)
	local brown = Color3.fromRGB(101, 67, 33)
	local lightBrown = Color3.fromRGB(140, 100, 60)
	local dark = Color3.fromRGB(30, 20, 20)
	local black = Color3.fromRGB(20, 20, 20)

	local mdl = Instance.new("Model")
	mdl.Name = "Luna"
	mdl:SetAttribute("CreatureId", "luna")

	local body = makePart({
		Name = "Body", Size = Vector3.new(4, 3.5, 7),
		Position = bp, Color = brown,
	}, mdl)

	makePart({
		Name = "Chest", Size = Vector3.new(3.8, 3, 4),
		Position = bp + Vector3.new(0, 0.5, 2), Color = lightBrown,
	}, mdl)

	makePart({
		Name = "Neck", Size = Vector3.new(3, 3, 2.5),
		Position = bp + Vector3.new(0, 2, 3.5), Color = brown,
	}, mdl)

	local head = makePart({
		Name = "Head", Size = Vector3.new(3, 2.8, 3),
		Position = bp + Vector3.new(0, 3.5, 4.5), Color = brown,
		Shape = Enum.PartType.Ball,
	}, mdl)

	local snout = makePart({
		Name = "Snout", Size = Vector3.new(1.8, 1.2, 2),
		Position = head.Position + Vector3.new(0, -0.3, 1.5), Color = brown,
	}, mdl)

	makePart({
		Name = "Nose", Size = Vector3.new(0.8, 0.6, 0.6),
		Position = snout.Position + Vector3.new(0, 0.2, 0.9), Color = dark,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "LeftFlipper", Size = Vector3.new(1, 0.4, 3),
		Position = bp + Vector3.new(-2.5, -1, 1), Color = brown,
		Rotation = Vector3.new(0, 0, 20),
	}, mdl)

	makePart({
		Name = "RightFlipper", Size = Vector3.new(1, 0.4, 3),
		Position = bp + Vector3.new(2.5, -1, 1), Color = brown,
		Rotation = Vector3.new(0, 0, -20),
	}, mdl)

	makePart({
		Name = "TailFlippers", Size = Vector3.new(3, 0.5, 2.5),
		Position = bp + Vector3.new(0, -1.5, -4), Color = brown,
	}, mdl)

	makePart({
		Name = "LeftEye", Size = Vector3.new(0.5, 0.5, 0.3),
		Position = head.Position + Vector3.new(-0.8, 0.3, 1.1), Color = black,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "RightEye", Size = Vector3.new(0.5, 0.5, 0.3),
		Position = head.Position + Vector3.new(0.8, 0.3, 1.1), Color = black,
		Shape = Enum.PartType.Ball,
	}, mdl)

	mdl.PrimaryPart = body
	CollectionService:AddTag(mdl, TAG)
	mdl.Parent = parent
	print("[MapGenerator] Placed Luna the Sea Lion on Rocky Outcrop.")
end

local function createSeahorse(parent: Instance)
	local bp = Vector3.new(-30, 8, -45)
	local pink = Color3.fromRGB(219, 130, 163)
	local blue = Color3.fromRGB(60, 60, 140)
	local lightPink = Color3.fromRGB(240, 180, 200)
	local black = Color3.fromRGB(10, 10, 10)

	local mdl = Instance.new("Model")
	mdl.Name = "Seahorse"
	mdl:SetAttribute("CreatureId", "seahorse")

	local body = makePart({
		Name = "Body", Size = Vector3.new(1.8, 4, 1.5),
		Position = bp, Color = pink,
	}, mdl)

	local head = makePart({
		Name = "Head", Size = Vector3.new(2, 2, 2),
		Position = bp + Vector3.new(0, 3, 0), Color = pink,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "Snout", Size = Vector3.new(0.6, 0.5, 1.8),
		Position = head.Position + Vector3.new(0, -0.3, 1.2), Color = pink,
	}, mdl)

	makePart({
		Name = "Crown", Size = Vector3.new(0.5, 1, 0.5),
		Position = head.Position + Vector3.new(0, 1.2, 0), Color = blue,
	}, mdl)

	makePart({
		Name = "Belly", Size = Vector3.new(2, 2.5, 1.8),
		Position = bp + Vector3.new(0, -0.5, 0.2), Color = lightPink,
	}, mdl)

	-- Curled tail
	makePart({
		Name = "TailCurve1", Size = Vector3.new(1, 1.5, 1),
		Position = bp + Vector3.new(0, -3, 0), Color = pink,
	}, mdl)

	makePart({
		Name = "TailCurve2", Size = Vector3.new(0.8, 1, 1),
		Position = bp + Vector3.new(0, -3.8, 0.8), Color = blue,
		Rotation = Vector3.new(30, 0, 0),
	}, mdl)

	makePart({
		Name = "TailTip", Size = Vector3.new(0.6, 0.6, 0.6),
		Position = bp + Vector3.new(0, -4, 1.5), Color = blue,
		Shape = Enum.PartType.Ball,
	}, mdl)

	-- Fins
	makePart({
		Name = "DorsalFin", Size = Vector3.new(0.2, 3, 1.5),
		Position = bp + Vector3.new(0, 1, -0.8), Color = blue,
	}, mdl)

	makePart({
		Name = "LeftFin", Size = Vector3.new(0.8, 0.2, 0.8),
		Position = bp + Vector3.new(-1, 0.5, 0.3), Color = pink,
		Rotation = Vector3.new(0, 0, 30),
	}, mdl)

	makePart({
		Name = "RightFin", Size = Vector3.new(0.8, 0.2, 0.8),
		Position = bp + Vector3.new(1, 0.5, 0.3), Color = pink,
		Rotation = Vector3.new(0, 0, -30),
	}, mdl)

	-- Eyes
	makePart({
		Name = "LeftEye", Size = Vector3.new(0.5, 0.5, 0.3),
		Position = head.Position + Vector3.new(-0.6, 0.2, 0.8), Color = black,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "RightEye", Size = Vector3.new(0.5, 0.5, 0.3),
		Position = head.Position + Vector3.new(0.6, 0.2, 0.8), Color = black,
		Shape = Enum.PartType.Ball,
	}, mdl)

	-- Blue stripes
	for i = 1, 4 do
		makePart({
			Name = "Stripe" .. i, Size = Vector3.new(2, 0.3, 1.6),
			Position = bp + Vector3.new(0, 1.5 - i * 0.9, 0), Color = blue,
		}, mdl)
	end

	mdl.PrimaryPart = body
	CollectionService:AddTag(mdl, TAG)
	mdl.Parent = parent
	print("[MapGenerator] Placed Seahorse at the Pier.")
end

local function createRedOctopus(parent: Instance)
	local bp = Vector3.new(85, 7, -45)
	local red = Color3.fromRGB(210, 70, 50)
	local lightRed = Color3.fromRGB(230, 120, 100)
	local underside = Color3.fromRGB(240, 190, 160)
	local white = Color3.fromRGB(255, 255, 240)
	local black = Color3.fromRGB(10, 10, 10)

	local mdl = Instance.new("Model")
	mdl.Name = "RedOctopus"
	mdl:SetAttribute("CreatureId", "redoctopus")

	local head = makePart({
		Name = "Head", Size = Vector3.new(4, 3.2, 4),
		Position = bp + Vector3.new(0, 2, 0), Color = red,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "Mantle", Size = Vector3.new(3.2, 4, 3.2),
		Position = bp + Vector3.new(0, 4.5, 0), Color = red,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "Mouth", Size = Vector3.new(1.5, 0.8, 1),
		Position = head.Position + Vector3.new(0, -1, 1.5), Color = underside,
		Shape = Enum.PartType.Ball,
	}, mdl)

	-- Eyes with pupils
	local leftEye = makePart({
		Name = "LeftEye", Size = Vector3.new(1, 0.9, 0.7),
		Position = head.Position + Vector3.new(-1.2, 0.5, 1.5), Color = white,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "LeftPupil", Size = Vector3.new(0.5, 0.6, 0.4),
		Position = leftEye.Position + Vector3.new(0, 0, 0.3), Color = black,
		Shape = Enum.PartType.Ball,
	}, mdl)

	local rightEye = makePart({
		Name = "RightEye", Size = Vector3.new(1, 0.9, 0.7),
		Position = head.Position + Vector3.new(1.2, 0.5, 1.5), Color = white,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "RightPupil", Size = Vector3.new(0.5, 0.6, 0.4),
		Position = rightEye.Position + Vector3.new(0, 0, 0.3), Color = black,
		Shape = Enum.PartType.Ball,
	}, mdl)

	-- 8 tentacles with segments, tips, and suckers
	local angles = { 0, 45, 90, 135, 180, 225, 270, 315 }
	for i, ang in angles do
		local rad = math.rad(ang)
		local tx = math.cos(rad) * 2.5
		local tz = math.sin(rad) * 2.5

		local seg1 = makePart({
			Name = "Tentacle" .. i .. "_A", Size = Vector3.new(0.7, 0.7, 2.5),
			Position = bp + Vector3.new(tx, 0.5, tz), Color = red,
			Rotation = Vector3.new(0, ang, 0),
		}, mdl)

		makePart({
			Name = "Tentacle" .. i .. "_B", Size = Vector3.new(0.5, 0.5, 2.5),
			Position = bp + Vector3.new(tx * 1.7, -0.2, tz * 1.7), Color = lightRed,
			Rotation = Vector3.new(20, ang, 0),
		}, mdl)

		makePart({
			Name = "Tentacle" .. i .. "_Tip", Size = Vector3.new(0.4, 0.4, 0.4),
			Position = bp + Vector3.new(tx * 2.3, -0.5, tz * 2.3), Color = lightRed,
			Shape = Enum.PartType.Ball,
		}, mdl)

		makePart({
			Name = "Sucker" .. i, Size = Vector3.new(0.25, 0.15, 0.25),
			Position = seg1.Position + Vector3.new(0, -0.35, 0), Color = underside,
			Shape = Enum.PartType.Ball,
		}, mdl)
	end

	mdl.PrimaryPart = head
	CollectionService:AddTag(mdl, TAG)
	mdl.Parent = parent
	print("[MapGenerator] Placed Red Octopus in Rocky Crevice.")
end

local function createTreefish(parent: Instance)
	local bp = Vector3.new(-10, 2, -85)
	local yellow = Color3.fromRGB(200, 180, 50)
	local stripe = Color3.fromRGB(30, 30, 30)
	local mouthColor = Color3.fromRGB(220, 140, 140)
	local black = Color3.fromRGB(10, 10, 10)

	local mdl = Instance.new("Model")
	mdl.Name = "Treefish"
	mdl:SetAttribute("CreatureId", "treefish")

	local body = makePart({
		Name = "Body", Size = Vector3.new(2.5, 3, 5),
		Position = bp, Color = yellow,
	}, mdl)

	local head = makePart({
		Name = "Head", Size = Vector3.new(2.8, 3, 2.5),
		Position = bp + Vector3.new(0, 0, 3.2), Color = yellow,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "Mouth", Size = Vector3.new(1.5, 0.6, 0.8),
		Position = head.Position + Vector3.new(0, -0.8, 1), Color = mouthColor,
	}, mdl)

	-- Fins
	makePart({
		Name = "DorsalFin", Size = Vector3.new(0.2, 2, 4),
		Position = bp + Vector3.new(0, 2.5, 0), Color = yellow,
	}, mdl)

	makePart({
		Name = "DorsalTip", Size = Vector3.new(0.2, 1, 1),
		Position = bp + Vector3.new(0, 3.5, 0), Color = stripe,
	}, mdl)

	makePart({
		Name = "TailFin", Size = Vector3.new(0.3, 2.5, 1.5),
		Position = bp + Vector3.new(0, 0, -3.5), Color = yellow,
		Rotation = Vector3.new(15, 0, 0),
	}, mdl)

	makePart({
		Name = "LeftPectoral", Size = Vector3.new(1.5, 0.2, 1.5),
		Position = bp + Vector3.new(-1.8, -0.5, 1), Color = yellow,
		Rotation = Vector3.new(0, 0, 30),
	}, mdl)

	makePart({
		Name = "RightPectoral", Size = Vector3.new(1.5, 0.2, 1.5),
		Position = bp + Vector3.new(1.8, -0.5, 1), Color = yellow,
		Rotation = Vector3.new(0, 0, -30),
	}, mdl)

	makePart({
		Name = "AnalFin", Size = Vector3.new(0.2, 1, 2),
		Position = bp + Vector3.new(0, -1.8, -1), Color = yellow,
	}, mdl)

	-- Eyes
	makePart({
		Name = "LeftEye", Size = Vector3.new(0.8, 0.8, 0.5),
		Position = head.Position + Vector3.new(-0.9, 0.5, 0.8), Color = black,
		Shape = Enum.PartType.Ball,
	}, mdl)

	makePart({
		Name = "RightEye", Size = Vector3.new(0.8, 0.8, 0.5),
		Position = head.Position + Vector3.new(0.9, 0.5, 0.8), Color = black,
		Shape = Enum.PartType.Ball,
	}, mdl)

	-- Black stripes
	for i = 1, 5 do
		makePart({
			Name = "Stripe" .. i, Size = Vector3.new(2.6, 0.4, 0.6),
			Position = bp + Vector3.new(0, 1.2 - i * 0.5, 2.5 - i * 1), Color = stripe,
		}, mdl)
	end

	mdl.PrimaryPart = body
	CollectionService:AddTag(mdl, TAG)
	mdl.Parent = parent
	print("[MapGenerator] Placed Treefish on Sandy Bottom.")
end

------------------------------------------------------------------------
-- EFFECTS: Glow, sparkles, and name labels
------------------------------------------------------------------------

local function addEffects()
	for _, mdl in CollectionService:GetTagged(TAG) do
		local primary = mdl.PrimaryPart or mdl:FindFirstChildWhichIsA("BasePart")
		if not primary then continue end

		-- Highlight glow
		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(100, 200, 255)
		highlight.FillTransparency = 0.85
		highlight.OutlineColor = Color3.fromRGB(0, 200, 255)
		highlight.OutlineTransparency = 0.3
		highlight.Parent = mdl

		-- Point light
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(100, 200, 255)
		light.Brightness = 1.5
		light.Range = 16
		light.Parent = primary

		-- Sparkle particles
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "Sparkle"
		sparkle.Color = ColorSequence.new(
			Color3.fromRGB(150, 220, 255),
			Color3.fromRGB(255, 255, 200)
		)
		sparkle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkle.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
		sparkle.Lifetime = NumberRange.new(1, 2.5)
		sparkle.Rate = 8
		sparkle.Speed = NumberRange.new(0.5, 2)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.LightEmission = 1
		sparkle.Parent = primary

		-- Name label
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(180, 40)
		billboard.StudsOffset = Vector3.new(0, 5, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = primary

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = mdl.Name
		label.TextColor3 = Color3.fromRGB(100, 255, 200)
		label.TextStrokeColor3 = Color3.fromRGB(0, 50, 30)
		label.TextStrokeTransparency = 0
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = billboard
	end

	print("[MapGenerator] Added glow, sparkles, and labels to all creatures.")
end

------------------------------------------------------------------------
-- RUN
------------------------------------------------------------------------

local habitats = createHabitats()

createMarlow(habitats)
createLuna(habitats)
createSeahorse(habitats)
createRedOctopus(habitats)
createTreefish(habitats)

addEffects()

print("[MapGenerator] Map generation complete! 5 habitats, 5 creatures.")
