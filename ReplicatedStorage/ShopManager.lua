local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIUtils = require(ReplicatedStorage:WaitForChild("UIUtils"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))



local ShopManager = {}
local ShopRefs = {}
local ShopFrame = nil
local player = Players.LocalPlayer
local VIP_ID = 0
-- NUEVO: Lista para recordar compras hechas en esta sesión
local sessionOwnedPasses = {} 

function ShopManager.registerLocalPurchase(id)
	sessionOwnedPasses[id] = true
end



-- 1. INIT

function ShopManager.init(ScreenGui, vipPassId)

	VIP_ID = vipPassId
	ShopFrame = Instance.new("Frame")
	ShopFrame.Name = "ShopFrameNew"
	ShopFrame.Size = UDim2.new(0.7, 0, 0.7, 0) 
	ShopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	ShopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	ShopFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 80)
	ShopFrame.BorderSizePixel = 0
	ShopFrame.ZIndex = 1200
	ShopFrame.Visible = false
	ShopFrame.Parent = ScreenGui 



	local mainStroke = Instance.new("UIStroke")

	mainStroke.Color = Color3.fromRGB(255, 200, 50)
	mainStroke.Thickness = 6
	mainStroke.Parent = ShopFrame
	Instance.new("UICorner", ShopFrame).CornerRadius = UDim.new(0, 15)



	local titleImage = Instance.new("ImageLabel")
	titleImage.Image = "rbxassetid://88661268877666"
	titleImage.BackgroundTransparency = 1
	titleImage.ScaleType = Enum.ScaleType.Fit
	titleImage.AnchorPoint = Vector2.new(0, 0)
	titleImage.Position = UDim2.new(0.005, 0, 0.005, 0) 
	titleImage.Size = UDim2.new(0.25, 0, 0.15, 0) 
	titleImage.ZIndex = 1202
	titleImage.Parent = ShopFrame



	local closeBtn = Instance.new("TextButton") 

	closeBtn.Name = "CloseButton"

	closeBtn.Text = "X"

	closeBtn.TextColor3 = Color3.new(1,1,1)

	closeBtn.TextSize = 28

	closeBtn.Font = Enum.Font.FredokaOne

	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)

	closeBtn.Size = UDim2.new(0.07, 0, 0.07, 0)

	closeBtn.Position = UDim2.new(0.99, 0, 0.01, 0)

	closeBtn.AnchorPoint = Vector2.new(1, 0)

	closeBtn.ZIndex = 1205

	closeBtn.Parent = ShopFrame

	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	local constraint = Instance.new("UIAspectRatioConstraint", closeBtn); constraint.AspectRatio = 1

	local xStroke = Instance.new("UIStroke", closeBtn); xStroke.Color = Color3.fromRGB(255, 200, 50); xStroke.Thickness = 3; xStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	ShopRefs.CloseBtn = closeBtn 



	local leftContainer = Instance.new("Frame")

	leftContainer.BackgroundTransparency = 1

	leftContainer.Size = UDim2.new(0.25, 0, 0.75, 0)

	leftContainer.Position = UDim2.new(0.02, 0, 0.2, 0)

	leftContainer.ZIndex = 1201

	leftContainer.Parent = ShopFrame

	local listLayout = Instance.new("UIListLayout", leftContainer); listLayout.Padding = UDim.new(0.02, 0); listLayout.SortOrder = Enum.SortOrder.LayoutOrder



	local function createCategoryButton(name, order)

		local btn = Instance.new("ImageButton")

		btn.Name = "Tab_" .. name

		btn.LayoutOrder = order

		btn.BackgroundColor3 = Color3.new(1,1,1)

		btn.BackgroundTransparency = 1

		btn.Size = UDim2.new(1, 0, 0.28, 0)

		btn.BorderSizePixel = 0

		btn.ScaleType = Enum.ScaleType.Fit

		btn.ZIndex = 1205

		btn.Parent = leftContainer

		btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(180, 180, 180)}):Play() end)

		btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {ImageColor3 = Color3.new(1,1,1)}):Play() end)

		return btn

	end



	ShopRefs.TabCurrencyBtn = createCategoryButton("Currency", 1); ShopRefs.TabCurrencyBtn.Image = "rbxassetid://70409978671126"

	ShopRefs.TabPassesBtn = createCategoryButton("Passes", 2); ShopRefs.TabPassesBtn.Image = "rbxassetid://132582629758945"

	ShopRefs.TabSkinsBtn = createCategoryButton("Skins", 3); ShopRefs.TabSkinsBtn.Image = "rbxassetid://100737380049446"



	local rightContainer = Instance.new("Frame")

	rightContainer.Name = "ShopContent"

	rightContainer.BackgroundColor3 = Color3.fromRGB(220, 180, 80)

	rightContainer.Size = UDim2.new(0.68, 0, 0.85, 0)

	rightContainer.Position = UDim2.new(0.98, 0, 0.55, 0)

	rightContainer.AnchorPoint = Vector2.new(1, 0.5)

	rightContainer.ZIndex = 1201

	rightContainer.Parent = ShopFrame

	Instance.new("UICorner", rightContainer).CornerRadius = UDim.new(0, 10)

	local rs = Instance.new("UIStroke", rightContainer); rs.Color = Color3.fromRGB(255, 215, 0); rs.Thickness = 5



	ShopRefs.CurrencyContainer = Instance.new("ScrollingFrame", rightContainer)

	ShopRefs.CurrencyContainer.Size = UDim2.new(0.95, 0, 0.95, 0); ShopRefs.CurrencyContainer.Position = UDim2.new(0.5,0,0.5,0); ShopRefs.CurrencyContainer.AnchorPoint = Vector2.new(0.5,0.5); ShopRefs.CurrencyContainer.BackgroundTransparency = 1; ShopRefs.CurrencyContainer.ScrollBarThickness = 6; ShopRefs.CurrencyContainer.ZIndex = 1205

	ShopRefs.CurrencyContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y; ShopRefs.CurrencyContainer.CanvasSize = UDim2.new(0,0,0,0)



	ShopRefs.SkinsPageContainer = Instance.new("ScrollingFrame", rightContainer)

	ShopRefs.SkinsPageContainer.Size = UDim2.new(0.95, 0, 0.95, 0); ShopRefs.SkinsPageContainer.Position = UDim2.new(0.5,0,0.5,0); ShopRefs.SkinsPageContainer.AnchorPoint = Vector2.new(0.5,0.5); ShopRefs.SkinsPageContainer.BackgroundTransparency = 1; ShopRefs.SkinsPageContainer.ScrollBarThickness = 6; ShopRefs.SkinsPageContainer.Visible = false; ShopRefs.SkinsPageContainer.ZIndex = 1205

	ShopRefs.SkinsPageContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y; ShopRefs.SkinsPageContainer.CanvasSize = UDim2.new(0,0,0,0)



	ShopRefs.PassesContainer = Instance.new("ScrollingFrame", rightContainer)
	ShopRefs.PassesContainer.Size = UDim2.new(0.95,0,0.95,0); ShopRefs.PassesContainer.Position = UDim2.new(0.5,0,0.5,0); ShopRefs.PassesContainer.AnchorPoint = Vector2.new(0.5,0.5)
	ShopRefs.PassesContainer.BackgroundTransparency = 1; ShopRefs.PassesContainer.Visible = false; ShopRefs.PassesContainer.ZIndex = 1205
	ShopRefs.PassesContainer.ScrollBarThickness = 6
	ShopRefs.PassesContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y; ShopRefs.PassesContainer.CanvasSize = UDim2.new(0,0,0,0)



	return ShopFrame, ShopRefs

