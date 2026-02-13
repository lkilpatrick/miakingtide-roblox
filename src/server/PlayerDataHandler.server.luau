--[[
	PlayerDataHandler.server.luau
	Manages player data: loading, saving, and tracking creature unlocks.
	Uses a mock DataStore approach for development, easily swappable to ProfileService.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CreatureDefinitions = require(Shared:WaitForChild("CreatureDefinitions"))
local Events = require(Shared:WaitForChild("Events"))

-- Create all remote events on server startup
Events.CreateAll()

-- DataStore setup (will error in Studio without API access enabled — that's fine for mock)
local DATA_STORE_NAME = "MiaKingtidePlayerData_v1"
local dataStore = nil
pcall(function()
	dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
end)

-- In-memory player data cache
local PlayerDataCache: { [number]: PlayerData } = {}

export type PlayerData = {
	UnlockedCreatures: { [string]: number }, -- creatureId -> os.time() timestamp
}

local function createDefaultData(): PlayerData
	return {
		UnlockedCreatures = {},
	}
end

local function loadPlayerData(player: Player): PlayerData
	local key = "Player_" .. player.UserId
	local data: PlayerData? = nil

	if dataStore then
		local success, result = pcall(function()
			return dataStore:GetAsync(key)
		end)
		if success and result then
			data = result :: PlayerData
		elseif not success then
			warn("[PlayerDataHandler] Failed to load data for", player.Name, ":", result)
		end
	end

	if not data then
		data = createDefaultData()
	end

	return data
end

local function savePlayerData(player: Player)
	local data = PlayerDataCache[player.UserId]
	if not data then return end

	local key = "Player_" .. player.UserId
	if dataStore then
		local success, err = pcall(function()
			dataStore:SetAsync(key, data)
		end)
		if not success then
			warn("[PlayerDataHandler] Failed to save data for", player.Name, ":", err)
		end
	end
end

-- Send the player's current journal state to the client
local function sendJournalUpdate(player: Player)
	local data = PlayerDataCache[player.UserId]
	if not data then return end

	local updateEvent = Events.Get(Events.Names.UpdateJournal)
	if updateEvent then
		updateEvent:FireClient(player, data.UnlockedCreatures)
	end
end

-- Unlock a creature for a player. Returns true if newly unlocked.
local function unlockCreature(player: Player, creatureId: string): boolean
	local data = PlayerDataCache[player.UserId]
	if not data then return false end

	if not CreatureDefinitions.IsValid(creatureId) then
		warn("[PlayerDataHandler] Invalid creature ID:", creatureId)
		return false
	end

	-- Already unlocked
	if data.UnlockedCreatures[creatureId] then
		return false
	end

	data.UnlockedCreatures[creatureId] = os.time()
	print("[PlayerDataHandler]", player.Name, "unlocked:", creatureId)

	-- Send updated journal to client
	sendJournalUpdate(player)

	-- Check for game completion
	local unlockCount = 0
	for _ in data.UnlockedCreatures do
		unlockCount += 1
	end

	if unlockCount >= 5 then
		local completedEvent = Events.Get(Events.Names.GameCompleted)
		if completedEvent then
			completedEvent:FireClient(player)
		end
		print("[PlayerDataHandler]", player.Name, "has found ALL creatures!")
	end

	return true
end

-- Reset a player's data (for dev/testing)
local function resetPlayerData(player: Player)
	PlayerDataCache[player.UserId] = createDefaultData()
	sendJournalUpdate(player)
	print("[PlayerDataHandler] Data reset for", player.Name)
end

-- Player lifecycle
Players.PlayerAdded:Connect(function(player: Player)
	local data = loadPlayerData(player)
	PlayerDataCache[player.UserId] = data
	print("[PlayerDataHandler] Loaded data for", player.Name)

	-- Small delay to ensure client is ready, then send initial journal state
	task.delay(2, function()
		if player.Parent then
			sendJournalUpdate(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	savePlayerData(player)
	PlayerDataCache[player.UserId] = nil
end)

-- Periodic auto-save
task.spawn(function()
	while true do
		task.wait(120)
		for userId, _ in PlayerDataCache do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				savePlayerData(player)
			end
		end
	end
end)

-- Expose module functions for other server scripts
local PlayerDataHandler = {}
PlayerDataHandler.UnlockCreature = unlockCreature
PlayerDataHandler.GetData = function(player: Player): PlayerData?
	return PlayerDataCache[player.UserId]
end
PlayerDataHandler.ResetData = resetPlayerData
PlayerDataHandler.SendJournalUpdate = sendJournalUpdate

-- Store in shared module registry so other server scripts can access it
local ServerStorage = game:GetService("ServerStorage")
local registry = ServerStorage:FindFirstChild("ModuleRegistry")
if not registry then
	registry = Instance.new("Folder")
	registry.Name = "ModuleRegistry"
	registry.Parent = ServerStorage
end

local bindable = Instance.new("BindableFunction")
bindable.Name = "GetPlayerDataHandler"
bindable.OnInvoke = function()
	return PlayerDataHandler
end
bindable.Parent = registry

return nil
