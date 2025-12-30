local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

print("?? Script de Chat (Estilo Bubblegum) CARGADO")

-- CONFIGURACIÓN DE ESTILOS
-- ColorTitle: El color de las letras del rango
-- ColorBracket: El color de los corchetes [ ] (Opcional, si quieres que sean distintos)
local TITLE_STYLES = {
	["Novice"] = {Color = "#A0A0A0", Text = "Novice"},
	["Pro"]    = {Color = "#00AAFF", Text = "Pro"},
	["Master"] = {Color = "#BF00FF", Text = "Master"},
	["Legend"] = {Color = "#FF9900", Text = "Legend"},
	["Hacker"] = {Color = "#00FF00", Text = "Hacker"},
	["VIP"]    = {Color = "#FFD700", Text = "VIP"},

	-- TÍTULOS DE FRUTAS
	["Tutti Frutti ??"] = {Color = "#FF69B4", Text = "Tutti Frutti ??"},
	["Apple Crisp ??"]  = {Color = "#FF4040", Text = "Apple Crisp ??"},
	["Golden Orchard ??"] = {Color = "#FFD700", Text = "Golden Orchard ??"},

	-- SEASON 1: HIGH SCORE
	["S1 #1 Score ??"]   = {Color = "#FFD700", Text = "S1 #1 Score ??"}, -- Oro
	["S1 #2 Score ??"]   = {Color = "#C0C0C0", Text = "S1 #2 Score ??"}, -- Plata
	["S1 #3 Score ??"]   = {Color = "#CD7F32", Text = "S1 #3 Score ??"}, -- Bronce
	["S1 Top 10 Score"]  = {Color = "#A020F0", Text = "S1 Top 10 Score"}, -- Violeta
	["S1 Top 100 Score"] = {Color = "#0064FF", Text = "S1 Top 100 Score"}, -- Azul Fuerte


}

TextChatService.OnIncomingMessage = function(message)
	local props = Instance.new("TextChatMessageProperties")

	if message.TextSource then
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)

		if player then
			-- 1. Obtener el título guardado
			local titleKey = player:GetAttribute("EquippedTitle")

			-- 2. Verificar si tenemos estilo para ese título
			if titleKey and TITLE_STYLES[titleKey] then
				local style = TITLE_STYLES[titleKey]

				-- 3. CREAR EL TAG ESTILO BUBBLEGUM
				-- Formato: [Titulo] (en Negrita y Color)
				-- <b> pone el texto grueso. <font color> le da color.
				local tagFormat = string.format(
					"<font color='%s'><b>[%s]</b></font> ", 
					style.Color, 
					style.Text
				)

				-- Añadimos el tag antes del nombre
				props.PrefixText = tagFormat .. message.PrefixText
			end
		end
	end

	return props
end