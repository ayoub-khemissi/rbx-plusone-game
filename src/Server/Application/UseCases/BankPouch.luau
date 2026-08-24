--!strict
--[[
	BankPouch — touching an Altar: the pouch becomes the player's.

	The save is fired immediately. A banked pouch that a server restart could erase
	would be worse than no bank at all: the whole loop rests on the player trusting
	that cashing out is final.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Pouch = require(Shared.Domain.Run.Pouch)
local Format = require(Shared.Domain.Support.Format)

local BankPouch = {}
BankPouch.__index = BankPouch

function BankPouch.new(dependencies)
	return setmetatable(table.clone(dependencies), BankPouch)
end

function BankPouch.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	if not session.flying or not session.pouch then
		return Result.err("NOT_FLYING", "No flight to bank")
	end
	if session.pouch.tierId == 0 then
		return Result.err("EMPTY_POUCH", "Reach a tier before banking")
	end

	local profile = session.profile
	local loot = self.ladder:lootOf(session.pouch.tierId)
	local payload = Pouch.bank(session.pouch, profile)

	-- The x2 Eggs pass doubles what an Altar hands over.
	local eggMultiplier = if session.passes.doubleEggs then 2 else 1
	local eggs = self.eggRoller:grant(profile, loot, eggMultiplier)

	self.sessions:endFlight(session)
	self.teleporter:sendTo(player, self.nestPoint)
	self.publisher:publish(player, self.snapshots:build(session))
	self.notifier:notify(
		player,
		`Banked: +{Format.abbreviate(payload.gold)} gold and {payload.eggs * eggMultiplier} eggs.`,
		"success"
	)

	self.save:run(session.userId)

	return Result.ok({ payload = payload, eggs = eggs })
end

return BankPouch
