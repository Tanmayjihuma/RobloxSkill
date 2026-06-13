-- help to format number 
-- to use MyLabel.Text = NumberUtils.Abbreviate(15000) -- Output: "15k"

local NumberUtils = {}

local SUFFIXES = {"k", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "Oc", "No"}

function NumberUtils.Abbreviate(n)
	n = tonumber(n)
	if not n then return "0" end

	local sign = n < 0 and "-" or ""
	n = math.abs(n)

	if n < 1000 then 
		return sign .. tostring(math.floor(n)) 
	end

	local index = 0
	while n >= 1000 and index < #SUFFIXES do
		n = n / 1000
		index += 1
	end

	local formatted = string.format("%.1f", n)

	formatted = formatted:gsub("%.0$", "")

	return sign .. formatted .. SUFFIXES[index]
end

return NumberUtils