end



-- 2. POPULATE CURRENCY

function ShopManager.populateCurrency()

	if not ShopRefs.CurrencyContainer then return end

	ShopRefs.CurrencyContainer:ClearAllChildren()

	local layout = Instance.new("UIListLayout", ShopRefs.CurrencyContainer); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 30); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center



	-- ? PADDING AUMENTADO (250) PARA QUE BAJE BIEN EL SCROLL

	local pad = Instance.new("UIPadding", ShopRefs.CurrencyContainer); pad.PaddingTop=UDim.new(0,10); pad.PaddingBottom=UDim.new(0,250)



	-- ? TUS IDS DEFINIDOS AQUÍ DENTRO PARA QUE NO DEN ERROR

	local ICON_COIN = "rbxassetid://108796514719654"

	local ICON_DIAMOND = "rbxassetid://111308733495717"

	local ICON_FRUIT = "rbxassetid://128100423386205"



	local coinProducts = {

		{Amount="1,000", Robux=15, ProductId=3467195139, Icon=ICON_COIN},

		{Amount="5,000", Robux=59, ProductId=3467195412, Icon=ICON_COIN},

		{Amount="15,000", Robux=159, ProductId=3467195674, Icon=ICON_COIN},

		{Amount="25,000", Robux=259, ProductId=3467195950, Icon=ICON_COIN},

		{Amount="50,000", Robux=479, ProductId=9240572528, Icon=ICON_COIN},

		{Amount="100,000", Robux=899, ProductId=3467196400, Icon=ICON_COIN}

	} 

	local diamondProducts = {

		{Amount="20", Robux=15, ProductId=3467196622, Icon=ICON_DIAMOND},

		{Amount="120", Robux=59, ProductId=3467197662, Icon=ICON_DIAMOND},

		{Amount="300", Robux=149, ProductId=3467197871, Icon=ICON_DIAMOND},

		{Amount="550", Robux=259, ProductId=3467281064, Icon=ICON_DIAMOND},

		{Amount="1,200", Robux=479, ProductId=3467281907, Icon=ICON_DIAMOND},

		{Amount="2,500", Robux=899, ProductId=3467282191, Icon=ICON_DIAMOND}

	}

	local fruitProducts = {

		{Amount="500", Robux=15, ProductId=3467282831, Icon=ICON_FRUIT},

		{Amount="2,500", Robux=59, ProductId=3467283069, Icon=ICON_FRUIT},

		{Amount="7,000", Robux=149, ProductId=3467283366, Icon=ICON_FRUIT},

		{Amount="12,500", Robux=259, ProductId=3467283639, Icon=ICON_FRUIT},

		{Amount="25,000", Robux=479, ProductId=3467283819, Icon=ICON_FRUIT},

		{Amount="50,000", Robux=899, ProductId=3467283985, Icon=ICON_FRUIT}

	}



	local function createSection(title, list, order, colorTheme)

		local header = Instance.new("TextLabel", ShopRefs.CurrencyContainer); header.Text = title; header.Size = UDim2.new(0.95, 0, 0, 40); header.BackgroundTransparency = 1; header.TextColor3 = colorTheme; header.Font = Enum.Font.FredokaOne; header.TextSize = 28; header.TextXAlignment = Enum.TextXAlignment.Left; header.LayoutOrder = order

		local gridFr = Instance.new("Frame", ShopRefs.CurrencyContainer); gridFr.Size = UDim2.new(1,0,0,0); gridFr.AutomaticSize=Enum.AutomaticSize.Y; gridFr.BackgroundTransparency=1; gridFr.LayoutOrder=order+1

		local grid = Instance.new("UIGridLayout", gridFr); grid.CellSize = UDim2.new(0.3, 0, 0, 180); grid.CellPadding = UDim2.new(0.03, 0, 0.03, 0); grid.HorizontalAlignment = Enum.HorizontalAlignment.Center

		for _, prod in ipairs(list) do

			local card = Instance.new("Frame", gridFr); card.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16); local cStroke = Instance.new("UIStroke", card); cStroke.Color = colorTheme; cStroke.Thickness = 4

			local amt = Instance.new("TextLabel", card); amt.Text = prod.Amount; amt.Size=UDim2.new(1,0,0.25,0); amt.BackgroundTransparency=1; amt.Font=Enum.Font.FredokaOne; amt.TextScaled=true; amt.TextColor3=colorTheme



			local icon = Instance.new("ImageLabel", card)

			icon.Image = prod.Icon

			icon.Size = UDim2.new(0.5,0,0.5,0)

			icon.Position = UDim2.new(0.25,0,0.2,0)

			icon.BackgroundTransparency = 1

			icon.ScaleType = Enum.ScaleType.Fit



			local buy = Instance.new("TextButton", card); buy.Text = "R$ " .. prod.Robux; buy.Size=UDim2.new(0.9,0,0.22,0); buy.Position=UDim2.new(0.05,0,0.72,0); buy.BackgroundColor3=Color3.fromRGB(0,220,100); buy.Font=Enum.Font.FredokaOne; buy.TextScaled=true; buy.TextColor3=Color3.new(1,1,1); Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 10)

			buy.MouseButton1Click:Connect(function() UIUtils.playClick(); if prod.ProductId > 0 then MarketplaceService:PromptProductPurchase(player, prod.ProductId) end end)

		end

	end

	createSection("COINS", coinProducts, 1, Color3.fromRGB(255, 180, 0))

	createSection("DIAMONDS", diamondProducts, 3, Color3.fromRGB(0, 180, 255))

	createSection("FRUITS", fruitProducts, 5, Color3.fromRGB(255, 80, 100))

