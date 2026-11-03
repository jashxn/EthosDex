-- Lex with Highlighter, then apply the symbol categories used by Luau's VS Code grammar.
-- See assets/vendor/catppuccin/README.md for the pinned scope and color sources.
local Lexer = require(script.Parent.Parent.packages.luauLexer)

export type Token = { Kind: string, Text: string }

local PUNCTUATION = {
	["("] = true,
	[")"] = true,
	["["] = true,
	["]"] = true,
	["{"] = true,
	["}"] = true,
	[","] = true,
	[";"] = true,
}

local function classify(tokens)
	local depth, angles = 0, 0
	local functionHead = false
	local parameterDepth = nil
	local parameterExpected = false
	local braces = 0

	for index, token in tokens do
		local word, kind = token.Value, token.Kind
		local before = tokens[index - 1]
		local after = tokens[index + 1]
		local previous = if before then before.Value else ""
		local following = if after then after.Value else ""

		if kind == "keyword" then
			if word == "function" then
				functionHead = true
			elseif word == "true" or word == "false" or word == "nil" then
				token.Kind = "constant"
			elseif word == "self" then
				token.Kind = "self"
			elseif (word == "type" or word == "typeof") and following == "(" then
				token.Kind = "function"
			end
		elseif kind == "operator" then
			if word == "(" or word == "[" or word == "{" then
				depth += 1
				if word == "(" and functionHead and angles == 0 then
					parameterDepth = depth
					parameterExpected = true
					functionHead = false
				end
				braces += if word == "{" then 1 else 0
			elseif word == ")" or word == "]" or word == "}" then
				if word == ")" and depth == parameterDepth then
					parameterDepth = nil
				end
				depth -= 1
				braces -= if word == "}" then 1 else 0
			elseif word == "<" and (functionHead or parameterDepth ~= nil) then
				angles += 1
			elseif word == ">" and angles > 0 then
				angles -= 1
			elseif word == "," and depth == parameterDepth and angles == 0 then
				parameterExpected = true
			elseif word == "..." and parameterExpected and depth == parameterDepth then
				token.Kind = "parameter"
				parameterExpected = false
			end
			if PUNCTUATION[word] then
				token.Kind = "punctuation"
			end
		elseif kind == "iden" or kind == "builtin" or kind == "type" then
			if parameterExpected and depth == parameterDepth and angles == 0 then
				token.Kind = "parameter"
				parameterExpected = false
				continue
			end
			if braces > 0
				and (previous == "{" or previous == ",")
				and (following == "=" or following == ":") then
				token.Kind = "property"
				continue
			end
			if kind == "type" or (functionHead and angles > 0) then
				token.Kind = "type"
				continue
			end
			if following == "("
				or following == "{"
				or (after and after.Kind == "string")
				or (functionHead and angles == 0 and following == "<")
				or (following == "<" and tokens[index + 2] and tokens[index + 2].Value == "<") then
				token.Kind = "function"
				continue
			end
			if previous == "." or previous == ":" then
				token.Kind = "property"
				continue
			end
			if string.match(word, "^[A-Z_][A-Z0-9_]*$") then
				token.Kind = "constant"
				continue
			end
			if kind == "builtin"
				and Lexer.language.builtin[word] == "table"
				and string.match(word, "^[A-Z]") then
				token.Kind = "type"
			end
		end
	end
end

local function luauHighlight(source: string): { { Token } }
	local tokens, significant = {}, {}
	Lexer.scanEach(
		source,
		function(kind, content)
			local token = {
				Kind = kind,
				Text = content,
				Value = string.match(content, "^%s*(.-)%s*$"),
			}
			table.insert(tokens, token)
			if kind ~= "comment" and token.Value ~= "" then
				table.insert(significant, token)
			end
		end
	)
	classify(significant)

	-- Split only after classifying so calls, comments, strings and signatures span lines.
	local lines: { { Token } } = { {} }
	for _, token in tokens do
		for index, text in string.split(token.Text, "\n") do
			if index > 1 then
				table.insert(lines, {})
			end
			if text ~= "" then
				table.insert(lines[#lines], { Kind = token.Kind, Text = text })
			end
		end
	end
	return lines
end

return luauHighlight
