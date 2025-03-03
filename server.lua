local QBCore = exports['qb-core']:GetCoreObject()

-- Global timestamp of last API call for rate limiting
local lastApiCallTime = 0

-- Debug print function
local function DebugPrint(message)
    if Config.Debug then
        print('[NFT Checker] ' .. message)
    end
end

-- Function to fetch NFTs from TON API
local function FetchNFTs(walletAddress, callback)
    DebugPrint("Fetching NFTs for wallet: " .. walletAddress)
    
    -- Apply rate limiting safely
    local currentTime = os.time()
    local waitTime = 0
    if currentTime - lastApiCallTime < 1 then
        waitTime = 1000 -- milliseconds
    end
    
    -- Use SetTimeout to avoid blocking the main thread
    SetTimeout(waitTime, function()
        lastApiCallTime = os.time()
        
        PerformHttpRequest('https://tonapi.io/v2/accounts/' .. walletAddress .. '/nfts', function(statusCode, responseText, headers)
            local response = json.decode(responseText or "{}")
            if statusCode == 200 and response and response.nft_items then
                DebugPrint("Successfully fetched NFTs, count: " .. #response.nft_items)
                callback(response.nft_items)
            else
                DebugPrint("Error fetching NFTs: Status " .. (statusCode or "unknown"))
                if responseText then
                    DebugPrint("Response: " .. responseText)
                end
                callback({})
            end
        end, 'GET', '', {['Authorization'] = 'Bearer ' .. Config.TON_API_KEY})
    end)
end

-- Function to revoke a vehicle from a player
local function RevokeVehicle(citizenId, vehicleModel)
    DebugPrint("Revoking vehicle " .. vehicleModel .. " from citizen " .. citizenId)
    
    MySQL.Async.fetchAll('SELECT plate FROM player_vehicles WHERE citizenid = ? AND vehicle = ?', 
        {citizenId, vehicleModel},
        function(result)
            if result and #result > 0 then
                local plate = result[1].plate
                
                -- Remove vehicle from database
                MySQL.Async.execute('DELETE FROM player_vehicles WHERE citizenid = ? AND vehicle = ?',
                    {citizenId, vehicleModel},
                    function(rowsChanged)
                        if rowsChanged > 0 then
                            DebugPrint("Successfully removed vehicle " .. vehicleModel .. " with plate " .. plate .. " from citizen " .. citizenId)
                            
                            -- Find player if online to notify them
                            local player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
                            if player then
                                TriggerClientEvent('QBCore:Notify', player.PlayerData.source, 'Vehicle ' .. vehicleModel .. ' has been removed - NFT not found', 'error')
                            end
                        end
                    end
                )
            else
                DebugPrint("No vehicle " .. vehicleModel .. " found for citizen " .. citizenId)
            end
        end
    )
end

-- Function to revoke a property from a player
local function RevokeProperty(citizenId, propertyId)
    DebugPrint("Revoking property " .. propertyId .. " from citizen " .. citizenId)
    
    MySQL.Async.execute('UPDATE properties SET owner_citizenid = NULL, for_sale = 1 WHERE property_id = ? AND owner_citizenid = ?',
        {propertyId, citizenId},
        function(rowsChanged)
            if rowsChanged > 0 then
                DebugPrint("Successfully removed property " .. propertyId .. " from citizen " .. citizenId)
                
                -- Broadcast property update to all clients
                TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateOwner", propertyId, nil)
                TriggerClientEvent("ps-housing:client:updateProperty", -1, "UpdateForSale", propertyId, 1)
                
                -- Find player if online to notify them
                local player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
                if player then
                    TriggerClientEvent('QBCore:Notify', player.PlayerData.source, 'Property ' .. propertyId .. ' has been removed - NFT not found', 'error')
                end
            else
                DebugPrint("No property " .. propertyId .. " found for citizen " .. citizenId .. " or update failed")
            end
        end
    )
end

-- Function to check NFTs for a specific player
local function CheckPlayerNFTs(citizenId, walletAddress)
    DebugPrint("Checking NFTs for citizen " .. citizenId .. " with wallet " .. walletAddress)
    
    FetchNFTs(walletAddress, function(nftItems)
        -- Create maps of owned NFT addresses for quick lookup
        local ownedPropertyNFTs = {}
        local ownedVehicleNFTs = {}
        
        for _, nft in ipairs(nftItems) do
            local nftAddress = nft.address
            
            -- Check if this NFT is for a property
            if Config.NFT_TO_PROPERTY_MAP[nftAddress] then
                ownedPropertyNFTs[Config.NFT_TO_PROPERTY_MAP[nftAddress]] = true
            end
            
            -- Check if this NFT is for a vehicle
            if Config.NFT_TO_VEHICLE_MAP[nftAddress] then
                ownedVehicleNFTs[Config.NFT_TO_VEHICLE_MAP[nftAddress]] = true
            end
        end
        
        -- Check properties ownership
        for nftAddress, propertyId in pairs(Config.NFT_TO_PROPERTY_MAP) do
            if not ownedPropertyNFTs[propertyId] then
                -- Check if player owns this property
                MySQL.Async.fetchAll('SELECT * FROM properties WHERE property_id = ? AND owner_citizenid = ?',
                    {propertyId, citizenId},
                    function(result)
                        if result and #result > 0 then
                            -- Player owns property but doesn't have the NFT, revoke it
                            RevokeProperty(citizenId, propertyId)
                        end
                    end
                )
            end
        end
        
        -- Check vehicles ownership
        for nftAddress, vehicleModel in pairs(Config.NFT_TO_VEHICLE_MAP) do
            if not ownedVehicleNFTs[vehicleModel] then
                -- Check if player owns this vehicle
                MySQL.Async.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND vehicle = ?',
                    {citizenId, vehicleModel},
                    function(result)
                        if result and #result > 0 then
                            -- Player owns vehicle but doesn't have the NFT, revoke it
                            RevokeVehicle(citizenId, vehicleModel)
                        end
                    end
                )
            end
        end
    end)
