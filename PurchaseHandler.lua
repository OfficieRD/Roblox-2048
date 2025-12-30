local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local PRODUCTS = {
	
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
		-- El jugador se fue, Roblox intentará cobrar luego
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productData = PRODUCTS[receiptInfo.ProductId]

	if productData then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			-- 1. Entregar Moneda
			if productData.Type == "Coins" then
				leaderstats.Coins.Value += productData.Amount
				player:SetAttribute("TotalCoins", (player:GetAttribute("TotalCoins") or 0) + productData.Amount)

			elseif productData.Type == "Diamonds" then
				-- Asegurar que existe la stat Diamonds
				if leaderstats:FindFirstChild("Diamonds") then
					leaderstats.Diamonds.Value += productData.Amount
				end

			elseif productData.Type == "FruitGems" then
				leaderstats.FruitGems.Value += productData.Amount
				player:SetAttribute("TotalFruitGems", (player:GetAttribute("TotalFruitGems") or 0) + productData.Amount)

				-- ? VALIDACIÓN DE UNDOS (Solo confirmamos el pago, el cliente da los undos visuales)
			elseif productData.Type == "Undos" then
				print("? Compra de Undos validada para: " .. player.Name)
			end

			print("? VENTA EXITOSA: " .. player.Name .. " compró " .. productData.Amount .. " " .. productData.Type)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- TABLA DE PRODUCTOS DE DEV (IDs Reales)
local DEV_PRODUCTS = {
	-- [TU_ID_DE_UNDOS] = {Type = "Undos", Amount = 3},
	-- Ejemplo:
	-- [12345678] = {Type = "Undos", Amount = 3}
}