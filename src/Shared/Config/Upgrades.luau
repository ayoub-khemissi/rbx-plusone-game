--!strict
--[[
	Upgrades — what Coins buy.

	`effect` names the bonus family aggregated by Domain.Movement.Multipliers:
	  speedMultiplier / coinMultiplier -> additive percentages
	  jumpPower / airJumps / magnet    -> flat bonuses
	`maxLevel = 0` means unlimited.

	`jump` and `dash` are deliberately expensive and capped: they are not stats to
	grind but milestones. Each level changes which parts of a map are reachable, so
	they are events, not increments.

	Unlocking and strengthening are separate rows, for both of them. `dash` grants
	the move, `dashPower` buys how hard it hits; `jump` grants the extra jumps,
	`jumpPower` buys the height. A row that both unlocked and upgraded would read as
	neither.

	`requires` gates a row behind anything Domain.Progression.Requirements can ask:
	another upgrade, a level, a prestige count, a stage, a pass.

	Careful with `jump`: the character starts at jump level 1, so buying level 1 of
	this upgrade grants the DOUBLE jump and level 2 the triple. The interface shows
	the real jump level, never the raw upgrade level.
]]

local UpgradeCatalog = require(script.Parent.Parent.Domain.Economy.UpgradeCatalog)

type Definition = UpgradeCatalog.Definition

local definitions: { Definition } = {
	{
		id = "speedGain",
		name = "Stride",
		icon = "👟",
		image = "rbxassetid://126302401572057", -- icon:upgradeStride
		description = "+15% speed gained on every stretch run.",
		maxLevel = 0,
		baseCost = 60,
		costGrowth = 1.3,
		effectPerLevel = 0.15,
		effect = "speedMultiplier",
	},
	{
		id = "coinGain",
		name = "Fortune",
		icon = "🪙",
		image = "rbxassetid://138275604315918", -- icon:upgradeFortune
		description = "+20% Coins from everything.",
		maxLevel = 0,
		baseCost = 50,
		costGrowth = 1.32,
		effectPerLevel = 0.2,
		effect = "coinMultiplier",
	},
	{
		id = "jumpPower",
		name = "Spring",
		icon = "🦿",
		image = "rbxassetid://100238025248039", -- icon:upgradeSpring
		description = "Jump higher.",
		maxLevel = 30,
		baseCost = 200,
		costGrowth = 1.4,
		effectPerLevel = 1,
		effect = "jumpPower",
	},
	{
		id = "jump",
		name = "Air Jump",
		icon = "🪽",
		image = "rbxassetid://91996752435178", -- icon:upgradeAirJump
		description = "Double jump, then triple jump.",
		maxLevel = 2,
		baseCost = 2500,
		costGrowth = 8,
		effectPerLevel = 1,
		effect = "jumps",
	},
	{
		id = "dash",
		name = "Dash",
		icon = "💨",
		image = "rbxassetid://120516011568071", -- icon:upgradeDash
		description = "A burst forward, on a cooldown.",
		maxLevel = 1,
		baseCost = 1200,
		costGrowth = 1,
		effectPerLevel = 1,
		effect = "dash",
	},
	{
		id = "dashPower",
		name = "Dash Power",
		icon = "🚀",
		image = "rbxassetid://120516011568071", -- icon:upgradeDashPower
		description = "x2 to x6 your speed, instead of x1.",
		maxLevel = 5,
		baseCost = 2000,
		costGrowth = 3.2,
		effectPerLevel = 1,
		effect = "dashPower",
		-- Buying strength for a dash you do not have would be money for nothing.
		requires = { { kind = "upgrade", id = "dash", level = 1 } },
	},
	{
		id = "magnet",
		name = "Magnet",
		icon = "🧲",
		image = "rbxassetid://118925544856392", -- icon:upgradeMagnet
		description = "Collect Coins from further away.",
		maxLevel = 12,
		baseCost = 400,
		costGrowth = 1.6,
		effectPerLevel = 4,
		effect = "magnet",
	},
}

return table.freeze(definitions)