end



-- 3. POPULATE SKINS

function ShopManager.populateSkins(currentSkin, callbackColor)

	if not ShopRefs.SkinsPageContainer then return end

	ShopRefs.SkinsPageContainer:ClearAllChildren()



	local mainLayout = Instance.new("UIListLayout", ShopRefs.SkinsPageContainer)

	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder

	mainLayout.Padding = UDim.new(0, 30)

	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center



	-- ? Padding de 300 para que baje completamente

	local pad = Instance.new("UIPadding", ShopRefs.SkinsPageContainer)

	pad.PaddingBottom = UDim.new(0, 300) 

	pad.PaddingTop = UDim.new(0, 20)



	-- LISTA DE SKINS

	local normalItems = {

		{Name="Classic",  Price=0,       Currency="Coins", Color=Color3.fromRGB(238, 228, 218)},

		{Name="Blue",     Price=500,     Currency="Coins", Color=Color3.fromRGB(0, 200, 255)},

		{Name="Red",      Price=1000,    Currency="Coins", Color=Color3.fromRGB(255, 80, 80)},

		{Name="Green",    Price=2500,    Currency="Coins", Color=Color3.fromRGB(80, 200, 80)},

		{Name="Purple",   Price=5000,    Currency="Coins", Color=Color3.fromRGB(180, 100, 255)},



		{Name="Blue Pro",   Price=10000,  Currency="Coins", Color=Color3.fromRGB(0, 150, 255), HasBorder=true},

		{Name="Red Pro",    Price=15000,  Currency="Coins", Color=Color3.fromRGB(255, 50, 50), HasBorder=true},

		{Name="Green Pro",  Price=20000,  Currency="Coins", Color=Color3.fromRGB(50, 200, 50), HasBorder=true},

		{Name="Purple Pro", Price=25000,  Currency="Coins", Color=Color3.fromRGB(150, 50, 255), HasBorder=true},

		{Name="Orange Pro", Price=30000,  Currency="Coins", Color=Color3.fromRGB(255, 120, 0), HasBorder=true},

		{Name="Pink Pro",   Price=40000,  Currency="Coins", Color=Color3.fromRGB(255, 80, 150), HasBorder=true},

		{Name="Cyan Pro",   Price=50000,  Currency="Coins", Color=Color3.fromRGB(0, 255, 255), HasBorder=true},



		{Name="Dark",     Price=90000,   Currency="Coins", Color=Color3.fromRGB(50, 50, 50)},

		{Name="Gold",     Price=95000,   Currency="Coins", Color=Color3.fromRGB(255, 215, 0)},

		{Name="Rainbow",  Price=100000,  Currency="Coins", Color=Color3.new(1,0,0), IsRainbow=true}

	}



	local specialItems = {

		{Name="Neon",         Price=1500,  Currency="Diamonds", Color=Color3.fromRGB(0, 255, 255), IsNeon=true},

		{Name="Robot",        Price=1000,  Currency="Diamonds", Color=Color3.fromRGB(80, 90, 100)},

		{Name="Volcanic",     Price=2500,  Currency="Diamonds", Color=Color3.fromRGB(255, 80, 0)},

		{Name="Classic 2048", Price=500,   Currency="Diamonds", Color=Color3.fromRGB(237, 194, 46), HasBorder=true},

		{Name="Fruit Mix",    Price=2000,  Currency="Diamonds", Color=Color3.fromRGB(255, 170, 0)},

		{Name="VIP",          Price=0,     Currency="Pass",     Color=Color3.fromRGB(20, 20, 20), IsVIP=true}

	}



	local function createSection(title, list, orderIndex)

		local header = Instance.new("TextLabel", ShopRefs.SkinsPageContainer)

		header.Text = title

		header.Size = UDim2.new(0.95, 0, 0, 40)

		header.BackgroundTransparency = 1

		header.TextColor3 = Color3.fromRGB(0, 120, 220)

		header.Font = Enum.Font.FredokaOne

		header.TextSize = 28

		header.TextXAlignment = Enum.TextXAlignment.Left

		header.LayoutOrder = orderIndex



		local gridFrame = Instance.new("Frame", ShopRefs.SkinsPageContainer)

		gridFrame.BackgroundTransparency = 1

		gridFrame.Size = UDim2.new(1, 0, 0, 0)

		gridFrame.AutomaticSize = Enum.AutomaticSize.Y

		gridFrame.LayoutOrder = orderIndex + 1



		local grid = Instance.new("UIGridLayout", gridFrame)

		grid.CellSize = UDim2.new(0.47, 0, 0, 230)

		grid.CellPadding = UDim2.new(0.04, 0, 0.04, 0)

		grid.HorizontalAlignment = Enum.HorizontalAlignment.Center



		for k, item in ipairs(list) do

			local card = Instance.new("Frame", gridFrame)

			card.BackgroundColor3 = Color3.fromRGB(240, 248, 255)

			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)



			local cardStroke = Instance.new("UIStroke", card)

			cardStroke.Color = Color3.fromRGB(180, 210, 255)

			cardStroke.Thickness = 4



			local titleLbl = Instance.new("TextLabel", card)

			titleLbl.Text = item.Name

			titleLbl.Size = UDim2.new(1,0,0.2,0)

			titleLbl.BackgroundTransparency = 1

			titleLbl.Font = Enum.Font.FredokaOne

			titleLbl.TextScaled = true

			titleLbl.TextColor3 = Color3.fromRGB(80, 80, 90)

			titleLbl.Position = UDim2.new(0,0,0.05,0)



			local pv = Instance.new("Frame", card)

			pv.Size = UDim2.new(0.55,0,0.4,0)

			pv.Position = UDim2.new(0.225,0,0.25,0)

			pv.BackgroundColor3 = item.Color

			Instance.new("UICorner", pv).CornerRadius = UDim.new(0, 12)



			if item.HasBorder then

				local pvStroke = Instance.new("UIStroke", pv)

				pvStroke.Thickness = 3

				pvStroke.Color = Color3.new(0,0,0)

				pvStroke.Transparency = 0.5

			end



			if item.IsRainbow then 

				task.spawn(function() 

					while pv.Parent do 

						local t=tick(); 

						pv.BackgroundColor3=Color3.fromHSV((t*0.5)%1,1,1); 

						task.wait() 

					end 

				end) 

			end



			local buyBtn = Instance.new("TextButton", card)

			buyBtn.Size = UDim2.new(0.9,0,0.22,0)

			buyBtn.Position = UDim2.new(0.05,0,0.72,0)

			buyBtn.Font = Enum.Font.FredokaOne

			buyBtn.TextScaled = true

			buyBtn.TextColor3 = Color3.new(1,1,1)

			Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 10)



			local safeName = string.gsub(item.Name, " ", "")

			local isOwned = (item.Price == 0) or player:GetAttribute("OwnedSkin_" .. safeName)

			if item.IsVIP then 

				local s, h = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_ID) end); 

				isOwned = s and h 

			end



			if isOwned then

				buyBtn.Text = (currentSkin == item.Name) and "EQUIPPED" or "EQUIP"

				buyBtn.BackgroundColor3 = (currentSkin == item.Name) and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(0, 160, 255)

				buyBtn.MouseButton1Click:Connect(function() 

					UIUtils.playClick()

					if callbackColor then 

						callbackColor(item.Name)

						ShopManager.populateSkins(item.Name, callbackColor) 

					end

				end)

			else

				if item.Currency == "Diamonds" then buyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)

				elseif item.Currency == "FruitGems" then buyBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)

				else buyBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0) end



				buyBtn.MouseButton1Click:Connect(function()

					UIUtils.playClick()

					if item.IsVIP then if VIP_ID > 0 then MarketplaceService:PromptGamePassPurchase(player, VIP_ID) end

					else

						local ls = player:FindFirstChild("leaderstats")

						local currencyVal = 0

						if item.Currency == "Diamonds" then currencyVal = ls.Diamonds.Value

						elseif item.Currency == "FruitGems" then currencyVal = ls.FruitGems.Value

						else currencyVal = ls.Coins.Value end



						if currencyVal >= item.Price then

							game.ReplicatedStorage:FindFirstChild("PurchaseItem"):FireServer(item.Name)

							player:SetAttribute("OwnedSkin_"..safeName, true)

							if callbackColor then ShopManager.populateSkins(currentSkin, callbackColor) end

						end

					end

				end)

				if not item.IsVIP then 

					-- CALCULAR PRECIO VISUAL (Con descuento VIP si aplica)

					local finalPrice = item.Price



					-- Verificamos localmente si tiene VIP para mostrar el precio rebajado

					-- (El servidor hace la verificación real de seguridad, esto es solo visual)

					local hasVip = false

					pcall(function() hasVip = MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_ID) end)



					if hasVip and finalPrice > 0 then

						finalPrice = math.floor(finalPrice * 0.85) -- 15% menos

						buyBtn.TextColor3 = Color3.fromRGB(255, 255, 100) -- Texto amarillo para indicar oferta

					end



					buyBtn.Text = "   "..finalPrice 

					local ic = Instance.new("ImageLabel", buyBtn); ic.Size=UDim2.new(0.25,0,0.7,0); ic.Position=UDim2.new(0.8,0,0.15,0); ic.BackgroundTransparency=1; ic.ScaleType=Enum.ScaleType.Fit; ic.AnchorPoint=Vector2.new(0.5,0)

					-- ? ICONOS CORRECTOS EN EL BOTÓN DE COMPRA

					if item.Currency == "Diamonds" then ic.Image = "rbxassetid://111308733495717"

					elseif item.Currency == "FruitGems" then ic.Image = "rbxassetid://128100423386205"

					else ic.Image = "rbxassetid://108796514719654" end

					buyBtn.TextXAlignment = Enum.TextXAlignment.Left

				end

			end

		end

	end



	createSection("NORMAL SKINS (Coins)", normalItems, 1)

	createSection("SPECIALS (Exclusives)", specialItems, 2)

