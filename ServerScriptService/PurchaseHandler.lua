local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local PRODUCTS = {
	-- Asegúrate de que este ID sea un DEVELOPER PRODUCT, no un GamePass.
	[3472578365] = {Type = "Undos", Amount = 3},

	-- MONEDAS
	[3467195139] = {Type = "Coins", Amount = 1000},
	[3467195412] = {Type = "Coins", Amount = 5000},
	[3467195674] = {Type = "Coins", Amount = 15000},
	[3467195950] = {Type = "Coins", Amount = 25000},
	[9240572528] = {Type = "Coins", Amount = 50000},
	[3467196400] = {Type = "Coins", Amount = 100000},

	-- DIAMANTES
	[3467196622] = {Type = "Diamonds", Amount = 20},
	[3467197662] = {Type = "Diamonds", Amount = 120},
	[3467197871] = {Type = "Diamonds", Amount = 300},
	[3467281064] = {Type = "Diamonds", Amount = 550},
	[3467281907] = {Type = "Diamonds", Amount = 1200},
	[3467282191] = {Type = "Diamonds", Amount = 2500},

	-- FRUIT GEMS
	[3467282831] = {Type = "FruitGems", Amount = 500},
	[3467283069] = {Type = "FruitGems", Amount = 2500},
	[3467283366] = {Type = "FruitGems", Amount = 7000},
	[3467283639] = {Type = "FruitGems", Amount = 12500},
	[3467283819] = {Type = "FruitGems", Amount = 25000},
	[3467283985] = {Type = "FruitGems", Amount = 50000},
}

-- FUNCIÓN DE PROCESO DE COMPRA
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessed
	end

	-- 1. REGISTRAR ROBUX GASTADOS (Global)
	local spent = receiptInfo.CurrencySpent or 0
	if spent == 0 then
		local s, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(receiptInfo.ProductId, Enum.InfoType.Product)
		end)
		if s and info then spent = info.PriceInRobux or 0 end
	end

	local currentTotal = player:GetAttribute("TotalRobuxSpent") or 0
	player:SetAttribute("TotalRobuxSpent", currentTotal + spent)
	print("💸 Gasto registrado: +" .. spent .. " Robux.")

	-- 2. ENTREGAR PRODUCTO
	local productData = PRODUCTS[receiptInfo.ProductId]

	if productData then
		local leaderstats = player:FindFirstChild("leaderstats")

		if leaderstats then
			-- A) Monedas
			if productData.Type == "Coins" then
				leaderstats.Coins.Value += productData.Amount
				player:SetAttribute("TotalCoins", (player:GetAttribute("TotalCoins") or 0) + productData.Amount)

				-- B) Diamantes
			elseif productData.Type == "Diamonds" then
				if leaderstats:FindFirstChild("Diamonds") then
					leaderstats.Diamonds.Value += productData.Amount
				end

				-- C) Fruit Gems
			elseif productData.Type == "FruitGems" then
				leaderstats.FruitGems.Value += productData.Amount
				player:SetAttribute("TotalFruitGems", (player:GetAttribute("TotalFruitGems") or 0) + productData.Amount)

				-- D) ✅ UNDOS (MODO REFILL: SIEMPRE 3 - SIN LAG)
			elseif productData.Type == "Undos" then
				local fixedAmount = productData.Amount or 3

				-- Asignamos el valor fijo sin imprimir nada en consola
				player:SetAttribute("Undos", fixedAmount) 
			end

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end
