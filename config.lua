Config = {}

-- Black Market Locations (can be rotated monthly)
Config.BlackMarketLocations = {
    vector3(-1094.9491, -2795.1938, 44.5575),
--   vector3(472.6172, 4815.8511, -58.3913),
 --   vector3(487.2386, 4820.0161, -58.3829) -- Add as many as needed
}

-- Black Market Items
Config.Items = {
    ["lockpick"] = { price = 500, label = "Lockpick" },
    ["weapon_ceramicpistol"] = { price = 18500, label = "Ceramic Pistol" }
-- Add more items here
}

-- Money Laundering (70% return rate)
Config.LaunderRate = 0.6

-- Discord Webhook for Logs
Config.Webhook = "YOUR_WEBHOOK_HERE"
