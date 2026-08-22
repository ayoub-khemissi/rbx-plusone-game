--!strict
--[[ Format — mise en forme des nombres pour l'interface (aucune dependance Roblox). ]]

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local Format = {}

local function trimZeros(text: string): string
	if not string.find(text, ".", 1, true) then
		return text
	end
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return text
end

--[[ 1500 -> "1.5K", 1250000 -> "1.25M" ]]
function Format.abbreviate(value: number): string
	if typeof(value) ~= "number" or value ~= value then
		return "0"
	end

	local sign = if value < 0 then "-" else ""
	local magnitude = math.abs(value)

	if magnitude < 1000 then
		return sign .. tostring(math.floor(magnitude))
	end

	-- Division iterative plutot que math.log : pas d'erreur d'arrondi aux puissances exactes.
	local tier = 0
	local scaled = magnitude
	while scaled >= 1000 and tier < #SUFFIXES - 1 do
		scaled /= 1000
		tier += 1
	end

	return sign .. trimZeros(string.format("%.2f", scaled)) .. SUFFIXES[tier + 1]
end

--[[ 0.25 -> "25%" ]]
function Format.percent(ratio: number): string
	return string.format("%d%%", math.round(ratio * 100))
end

--[[ 1.35 -> "x1.35" ]]
function Format.multiplier(value: number): string
	return "x" .. trimZeros(string.format("%.2f", value))
end

--[[ 92 -> "1m 32s" ]]
function Format.duration(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	local hours = total // 3600
	local minutes = (total % 3600) // 60
	if hours > 0 then
		return `{hours}h {minutes}m`
	end
	return `{minutes}m {total % 60}s`
end

return Format
