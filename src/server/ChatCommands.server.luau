--[[
	ChatCommands.server.luau
	Developer chat commands for testing.
	/reset - Wipes the player's creature data (restricted to DEVELOPER_USER_ID).
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- IMPORTANT: Replace this with your actual Roblox UserId for security
local DEVELOPER_USER_ID = 6121847161 -- Set your UserId here (e.g., 123456789)

-- Get the PlayerDataHandler module via the registry
local function getPlayerDataHandler()
	local registry = ServerStorage:WaitForChild("ModuleRegistry", 10)
	if not registry then return nil end
	local bindable = registry:WaitForChild("GetPlayerDataHandler", 10)
	if not bindable then return nil end
	return bindable:Invoke()
end

local function handleChatCommand(player: Player, message: string)
	-- Only allow developer commands from the authorized user
	-- If DEVELOPER_USER_ID is 0, allow any player (dev mode)
	if DEVELOPER_USER_ID ~= 0 and player.UserId ~= DEVELOPER_USER_ID then
		return
	end

	local lowerMessage = string.lower(message)

	if lowerMessage == "/reset" then
		local handler = getPlayerDataHandler()
		if handler then
			handler.ResetData(player)
			print("[ChatCommands]", player.Name, "reset their creature data.")
		else
			warn("[ChatCommands] Could not access PlayerDataHandler!")
		end
	elseif lowerMessage == "/unlockall" then
		-- Debug command: unlock all creatures instantly
		local handler = getPlayerDataHandler()
		if handler then
			local creatures = { "marlow", "luna", "seahorse", "redoctopus", "treefish" }
			for _, creatureId in creatures do
				handler.UnlockCreature(player, creatureId)
			end
			print("[ChatCommands]", player.Name, "unlocked all creatures (debug).")
		end
	elseif lowerMessage == "/status" then
		-- Debug command: print current unlock status
		local handler = getPlayerDataHandler()
		if handler then
			local data = handler.GetData(player)
			if data then
				local count = 0
				local names = {}
				for id, _ in data.UnlockedCreatures do
					count += 1
					table.insert(names, id)
				end
				print("[ChatCommands] Status for", player.Name, ":", count, "/5 -", table.concat(names, ", "))
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player: Player)
	player.Chatted:Connect(function(message: string)
		handleChatCommand(player, message)
	end)
end)

print("[ChatCommands] Loaded. Dev commands: /reset, /unlockall, /status")