end

-- Main function to check all wallet mappings
local function CheckAllWalletMappings()
    DebugPrint("Starting NFT ownership verification for all wallet mappings")
    
    MySQL.Async.fetchAll('SELECT citizen_id, wallet_address FROM wallet_mappings', {}, function(results)
        if results and #results > 0 then
            DebugPrint("Found " .. #results .. " wallet mappings to check")
            
            for _, mapping in ipairs(results) do
                local citizenId = mapping.citizen_id
                local walletAddress = mapping.wallet_address
                
                if citizenId and walletAddress and walletAddress ~= "" then
                    -- Process with a small delay between each to avoid rate limiting
                    SetTimeout(1000, function()
                        CheckPlayerNFTs(citizenId, walletAddress)
                    end)
                end
            end
        else
            DebugPrint("No wallet mappings found")
        end
    end)
end

-- Register command to manually trigger check
RegisterCommand('checknfts', function(source, args, rawCommand)
    if source == 0 or QBCore.Functions.HasPermission(source, 'admin') then
        DebugPrint("NFT check manually triggered by " .. (source == 0 and "console" or GetPlayerName(source)))
        CheckAllWalletMappings()
        
        if source > 0 then
            TriggerClientEvent('QBCore:Notify', source, 'NFT ownership verification started', 'success')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'You do not have permission to use this command', 'error')
    end
end, true)

-- Start periodic check
CreateThread(function()
    -- Wait for server to fully start
    Wait(10000)
    
    DebugPrint("NFT Checker resource started")
    
    -- Run initial check
    CheckAllWalletMappings()
    
    -- Set up periodic check
    while true do
        -- Wait for the configured interval (in minutes)
        local waitTime = Config.CheckIntervalMinutes * 60 * 1000
        Wait(waitTime)
        
        DebugPrint("Running scheduled NFT ownership verification")
        CheckAllWalletMappings()
    end
end) 