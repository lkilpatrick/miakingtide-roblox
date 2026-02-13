--[[
	CreatureDefinitions.luau
	Single source of truth for all creature data in the game.
	Used by both server and client.
]]

export type CreatureData = {
	Id: string,
	Name: string,
	Description: string,
	HabitatHint: string,
	UnlockFact: string,
	HabitatZone: string,
}

local CreatureDefinitions: { [string]: CreatureData } = {
	marlow = {
		Id = "marlow",
		Name = "Marlow",
		Description = "A playful sea otter who loves floating in the kelp.",
		HabitatHint = "Look among the swaying kelp forests...",
		UnlockFact = "Sea otters wrap themselves in kelp to keep from drifting while they sleep!",
		HabitatZone = "KelpForest",
	},
	luna = {
		Id = "luna",
		Name = "Luna",
		Description = "A curious sea lion basking on the rocks.",
		HabitatHint = "Check the rocky outcrop where the waves crash...",
		UnlockFact = "Sea lions can rotate their back flippers forward to walk on land!",
		HabitatZone = "RockyOutcrop",
	},
	flip = {
		Id = "flip",
		Name = "Flip",
		Description = "A shy harbor seal hiding near the pier.",
		HabitatHint = "Peek around the old pier pylons...",
		UnlockFact = "Harbor seals can hold their breath for up to 30 minutes underwater!",
		HabitatZone = "Pier",
	},
	octopus = {
		Id = "octopus",
		Name = "Giant Pacific Octopus",
		Description = "A master of disguise lurking in a rocky crevice.",
		HabitatHint = "Search the dark rocky crevice near the cave...",
		UnlockFact = "The Giant Pacific Octopus has three hearts and blue blood!",
		HabitatZone = "RockyCrevice",
	},
	batray = {
		Id = "batray",
		Name = "Bat Ray",
		Description = "A graceful ray gliding over the sandy bottom.",
		HabitatHint = "Scan the sandy bottom of the shallow bay...",
		UnlockFact = "Bat rays flap their pectoral fins like wings to 'fly' through the water!",
		HabitatZone = "SandyBottom",
	},
}

-- Utility: get total creature count
function CreatureDefinitions.GetCount(): number
	local count = 0
	for _ in CreatureDefinitions do
		if typeof(CreatureDefinitions[_]) == "table" then
			count += 1
		end
	end
	return count
end

-- Utility: check if a creature ID is valid
function CreatureDefinitions.IsValid(creatureId: string): boolean
	return CreatureDefinitions[creatureId] ~= nil and typeof(CreatureDefinitions[creatureId]) == "table"
end

return CreatureDefinitions
