local _, Private = ...
local LRS = Private.Addon

function LRS:SlashCommand(msg)
	msg = msg:lower()
	local args = {}
	for arg in msg:gmatch("%S+") do
		table.insert(args, arg)
	end
	if args[1] == "anchor" or args[1] == "a" then
		self:ToggleAnchor()
	elseif args[1] == "settings" or args[1] == "s" or args[1] == nil then
		self:ToggleSettings()
	end
end