end



-- 4. POPULATE PASSES (VERIFICACIÓN DE PROPIEDAD CORREGIDA)
function ShopManager.populatePasses()
	if not ShopRefs.PassesContainer then return end
	ShopRefs.PassesContainer:ClearAllChildren()

	local layout = Instance.new("UIGridLayout", ShopRefs.PassesContainer); layout.CellSize = UDim2.new(0.47, 0, 0, 200); layout.CellPadding = UDim2.new(0.04, 0, 0.04, 0); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local pad = Instance.new("UIPadding", ShopRefs.PassesContainer); pad.PaddingTop = UDim.new(0, 20); pad.PaddingBottom = UDim.new(0, 150)

	-- ? IDs REALES (Asegúrate de que coincidan con los de tu juego)
	local passes = {
		{Name="x2 XP",     Id=1609347878, Price=249, Color=Color3.fromRGB(100, 255, 100)},
		{Name="x2 Coins",  Id=1612413325, Price=149, Color=Color3.fromRGB(255, 200, 0)},
		{Name="x2 Gems",   Id=1613811032, Price=249, Color=Color3.fromRGB(0, 200, 255)},
		{Name="x2 Fruits", Id=1614668850, Price=149, Color=Color3.fromRGB(255, 100, 100)},
		{Name="VIP",       Id=1605082468, Price=199, Color=Color3.fromRGB(50, 50, 50)}
	}

	for _, pass in ipairs(passes) do
		local card = Instance.new("Frame", ShopRefs.PassesContainer); card.BackgroundColor3 = Color3.fromRGB(240, 240, 255); Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
		local s = Instance.new("UIStroke", card); s.Color = pass.Color; s.Thickness = 4

		local icon = Instance.new("ImageLabel", card); icon.Size=UDim2.new(0.5,0,0.5,0); icon.Position=UDim2.new(0.25,0,0.1,0); icon.BackgroundTransparency=1; icon.ScaleType=Enum.ScaleType.Fit
		icon.Image = "rbxthumb://type=GamePass&id=" .. pass.Id .. "&w=150&h=150"

		local nameLbl = Instance.new("TextLabel", card); nameLbl.Text = pass.Name; nameLbl.Size=UDim2.new(1,0,0.15,0); nameLbl.Position=UDim2.new(0,0,0.6,0); nameLbl.BackgroundTransparency=1; nameLbl.Font=Enum.Font.FredokaOne; nameLbl.TextColor3=Color3.new(0.3,0.3,0.3); nameLbl.TextScaled=true

		local buyBtn = Instance.new("TextButton", card)
		buyBtn.Size=UDim2.new(0.9,0,0.2,0); buyBtn.Position=UDim2.new(0.05,0,0.78,0)
		buyBtn.Font=Enum.Font.FredokaOne; buyBtn.TextScaled=true; Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

		-- ?? VERIFICAR SI YA LO TIENE (API + Memoria Local)
		local isOwned = sessionOwnedPasses[pass.Id] == true -- Revisar memoria local primero

		if not isOwned then -- Si no está en memoria, preguntar a Roblox
			local success, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
			end)
			if success and result then isOwned = true end
		end

		if isOwned then
			buyBtn.Text = "OWNED"
			buyBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Gris
			buyBtn.TextColor3 = Color3.new(1,1,1)
			buyBtn.Active = false -- No clickeable
		else
			buyBtn.Text = "R$ "..pass.Price
			buyBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 100) -- Verde
			buyBtn.TextColor3 = Color3.new(1,1,1)

			buyBtn.MouseButton1Click:Connect(function()
				UIUtils.playClick()
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			end)
		end
	end
