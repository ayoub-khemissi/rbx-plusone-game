--!nocheck
-- Verifie que le harness reproduit bien la semantique Roblox attendue.

describe("harness", function()
	it("expose ReplicatedStorage.Shared", function()
		expect(Shared.Name).toBe("Shared")
		expect(Shared.Parent.Name).toBe("ReplicatedStorage")
	end)

	it("resout les chemins comme dans Roblox", function()
		expect(Shared:GetFullName()).toContain("ReplicatedStorage.Shared")
	end)
end)
