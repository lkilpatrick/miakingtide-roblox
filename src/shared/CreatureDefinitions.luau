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
	seahorse = {
		Id = "seahorse",
		Name = "Seahorse",
		Description = "A delicate seahorse drifting among the pier pylons.",
		HabitatHint = "Peek around the old pier pylons...",
		UnlockFact = "Seahorses are the only animals where the male gives birth to babies!",
		HabitatZone = "Pier",
	},
	redoctopus = {
		Id = "redoctopus",
		Name = "Red Octopus",
		Description = "A clever red octopus hiding in a rocky crevice.",
		HabitatHint = "Search the dark rocky crevice near the cave...",
		UnlockFact = "The Red Octopus can change color in less than a second to blend in!",
		HabitatZone = "RockyCrevice",
	},
	treefish = {
		Id = "treefish",
		Name = "Treefish",
		Description = "A bold yellow-and-black striped fish resting on the sandy bottom.",
		HabitatHint = "Scan the sandy bottom of the shallow bay...",
		UnlockFact = "Treefish can live for over 20 years and rarely stray far from their home rock!",
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