end



function ShopManager.switchTab(name, currentSkin, skinCallback)

	UIUtils.playClick()

	if ShopRefs.CurrencyContainer then ShopRefs.CurrencyContainer.Visible = false end

	if ShopRefs.SkinsPageContainer then ShopRefs.SkinsPageContainer.Visible = false end

	if ShopRefs.PassesContainer then ShopRefs.PassesContainer.Visible = false end



	if ShopRefs.TabCurrencyBtn then ShopRefs.TabCurrencyBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 0) end

	if ShopRefs.TabSkinsBtn then ShopRefs.TabSkinsBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 200) end

	if ShopRefs.TabPassesBtn then ShopRefs.TabPassesBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 200) end



	if name == "Currency" then

		if ShopRefs.CurrencyContainer then ShopRefs.CurrencyContainer.Visible = true end

		if ShopRefs.TabCurrencyBtn then ShopRefs.TabCurrencyBtn.BackgroundColor3 = Color3.fromRGB(255, 220, 50) end

		ShopManager.populateCurrency()

	elseif name == "Skins" then

		if ShopRefs.SkinsPageContainer then ShopRefs.SkinsPageContainer.Visible = true end

		if ShopRefs.TabSkinsBtn then ShopRefs.TabSkinsBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 255) end

		ShopManager.populateSkins(currentSkin, skinCallback)

	elseif name == "Passes" then

		if ShopRefs.CurrencyContainer then ShopRefs.CurrencyContainer.Visible = false end

		if ShopRefs.SkinsPageContainer then ShopRefs.SkinsPageContainer.Visible = false end

		if ShopRefs.PassesContainer then ShopRefs.PassesContainer.Visible = true end

		if ShopRefs.TabPassesBtn then ShopRefs.TabPassesBtn.BackgroundColor3 = Color3.fromRGB(255, 120, 255) end



		-- ? LLAMAMOS A LA NUEVA FUNCIÓN PARA QUE CARGUEN LOS PASES

		ShopManager.populatePasses()

	end

end



return ShopManager