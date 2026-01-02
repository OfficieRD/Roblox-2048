local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local UIUtils = {}

-- CONSTANTES DE ANIMACIÓN
local POP_OPEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_CLOSE_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local HOVER_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- SONIDOS (Se asignarán desde el cliente para no crear conflictos)
UIUtils.ClickSound = nil

function UIUtils.playClick()
	if UIUtils.ClickSound then UIUtils.ClickSound:Play() end
end

function UIUtils.addHoverEffect(button)
	if not button then return end
	-- Usamos pcall por si el botón no tiene propiedad Size (raro, pero seguro)
	local success, originalSize = pcall(function() return button.Size end)
	if not success then return end

	button.MouseEnter:Connect(function()
		TweenService:Create(button, HOVER_INFO, {
			Size = UDim2.new(originalSize.X.Scale * 0.9, originalSize.X.Offset, originalSize.Y.Scale * 0.9, originalSize.Y.Offset)
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, HOVER_INFO, {Size = originalSize}):Play()
	end)
end

function UIUtils.openMenuWithAnim(frame)
	if frame.Visible then return end

	-- Detectar tamaño objetivo basado en el nombre o tipo (lógica simplificada)
	local targetSize = UDim2.new(0.7, 0, 0.7, 0) -- Default
	if frame.Name == "SettingsFrame" then targetSize = UDim2.new(0.6, 0, 0.6, 0) 
	elseif frame.Name == "LeaderboardFrame" then targetSize = UDim2.new(0.7, 0, 0.8, 0)
	elseif frame.Name == "ShopFrameNew" then targetSize = UDim2.new(0.7, 0, 0.7, 0)
	end

	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.Visible = true
	UIUtils.playClick()
	TweenService:Create(frame, POP_OPEN_INFO, {Size = targetSize}):Play()
end

function UIUtils.closeMenuWithAnim(frame, callback)
	if not frame.Visible then return end
	UIUtils.playClick()
	local tween = TweenService:Create(frame, POP_CLOSE_INFO, {Size = UDim2.new(0, 0, 0, 0)})
	tween:Play()
	tween.Completed:Connect(function() 
		frame.Visible = false 
		if callback then callback() end
	end)
end

function UIUtils.spawnConfetti(parent, centerPos, colorOrId, isImage)
	for i = 1, 8 do 
		local p
		if isImage then
			p = Instance.new("ImageLabel")
			p.Image = colorOrId
			p.BackgroundTransparency = 1
		else
			p = Instance.new("Frame")
			p.BackgroundColor3 = colorOrId
			p.BorderSizePixel = 0
		end

		p.Size = UDim2.new(0.08, 0, 0.08, 0)
		p.Position = centerPos
		p.Parent = parent
		p.ZIndex = 50

		local angle = math.rad(math.random(0, 360))
		local dist = 0.12 + (math.random()*0.05)
		local targetPos = centerPos + UDim2.new(math.cos(angle)*dist, 0, math.sin(angle)*dist, 0)

		local properties = {
			Position = targetPos,
			Rotation = math.random(0, 360)
		}
		if isImage then properties.ImageTransparency = 1 else properties.BackgroundTransparency = 1 end

		local tween = TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
		tween:Play()
		Debris:AddItem(p, 0.4)
	end
end

return UIUtils
