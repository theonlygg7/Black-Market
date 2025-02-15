local QBCore = exports['qb-core']:GetCoreObject()
local currentBlackMarketLocation = nil
local spawnedPed = nil

-- Function to select a new black market location each month
function SelectBlackMarketLocation()
    math.randomseed(GetGameTimer()) -- Ensure randomness
    currentBlackMarketLocation = Config.BlackMarketLocations[math.random(#Config.BlackMarketLocations)]
end

-- Function to spawn a black market ped
function SpawnBlackMarketPed()
    if not currentBlackMarketLocation then return end

    -- Delete old ped if it exists
    if spawnedPed and DoesEntityExist(spawnedPed) then
        DeleteEntity(spawnedPed)
    end

    local model = `a_m_m_og_boss_01` -- Black market boss ped model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end

    spawnedPed = CreatePed(4, model, currentBlackMarketLocation.x, currentBlackMarketLocation.y, currentBlackMarketLocation.z - 1.0, 0.0, false, true)
    SetEntityHeading(spawnedPed, 180.0)
    FreezeEntityPosition(spawnedPed, true)
    SetEntityInvincible(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)

    -- Add interaction using qb-target
    exports['qb-target']:AddTargetEntity(spawnedPed, {
        options = {
            {
                label = "Open Black Market",
                icon = "fas fa-shopping-cart",
                action = function()
                    print("Opening Black Market Shop...")  -- Debugging log
                    TriggerServerEvent('qb-blackmarket:openShop', "blackmarket", { label = "Black Market" })
                end
            },
            {
                label = "Launder Money",
                icon = "fas fa-money-bill-wave",
                action = function()
                    local amount = tonumber(KeyboardInput("Enter amount to launder:", "", 10))  -- Prompt for amount
                    if amount and amount > 0 then
                        TriggerServerEvent('qb-blackmarket:launderMoney', amount)
                    else
                        QBCore.Functions.Notify("Invalid amount!", "error")
                    end
                end
            }
        },
        distance = 2.0
    })
end

-- Function to rotate black market location every month
function RotateBlackMarketLocation()
    SelectBlackMarketLocation()
    SpawnBlackMarketPed()
end

-- Initialize Black Market
CreateThread(function()
    Wait(2000) -- Wait for resources to load
    RotateBlackMarketLocation() -- Select initial location and spawn ped

    -- Set up a timer to rotate the location every 30 days (real-time)
    local oneMonth = 30 * 24 * 60 * 60 * 1000  -- 30 days in milliseconds
    while true do
        Wait(oneMonth)
        RotateBlackMarketLocation()
    end
end)

-- Keyboard Input function for money laundering
function KeyboardInput(text, example, maxLength)
    AddTextEntry('FMMC_KEY_TIP1', text)
    DisplayOnscreenKeyboard(1, 'FMMC_KEY_TIP1', '', example, '', '', '', maxLength)

    while UpdateOnscreenKeyboard() == 0 do
        Wait(0)
    end

    if GetOnscreenKeyboardResult() then
        return GetOnscreenKeyboardResult()
    end
    return nil
end

-- Trigger shop opening UI
RegisterNetEvent('inventory:client:ShopOpen', function(shopName, items)
    print("Opening shop: " .. shopName)  -- Debugging: Ensure shop is opening
    
    local menuItems = {}

    -- Loop through the items and construct the menu
    for _, item in ipairs(items) do
        print("Adding item to menu:", item.label, item.price)  -- Debugging

        table.insert(menuItems, {
            header = item.label,
            txt = "Price: $" .. item.price,
            params = {
                event = "qb-blackmarket:purchaseItem",
                args = { item = item.name, price = item.price }
            }
        })
    end

    -- Add a close option
    table.insert(menuItems, {
        header = "Close",
        params = { event = "qb-menu:client:closeMenu" }
    })

    -- Open the menu
    exports['qb-menu']:openMenu(menuItems)
end)

RegisterNetEvent('qb-blackmarket:purchaseItem', function(data)
    if not data or not data.item or not data.price then
        print("^1Error: Missing item or price in qb-blackmarket:purchaseItem^7")
        return
    end

    print("Purchasing item:", data.item, "Price:", data.price)  -- Debugging
    TriggerServerEvent('qb-blackmarket:purchaseItem', data)  -- Send purchase request to server
end)

RegisterNUICallback("purchaseItem", function(data, cb)
    if data and data.item and data.price then
        TriggerServerEvent('qb-blackmarket:purchaseItem', data)
        print("Client: Sending purchase request -", json.encode(data))
    else
        print("^1Error: Invalid purchase data!^7", json.encode(data))
    end
    cb("ok")
end)

-- Launder Money Prompt
RegisterNetEvent('qb-blackmarket:launderMoneyPrompt', function()
    local amount = tonumber(KeyboardInput("Enter amount to launder:", "", 10)) -- Show prompt for laundering
    if amount and amount > 0 then
        TriggerServerEvent('qb-blackmarket:launderMoney', amount) -- Trigger server event to launder money
    else
        QBCore.Functions.Notify("Invalid amount!", "error")
    end
end)

exports('openMenu', openMenu)
exports('closeMenu', closeMenu)
exports('showHeader', showHeader)
