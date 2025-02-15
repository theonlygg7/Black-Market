local QBCore = exports['qb-core']:GetCoreObject()

-- Open Shop Event
local function openShop(shop, data)
    print("Received request to open Black Market shop...")  -- Debugging log

    -- Get the shop inventory (can be used to manage dynamic items)
    QBCore.Functions.TriggerCallback('qb-blackmarket:server:GetShopInventory', function(shopInvJson)
        local function SetupItems()
            local products = Config.Items
            local items = {}
            local notifiedLicenses = {}

            -- Decode the inventory JSON from the callback
            shopInvJson = json.decode(shopInvJson)

            -- Handle inventory rotation or any job/license filtering here if needed
            for i = 1, #products do
                local curProduct = products[i]
                local addProduct = true

                -- License check (if licenses are required for the item)
                if curProduct.requiredLicense and not hasLicense(curProduct.requiredLicense, PlayerData.metadata["licences"]) then
                    addProduct = false
                    for _, license in ipairs(curProduct.requiredLicense) do
                        if not PlayerData.metadata["licences"][license] and not notifiedLicenses[license] then
                            QBCore.Functions.Notify(string.format(Lang:t("error.missing_license"), license), "error")
                            notifiedLicenses[license] = true
                        end
                    end
                end

                -- If product can be added, push to the items array
                if addProduct then
                    curProduct.slot = #items + 1
                    table.insert(items, curProduct)
                end
            end

            return items
        end

        TriggerServerEvent('qb-blackmarket:server:SetShopList')
        local ShopItems = { items = {}, label = data["label"] }

        -- Get the items for the shop
        ShopItems.items = SetupItems()

        -- Open inventory UI for the player with Black Market items
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "BlackMarket_" .. shop, ShopItems)
    end)
end

-- Trigger event when Black Market shop is opened
RegisterNetEvent('qb-blackmarket:openShop', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        local items = {}

        -- Ensure items exist in the configuration and check if the table is populated
        for k, v in pairs(Config.Items) do
            print("Adding item to shop:", k, v)  -- Debugging
            table.insert(items, {
                name = k,
                price = v.price,
                label = v.label
            })
        end

        -- Debugging: Show items
        print("Items to show in shop:", items)

        -- Open the shop UI for the player
        TriggerClientEvent("inventory:client:ShopOpen", src, "Black Market", items)
    end
end)

RegisterNetEvent('qb-blackmarket:purchaseItem', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local item = data.item
    local price = tonumber(data.price)

    if not Player or not item or not price then return end

    -- Check if player has enough dirty cash
    local blackMoney = Player.Functions.GetItemByName("dirtycash")

    -- Debugging: Show dirty cash
    print("Player dirty cash:", blackMoney and blackMoney.amount or "None")

    if not blackMoney or blackMoney.amount < price then
        TriggerClientEvent('QBCore:Notify', src, "Not enough dirty cash!", "error")
        return
    end

    -- Remove black money and give the item
    Player.Functions.RemoveItem("dirtycash", price)
    Player.Functions.AddItem(item, 1)

    -- Notify Player
    TriggerClientEvent('QBCore:Notify', src, "You bought " .. item .. " for $" .. price, "success")

    -- Log transactions in Discord
    TriggerEvent('qb-blackmarket:logTransaction', src, "purchase", item, 1, price) -- Fixed variable names
end)



RegisterNetEvent('qb-blackmarket:launderMoney', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local blackMoney = Player.Functions.GetItemByName("dirtycash")

    if blackMoney and blackMoney.amount >= amount then
        local cleanAmount = math.floor(amount * Config.LaunderRate)

        Player.Functions.RemoveItem("dirtycash", amount)
        Player.Functions.AddMoney("cash", cleanAmount)

        -- Logging laundering to Discord (FIXED)
        TriggerEvent('qb-blackmarket:logTransaction', src, "launder", nil, amount, cleanAmount)

        TriggerClientEvent('QBCore:Notify', src, "Laundered $" .. cleanAmount, "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Not enough Dirty Cash!", "error")
    end
end)



RegisterNetEvent('qb-blackmarket:logTransaction')
AddEventHandler('qb-blackmarket:logTransaction', function(source, transactionType, item, amount, price)
    local Player = QBCore.Functions.GetPlayer(source)
    local discordMessage = ""

    if transactionType == "launder" then
        discordMessage = string.format("**%s [%s]** laundered **$%d** dirty cash and received **$%d** clean money.", Player.PlayerData.name, Player.PlayerData.citizenid, amount, price)
    elseif transactionType == "purchase" then
        discordMessage = string.format("**%s [%s]** purchased **%dx %s** for **$%d**.", Player.PlayerData.name, Player.PlayerData.citizenid, amount, item, price)
    end

    if discordMessage ~= "" then
        PerformHttpRequest(Config.Webhook, function(err, text, headers) end, "POST", json.encode({username = "Black Market", content = discordMessage}), { ["Content-Type"] = "application/json" })
    end
end)

