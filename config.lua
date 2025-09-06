Config = {}
-- 1.2 UPDATE -> SET YOUR WEBHOOK IN server/server.lua
Config.Language = 'pl' -- pl / en
Config.Payments = { -- set to false if you don't want payments
    add = 500,
    replace = 750,
    remove = 500
}
Config.RequireConfirmation = true

Config.Ped = {
    coords = vec4(-543.81, -609.68, 35.64, 276.88),
    model = "a_m_m_business_01",
    scenario = "WORLD_HUMAN_CLIPBOARD",
    blip = { -- set to false if you don't want blip
        sprite = 326,
        color = 3,
        scale = 0.8,
        label = "Współwłaściciel pojazdu"
    }
}

lib.locale(Config.Language or 'en')