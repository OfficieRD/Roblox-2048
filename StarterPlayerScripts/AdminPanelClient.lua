local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Verificamos si existe el evento
local AdminEvent = ReplicatedStorage:WaitForChild("AdminAction", 5)
if not AdminEvent then
	warn("🔴 ERROR CRÍTICO: No se encontró el RemoteEvent 'AdminAction'")
	return
end

print("🔵 SCRIPT ADMIN CLIENTE: Iniciado para " .. player.Name)

-- LISTA DE ADMINS (Asegúrate de estar aquí)
local ADMINS = {
	["OFFICIE_ROBLOX"] = true,
}

-- --- CREACIÓN DE UI (REWORK PREMIUM) ---
if playerGui:FindFirstChild("AdminPanelUI") then playerGui.AdminPanelUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdminPanelUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10000
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = playerGui

-- 1. MARCO PRINCIPAL (DASHBOARD)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Panel"
MainFrame.Size = UDim2.new(0, 450, 0, 650) -- Un poco más alto para que quepa todo
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui


-- Estilo del Marco
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Thickness = 3; MainStroke.Color = Color3.fromRGB(80, 80, 100)
local MainGrad = Instance.new("UIGradient", MainFrame); MainGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(40,40,50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20,20,25))}; MainGrad.Rotation = 45

-- Sombra
local Shadow = Instance.new("ImageLabel", MainFrame)
Shadow.AnchorPoint = Vector2.new(0.5, 0.5); Shadow.Position = UDim2.new(0.5,0,0.5,0); Shadow.Size = UDim2.new(1, 60, 1, 60); Shadow.BackgroundTransparency = 1; Shadow.Image = "rbxassetid://6015897843"; Shadow.ImageColor3 = Color3.new(0, 0, 0); Shadow.ImageTransparency = 0.4; Shadow.ZIndex = -1

-- 2. HEADER
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0.1, 0); Header.BackgroundTransparency = 1
local TitleText = Instance.new("TextLabel", Header); TitleText.Text = "COMMAND CENTER 🛡️"; TitleText.Size = UDim2.new(1, -20, 1, 0); TitleText.Position = UDim2.new(0, 20, 0, 0); TitleText.BackgroundTransparency = 1; TitleText.TextColor3 = Color3.new(1,1,1); TitleText.Font = Enum.Font.FredokaOne; TitleText.TextSize = 26; TitleText.TextXAlignment = Enum.TextXAlignment.Left
local CloseHint = Instance.new("TextLabel", Header); CloseHint.Text = "[F2] to Close"; CloseHint.Size = UDim2.new(0.3, 0, 1, 0); CloseHint.Position = UDim2.new(0.7, 0, 0, 0); CloseHint.BackgroundTransparency = 1; CloseHint.TextColor3 = Color3.fromRGB(150,150,150); CloseHint.Font = Enum.Font.GothamBold; CloseHint.TextSize = 14

-- 3. CONTENEDOR SCROLL
local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(0.92, 0, 0.86, 0); Container.Position = UDim2.new(0.04, 0, 0.12, 0); Container.BackgroundTransparency = 1; Container.BorderSizePixel = 0; Container.ScrollBarThickness = 6; Container.AutomaticCanvasSize = Enum.AutomaticSize.Y; Container.CanvasSize = UDim2.new(0,0,0,0)
local Layout = Instance.new("UIListLayout", Container); Layout.Padding = UDim.new(0, 12); Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; Layout.SortOrder = Enum.SortOrder.LayoutOrder
local Pad = Instance.new("UIPadding", Container); Pad.PaddingBottom = UDim.new(0, 20); Pad.PaddingTop = UDim.new(0, 10)

-- FUNCIONES HELPER (ESTILO NUEVO)
local function createLabel(text, order)
	local l = Instance.new("TextLabel", Container); l.Text = text; l.Size = UDim2.new(1, 0, 0, 20); l.BackgroundTransparency = 1; l.TextColor3 = Color3.fromRGB(100, 200, 255); l.Font = Enum.Font.GothamBlack; l.TextSize = 14; l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = order
	return l
end

local function createInput(ph, order)
	local b = Instance.new("TextBox", Container); b.PlaceholderText = ph; b.Text = ""; b.Size = UDim2.new(1, 0, 0, 45); b.BackgroundColor3 = Color3.fromRGB(50, 50, 60); b.TextColor3 = Color3.new(1,1,1); b.PlaceholderColor3 = Color3.fromRGB(150,150,160); b.Font = Enum.Font.GothamBold; b.TextSize = 16; b.LayoutOrder = order
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10); Instance.new("UIStroke", b).Color = Color3.fromRGB(80,80,100); Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 10)
	return b
