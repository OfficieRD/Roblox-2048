local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 1. Esperamos a que el "buzón" exista (Ya comprobamos que sí existe)
local equipEvent = ReplicatedStorage:WaitForChild("EquipTitle")

print("?? SERVER: Script de Chat Cargado y Esperando...")

-- 2. Escuchamos cuando el cliente manda el mensaje
equipEvent.OnServerEvent:Connect(function(player, titleName)
	print("?? SERVER: Recibido título '" .. tostring(titleName) .. "' de " .. player.Name)

	-- Guardamos el título en el jugador (Atributo)
	player:SetAttribute("EquippedTitle", titleName)

	-- Feedback en consola para confirmar
	print("? TÍTULO EQUIPADO Y LISTO PARA GUARDAR: " .. tostring(titleName))
end)