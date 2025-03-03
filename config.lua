Config = {}

-- TON API Key (same as in ton_connect)
Config.TON_API_KEY = 'YOUR_API_KEY'

-- Check interval in minutes (60 = hourly)
Config.CheckIntervalMinutes = 60

-- NFT to Property Mapping
Config.NFT_TO_PROPERTY_MAP = {
    ["0:422fa..."] = 1,
    ["0:7a1c1..."] = 2,
    ["0:6b21b..."] = 3,
    ["0:a292b...."] = 14,
}

-- NFT to Vehicle Mapping (copied from ton_connect)
Config.NFT_TO_VEHICLE_MAP = {
    ["0:db881..."] = "amggtrr20",
    ["0:f92c4..."] = "20rs7c8",
}

-- Debug mode (set to true for more verbose logging)
Config.Debug = true 
