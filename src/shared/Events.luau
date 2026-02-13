--[[
	Events.luau
	Centralized RemoteEvent/RemoteFunction setup.
	Server creates them; client waits for them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = {}

-- Event names used throughout the game
Events.Names = {
	RequestCapture = "RequestCapture",       -- Client -> Server: player tries to capture a creature
	UpdateJournal = "UpdateJournal",         -- Server -> Client: send updated unlock data
	CaptureResult = "CaptureResult",         -- Server -> Client: result of a capture attempt
	GameCompleted = "GameCompleted",         -- Server -> Client: all creatures found
}

-- Get or create the events folder
local function getEventsFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild("GameEvents")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GameEvents"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

-- Server-side: create all RemoteEvents
function Events.CreateAll()
	local folder = getEventsFolder()
	for _, eventName in Events.Names do
		if not folder:FindFirstChild(eventName) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = eventName
			remote.Parent = folder
		end
	end
end

-- Client-side: wait for a specific RemoteEvent
function Events.WaitFor(eventName: string): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild("GameEvents", 10)
	assert(folder, "[Events] GameEvents folder not found!")
	local remote = folder:WaitForChild(eventName, 10)
	assert(remote, "[Events] RemoteEvent '" .. eventName .. "' not found!")
	return remote :: RemoteEvent
end

-- Get a RemoteEvent (no waiting, returns nil if not found)
function Events.Get(eventName: string): RemoteEvent?
	local folder = ReplicatedStorage:FindFirstChild("GameEvents")
	if folder then
		return folder:FindFirstChild(eventName) :: RemoteEvent
	end
	return nil
end

return Events
