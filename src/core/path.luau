--!nocheck
-- An instance's path as Luau that finds it again, the way Dex's "Copy path" writes it.

local Path = {}

local KEYWORDS = {}
for _, word in string.split(
	"and break do else elseif end false for function if in local nil not or repeat return then true until while continue export type",
	" "
) do
	KEYWORDS[word] = true
end

function Path.index(name: string): string
	if string.match(name, "^[%a_][%w_]*$") and not KEYWORDS[name] then
		return "." .. name
	end
	return `[{string.format("%q", name)}]`
end

-- `game` is the DataModel; `localPlayer` shortens paths through the local player.
function Path.of(instance: Instance, game: Instance, localPlayer: Instance?): string
	if instance == game then
		return "game"
	end
	local parts = {}
	local current = instance
	while current do
		if current == localPlayer then
			table.insert(parts, 1, 'game:GetService("Players").LocalPlayer')
			return table.concat(parts)
		end
		local parent = current.Parent
		if parent == game then
			local ok, service = pcall(game.FindService, game, current.ClassName)
			if ok and service == current then
				table.insert(parts, 1, `game:GetService("{current.ClassName}")`)
			else
				table.insert(parts, 1, "game" .. Path.index(current.Name))
			end
			return table.concat(parts)
		elseif parent == nil then
			-- Parented to nil: find it again through getnilinstances.
			table.insert(
				parts,
				1,
				string.format(
					"(function() for _, v in getnilinstances() do if v.Name == %q and v.ClassName == %q then return v end end end)()",
					current.Name,
					current.ClassName
				)
			)
			return table.concat(parts)
		end
		table.insert(parts, 1, Path.index(current.Name))
		current = parent
	end
	return table.concat(parts)
end

-- Ancestors from the top down, for the breadcrumb.
function Path.chain(instance: Instance, game: Instance): { Instance }
	local chain = {}
	local current = instance
	while current and current ~= game do
		table.insert(chain, 1, current)
		current = current.Parent
	end
	return chain
end

return table.freeze(Path)
