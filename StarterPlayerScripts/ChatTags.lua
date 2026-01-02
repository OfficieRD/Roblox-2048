local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

-- 1. FUNCIÓN MATEMÁTICA: Obtener color exacto en un punto del degradado
local function getColorAtTime(colorSequence, t)
	if t <= 0 then return colorSequence.Keypoints[1].Value end
	if t >= 1 then return colorSequence.Keypoints[#colorSequence.Keypoints].Value end

	for i = 1, #colorSequence.Keypoints - 1 do
		local thisKey = colorSequence.Keypoints[i]
		local nextKey = colorSequence.Keypoints[i + 1]
		if t >= thisKey.Time and t < nextKey.Time then
			local alpha = (t - thisKey.Time) / (nextKey.Time - thisKey.Time)
			return thisKey.Value:Lerp(nextKey.Value, alpha)
		end
	end
	return colorSequence.Keypoints[1].Value
end

-- 2. FUNCIÓN DE FORMATO: Colorear Letra por Letra (El truco visual)
local function applyGradientToText(text, colorSequence)
	local result = ""
	local length = #text

	for i = 1, length do
		-- Calcular posición (0 a 1) para esta letra
		local step = (i - 1) / math.max(1, length - 1)
		local charColor = getColorAtTime(colorSequence, step)
		local hex = charColor:ToHex()

		-- Envolver letra en etiqueta de color
		local char = string.sub(text, i, i)
		result = result .. string.format("<font color='#%s'>%s</font>", hex, char)
	end
	return result
end

local function getTitleData(name)
	if not GameData.TITLES_DATA then return nil end
	for _, d in pairs(GameData.TITLES_DATA) do
		if d.Name == name then return d end
	end
	return nil
end

-- 3. CONECTAR AL CHAT
TextChatService.OnIncomingMessage = function(message)
	if not message.TextSource then return end

	local player = Players:GetPlayerByUserId(message.TextSource.UserId)
	if not player then return end

	local equippedTitle = player:GetAttribute("EquippedTitle")

	if equippedTitle then
		local data = getTitleData(equippedTitle)

		if data then
			local titleText = ""

			-- ¿Tiene degradado? Usamos la función letra por letra
			if data.Gradient then
				local gradientText = applyGradientToText(equippedTitle, data.Gradient)
				titleText = string.format("[%s]", gradientText)
			else
				-- Si no tiene degradado, color plano (Fallback)
				local hex = data.Color and data.Color:ToHex() or "FFFFFF"
				titleText = string.format("<font color='#%s'>[%s]</font>", hex, equippedTitle)
			end

			-- Aplicar al chat
			message.PrefixText = titleText .. " " .. message.PrefixText
		end
	end
end