end

local function createBtn(text, color, order, callback)
	local b = Instance.new("TextButton", Container); b.Text = text; b.Size = UDim2.new(1, 0, 0, 50); b.BackgroundColor3 = color; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.FredokaOne; b.TextSize = 20; b.LayoutOrder = order; b.AutoButtonColor = true
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)

	-- Efecto Brillo
	local g = Instance.new("UIGradient", b); g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200,200,200))}

	b.MouseButton1Click:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.1), {Size = UDim2.new(0.95, 0, 0, 45)}):Play()
		task.wait(0.1)
		TweenService:Create(b, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 50)}):Play()
		if callback then
			callback()
		end
	end)
end

-- === SECCIONES DEL PANEL ===

createLabel("1. TARGET (Leave empty for Self)", 1)
local TargetBox = createInput("Username...", 2)

createLabel("2. AMOUNT / VALUE", 3)
local AmountBox = createInput("1000", 4)

createLabel("3. ACTIONS", 5)

createBtn("ADD COINS 🟡", Color3.fromRGB(255, 180, 0), 6, function()
	AdminEvent:FireServer("AddCoins", TargetBox.Text, AmountBox.Text)
end)

-- NUEVO BOTÓN DE DIAMANTES
createBtn("ADD DIAMONDS 💎", Color3.fromRGB(0, 180, 255), 7, function()
	AdminEvent:FireServer("AddDiamonds", TargetBox.Text, AmountBox.Text)
end)

createBtn("ADD FRUIT GEMS 🍓", Color3.fromRGB(255, 80, 100), 8, function()
	AdminEvent:FireServer("AddFruits", TargetBox.Text, AmountBox.Text)
end)

createBtn("SET LEVEL 🆙", Color3.fromRGB(80, 220, 100), 9, function()
	AdminEvent:FireServer("SetLevel", TargetBox.Text, AmountBox.Text)
end)

-- BOTÓN DE HIGHSCORE AÑADIDO
createBtn("SET HIGHSCORE 🏆", Color3.fromRGB(255, 215, 0), 10, function()
	AdminEvent:FireServer("SetScore", TargetBox.Text, AmountBox.Text)
end)

-- ✅ CORREGIDO: AHORA SÍ FUNCIONA (Con función y orden correcto 11)
createBtn("SET 5x5 SCORE 🟦", Color3.fromRGB(150, 50, 255), 11, function()
	AdminEvent:FireServer("SetScore5x5", TargetBox.Text, AmountBox.Text)
end)

createLabel("4. SPECIALS", 12) -- Movido a 12
local AttrBox = createInput("Attribute Name (e.g. Title_S1_HS_1)", 13)

createBtn("GIVE ATTRIBUTE 🔓", Color3.fromRGB(160, 50, 255), 14, function()
	AdminEvent:FireServer("GiveAttribute", TargetBox.Text, AttrBox.Text)
end)

createBtn("UNLOCK ALL SKINS/TITLES 🌟", Color3.fromRGB(255, 0, 255), 15, function()
	AdminEvent:FireServer("UnlockAllTitles", TargetBox.Text, nil)
end)

-- Botón nuevo para Resetear Nivel
createBtn("RESET LEVEL ONLY 📉", Color3.fromRGB(255, 100, 50), 16, function()
	AdminEvent:FireServer("ResetLevel", TargetBox.Text, nil)
end)

-- CONTROLES DE RACHA
createBtn("SET STREAK DAYS 🔥", Color3.fromRGB(255, 140, 0), 17, function()
	AdminEvent:FireServer("SetStreak", TargetBox.Text, AmountBox.Text)
end)

createBtn("BREAK STREAK 💔", Color3.fromRGB(100, 100, 100), 18, function()
	AdminEvent:FireServer("BreakStreak", TargetBox.Text, nil)
end)

-- ✅ BOTÓN RESTAURADO: RESETEAR TODO (DATA + LEADERBOARDS)
createBtn("XXX RESET ALL DATA XXX ☠️", Color3.fromRGB(180, 0, 0), 20, function()
	AdminEvent:FireServer("Reset", TargetBox.Text, nil)
end)


-- TOGGLE CON F2
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end -- Ignorar si estás escribiendo en el chat
	if input.KeyCode == Enum.KeyCode.F2 then
		-- Verificación de seguridad: Solo abrir si está en la lista ADMINS
		if ADMINS[player.Name] then
			MainFrame.Visible = not MainFrame.Visible
		else
			warn("⛔ Acceso denegado: No eres administrador.")
		end
	end
end)
