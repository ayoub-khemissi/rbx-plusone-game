--!nocheck
local BoostStack = require(Domain.Monetization.BoostStack)
local PurchaseLedger = require(Domain.Monetization.PurchaseLedger)
local ProductCatalog = require(Domain.Monetization.ProductCatalog)
local Grants = require(Domain.Monetization.Grants)
local RewardSchedule = require(Domain.Monetization.RewardSchedule)
local IntervalReward = require(Domain.Monetization.IntervalReward)
local PromoCodes = require(Domain.Monetization.PromoCodes)
local OfferEngine = require(Domain.Monetization.OfferEngine)
local Profile = require(Domain.Profile.Profile)

local HOUR = 3600
local DAY = 86400

describe("BoostStack", function()
	local stack, profile
	beforeEach(function()
		stack = BoostStack.new({
			definitions = {
				swiftRush = { name = "Ruee", speed = 2 },
				coinsFever = { name = "Fievre", coins = 3 },
				serverParty = { name = "Fete", speed = 1.5, coins = 1.5 },
			},
			maxStackedDuration = 4 * HOUR,
		})
		profile = Profile.create()
	end)

	it("activates a boost for a given duration", function()
		stack:grant(profile, "swiftRush", 900, 1000)
		expect(stack:isActive(profile, "swiftRush", 1500)).toBe(true)
		expect(stack:remainingFor(profile, "swiftRush", 1500)).toBe(400)
	end)

	it("expires cleanly", function()
		stack:grant(profile, "swiftRush", 900, 1000)
		expect(stack:isActive(profile, "swiftRush", 1901)).toBe(false)
		expect(stack:remainingFor(profile, "swiftRush", 1901)).toBe(0)
	end)

	it("stacks repeat purchases of the same boost", function()
		stack:grant(profile, "swiftRush", 900, 1000)
		stack:grant(profile, "swiftRush", 900, 1200)
		-- 700 s were left, adding 900 s gives 1600 s
		expect(stack:remainingFor(profile, "swiftRush", 1200)).toBe(1600)
	end)

	it("caps the stack so boosts never become permanent", function()
		for _ = 1, 20 do
			stack:grant(profile, "swiftRush", HOUR, 0)
		end
		expect(stack:remainingFor(profile, "swiftRush", 0)).toBe(4 * HOUR)
	end)

	it("ignores an unknown boost", function()
		local granted = stack:grant(profile, "inconnu", 900, 0)
		expect(granted).toBe(false)
		expect(profile.boosts.inconnu).toBeNil()
	end)

	it("combines the multipliers of active boosts", function()
		stack:grant(profile, "swiftRush", 900, 0)
		stack:grant(profile, "coinsFever", 900, 0)
		local bonuses = stack:multipliersFor(profile, 100)
		expect(bonuses.speed).toBe(2)
		expect(bonuses.coins).toBe(3)
	end)

	it("multiplies overlapping boosts together", function()
		stack:grant(profile, "swiftRush", 900, 0)
		stack:grant(profile, "serverParty", 900, 0)
		expect(stack:multipliersFor(profile, 100).speed).toBe(3)
	end)

	it("falls back to 1 with no boost running", function()
		local bonuses = stack:multipliersFor(profile, 0)
		expect(bonuses.speed).toBe(1)
		expect(bonuses.coins).toBe(1)
	end)

	it("prunes expired boosts from the profile", function()
		stack:grant(profile, "swiftRush", 10, 0)
		stack:prune(profile, 999)
		expect(profile.boosts.swiftRush).toBeNil()
	end)

	it("lists active boosts for the interface", function()
		stack:grant(profile, "swiftRush", 900, 0)
		local active = stack:activeFor(profile, 100)
		expect(#active).toBe(1)
		expect(active[1].id).toBe("swiftRush")
		expect(active[1].name).toBe("Ruee")
		expect(active[1].remaining).toBe(800)
	end)
end)

describe("PurchaseLedger", function()
	local profile
	beforeEach(function()
		profile = Profile.create()
	end)

	it("knows no purchase at first", function()
		expect(PurchaseLedger.hasProcessed(profile, "r-1")).toBe(false)
	end)

	it("records a purchase exactly once", function()
		expect(
			PurchaseLedger.record(profile, { purchaseId = "r-1", productId = "coinBag", robux = 99, at = 10 })
		).toBe(true)
		expect(PurchaseLedger.hasProcessed(profile, "r-1")).toBe(true)
		expect(
			PurchaseLedger.record(profile, { purchaseId = "r-1", productId = "coinBag", robux = 99, at = 20 })
		).toBe(false)
	end)

	it("totals the robux spent and the purchase count", function()
		PurchaseLedger.record(profile, { purchaseId = "r-1", productId = "a", robux = 99, at = 1 })
		PurchaseLedger.record(profile, { purchaseId = "r-2", productId = "b", robux = 199, at = 2 })
		expect(profile.purchases.count).toBe(2)
		expect(profile.purchases.spentRobux).toBe(298)
	end)

	it("bounds the history so the save cannot grow forever", function()
		for index = 1, PurchaseLedger.MAX_HISTORY + 25 do
			PurchaseLedger.record(
				profile,
				{ purchaseId = `r-{index}`, productId = "a", robux = 1, at = index }
			)
		end
		expect(#profile.purchases.order).toBe(PurchaseLedger.MAX_HISTORY)
		-- the oldest fall out of the history, recent ones stay protected
		expect(PurchaseLedger.hasProcessed(profile, "r-1")).toBe(false)
		expect(PurchaseLedger.hasProcessed(profile, `r-{PurchaseLedger.MAX_HISTORY + 25}`)).toBe(true)
	end)
end)

describe("ProductCatalog", function()
	local catalog
	beforeEach(function()
		catalog = ProductCatalog.new({
			{
				id = "coinBag",
				productId = 111,
				name = "Sac de bananes",
				robux = 99,
				grant = { coins = 5000 },
			},
			{
				id = "swiftRush",
				productId = 222,
				name = "Ruee",
				robux = 199,
				grant = { boost = { id = "swiftRush", duration = 1200 } },
			},
			{ id = "desactive", productId = 0, name = "Non configure", robux = 0, grant = { coins = 1 } },
		})
	end)

	it("finds a product by its business id", function()
		expect(catalog:get("coinBag").name).toBe("Sac de bananes")
	end)

	it("finds a product by its Roblox id", function()
		expect(catalog:byProductId(222).id).toBe("swiftRush")
		expect(catalog:byProductId(999)).toBeNil()
	end)

	it("ignores unconfigured products (productId = 0)", function()
		expect(catalog:byProductId(0)).toBeNil()
		expect(catalog:isConfigured("desactive")).toBe(false)
		expect(catalog:isConfigured("coinBag")).toBe(true)
	end)

	it("lists sellable products only", function()
		local sellable = catalog:sellable()
		expect(#sellable).toBe(2)
	end)
end)

describe("Grants", function()
	local context, stack
	beforeEach(function()
		stack = BoostStack.new({ definitions = { swiftRush = { speed = 2 } }, maxStackedDuration = HOUR })
		context = { profile = Profile.create(), boosts = stack, now = 100 }
	end)

	it("credits coins", function()
		local summary = Grants.apply({ coins = 5000 }, context)
		expect(context.profile.coins).toBe(5000)
		expect(summary.coins).toBe(5000)
	end)

	it("credits speed", function()
		Grants.apply({ speed = 250 }, context)
		expect(context.profile.speed).toBe(250)
	end)

	it("activates a boost", function()
		Grants.apply({ boost = { id = "swiftRush", duration = 600 } }, context)
		expect(stack:isActive(context.profile, "swiftRush", 200)).toBe(true)
	end)

	--[[
		Income and shop prices are both multiplied by every rebirth taken, so a fixed
		amount buys a shop row on day one and nothing at all two worlds later. The
		price on the product never changes; what it buys must not either.
	]]
	it("pays a grant in the money of the day", function()
		context.prestigePolicy = {
			multiplierFor = function(_self, taken)
				return 2 ^ taken
			end,
		}
		context.profile.prestiges = 3

		local summary = Grants.apply({ coins = 5000, speed = 250 }, context)

		expect(summary.coins).toBe(40000)
		expect(context.profile.speed).toBe(2000)
	end)

	-- A player who has never rebirthed pays and receives exactly what is written.
	it("quotes the amount at the first rebirth", function()
		context.prestigePolicy = {
			multiplierFor = function()
				return 1
			end,
		}
		expect(Grants.apply({ coins = 5000 }, context).coins).toBe(5000)
	end)

	it("grants an instant molt without the speed requirement", function()
		context.profile.speed = 10
		context.prestigePolicy = {
			multiplierFor = function(_self, n)
				return 1 + n
			end,
		}
		local summary = Grants.apply({ prestiges = 1 }, context)
		expect(context.profile.prestiges).toBe(1)
		expect(context.profile.speed).toBe(0)
		expect(summary.prestiges).toBe(1)
	end)

	it("combines several rewards", function()
		local summary = Grants.apply({ coins = 100, speed = 10 }, context)
		expect(summary.coins).toBe(100)
		expect(summary.speed).toBe(10)
	end)

	it("ignores an empty reward", function()
		expect(Grants.apply(nil, context)).toEqual({})
	end)
end)

describe("RewardSchedule (daily reward)", function()
	local schedule, profile
	beforeEach(function()
		schedule = RewardSchedule.new({
			dayLength = DAY,
			graceWindow = 2 * DAY,
			rewards = {
				{ day = 1, grant = { coins = 100 } },
				{ day = 2, grant = { coins = 250 } },
				{ day = 3, grant = { boost = { id = "swiftRush", duration = 600 } } },
			},
		})
		profile = Profile.create()
	end)

	it("is claimable on the very first login", function()
		local status = schedule:statusFor(profile, 0)
		expect(status.claimable).toBe(true)
		expect(status.day).toBe(1)
	end)

	it("grants the day reward and starts the streak", function()
		local result = schedule:claim(profile, 1000)
		expect(result.ok).toBe(true)
		expect(result.value.day).toBe(1)
		expect(profile.daily.streak).toBe(1)
		expect(profile.daily.lastClaimAt).toBe(1000)
	end)

	it("refuses a second claim on the same day", function()
		schedule:claim(profile, 1000)
		local result = schedule:claim(profile, 1000 + HOUR)
		expect(result.ok).toBe(false)
		expect(result.code).toBe("ALREADY_CLAIMED")
		expect(result.value.secondsRemaining).toBe(DAY - HOUR)
	end)

	it("grows the streak the next day", function()
		schedule:claim(profile, 0)
		local result = schedule:claim(profile, DAY + 60)
		expect(result.ok).toBe(true)
		expect(profile.daily.streak).toBe(2)
		expect(result.value.day).toBe(2)
	end)

	it("resets the streak after a long absence", function()
		schedule:claim(profile, 0)
		schedule:claim(profile, 3 * DAY)
		expect(profile.daily.streak).toBe(1)
	end)

	it("loops back to day one once the cycle ends", function()
		profile.daily.streak = 3
		profile.daily.lastClaimAt = 0
		local result = schedule:claim(profile, DAY + 1)
		expect(result.value.day).toBe(1)
		expect(profile.daily.streak).toBe(4)
	end)
end)

describe("IntervalReward (session chest)", function()
	local chest, profile
	beforeEach(function()
		chest = IntervalReward.new({ interval = 300, grant = { coins = 50 } })
		profile = Profile.create()
	end)

	it("is not claimable before the interval", function()
		local status = chest:statusFor(profile, "playtimeChest", 0)
		expect(status.claimable).toBe(false)
		expect(status.secondsRemaining).toBe(300)
	end)

	it("becomes claimable after the interval", function()
		expect(chest:statusFor(profile, "playtimeChest", 300).claimable).toBe(true)
	end)

	it("restarts the timer once claimed", function()
		local result = chest:claim(profile, "playtimeChest", 400)
		expect(result.ok).toBe(true)
		expect(result.value.grant.coins).toBe(50)
		expect(chest:statusFor(profile, "playtimeChest", 400).claimable).toBe(false)
	end)

	it("refuses an early claim", function()
		chest:claim(profile, "playtimeChest", 400)
		local result = chest:claim(profile, "playtimeChest", 500)
		expect(result.code).toBe("NOT_READY")
	end)
end)

describe("PromoCodes", function()
	local codes, profile
	beforeEach(function()
		codes = PromoCodes.new({
			{ code = "SINGE2026", grant = { coins = 500 } },
			{ code = "EXPIRE", grant = { coins = 100 }, expiresAt = 50 },
		})
		profile = Profile.create()
	end)

	it("accepts a valid code, whatever the case", function()
		local result = codes:redeem(profile, "singe2026", 10)
		expect(result.ok).toBe(true)
		expect(result.value.grant.coins).toBe(500)
	end)

	it("refuses an already redeemed code", function()
		codes:redeem(profile, "SINGE2026", 10)
		local result = codes:redeem(profile, "SINGE2026", 20)
		expect(result.code).toBe("ALREADY_REDEEMED")
	end)

	it("refuses an unknown code", function()
		expect(codes:redeem(profile, "n'importe quoi", 10).code).toBe("UNKNOWN_CODE")
	end)

	it("refuses an expired code", function()
		expect(codes:redeem(profile, "EXPIRE", 100).code).toBe("EXPIRED")
	end)

	it("lets a repeatable code be redeemed again and again", function()
		codes = PromoCodes.new({ { code = "AGAIN", grant = { coins = 25 }, repeatable = true } })
		expect(codes:redeem(profile, "AGAIN", 10).ok).toBe(true)
		expect(codes:redeem(profile, "AGAIN", 20).ok).toBe(true)
		expect(codes:redeem(profile, "AGAIN", 30).value.grant.coins).toBe(25)
	end)

	-- Recording it would grow the profile for nothing, and a code turned repeatable
	-- later would stay blocked for everyone who had already used it once.
	it("does not record a repeatable code against the profile", function()
		codes = PromoCodes.new({ { code = "AGAIN", grant = { coins = 25 }, repeatable = true } })
		codes:redeem(profile, "AGAIN", 10)
		expect(profile.codes.AGAIN).toBeNil()
	end)
end)

describe("OfferEngine", function()
	local engine, profile
	beforeEach(function()
		engine = OfferEngine.new({
			{
				id = "starterPack",
				productKey = "starterPack",
				triggerAfterSeconds = 180,
				durationSeconds = 900,
				oncePerProfile = true,
			},
			{
				id = "gateBooster",
				productKey = "swiftRush",
				trigger = "zoneBlocked",
				durationSeconds = 600,
			},
		})
		profile = Profile.create()
	end)

	it("hides the welcome offer before its trigger", function()
		expect(#engine:visibleFor(profile, { playtime = 60, now = 60 })).toBe(0)
	end)

	it("triggers the welcome offer after enough playtime", function()
		local offers = engine:visibleFor(profile, { playtime = 200, now = 200 })
		expect(#offers).toBe(1)
		expect(offers[1].id).toBe("starterPack")
		expect(offers[1].secondsRemaining).toBe(900)
	end)

	it("expires the offer once its window closes", function()
		engine:visibleFor(profile, { playtime = 200, now = 200 })
		expect(#engine:visibleFor(profile, { playtime = 1200, now = 1200 })).toBe(0)
	end)

	it("never shows a one-shot offer twice", function()
		engine:markPurchased(profile, "starterPack")
		expect(#engine:visibleFor(profile, { playtime = 200, now = 200 })).toBe(0)
	end)

	it("triggers a contextual offer on an event", function()
		engine:trigger(profile, "zoneBlocked", 500)
		local offers = engine:visibleFor(profile, { playtime = 500, now = 700 })
		expect(#offers).toBe(1)
		expect(offers[1].id).toBe("gateBooster")
		expect(offers[1].secondsRemaining).toBe(400)
	end)
end)
