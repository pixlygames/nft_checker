Config = {}

-- TON API Key (same as in ton_connect)
Config.TON_API_KEY = 'AFN7E2R5CF75OGIAAAAFWUNDQNZPA2ZAOHCEWW5NOCJ6Z3T7SBL6JMCCDFFKBNOPAUZX2NQ'

-- Check interval in minutes (60 = hourly)
Config.CheckIntervalMinutes = 60

-- NFT to Property Mapping (copied from ton_connect)
Config.NFT_TO_PROPERTY_MAP = {
    ["0:422fa1d5c33ff35b7d235378b31ab411640fcf07bf1bd3483a7cae3a6780d94c"] = 9,
    ["0:7a1c1cc5f4b53f460db889242b28147052b6ce65f984730c8e68659ce85320fc"] = 3,
    ["0:6b21b3a17d97396889648f39b5321e88366edf5984090da95b43c21d65757f61"] = 4,
    ["0:a292bd1986590a0bcc9198cd8964e86eb3aff65d8c619b9c898dc708ed86d0d9"] = 17,
}

-- NFT to Vehicle Mapping (copied from ton_connect)
Config.NFT_TO_VEHICLE_MAP = {
    ["0:db881fe436dbdf3060f0757fcb4c646e71d3f959705b7f2f029dee66a688274f"] = "amggtrr20",
    ["0:f92c4b1328db68a1f35a2ccaed9874a21d3f77b999187124cf27ca27abcf8f05"] = "20rs7c8",
}

-- Debug mode (set to true for more verbose logging)
Config.Debug = true 