# NFT Checker

A standalone FiveM resource for QBCore framework that periodically checks NFT ownership and revokes in-game assets (vehicles and properties) when the corresponding NFTs are no longer owned.

## Features

- Hourly automatic verification of NFT ownership
- Revokes vehicles and properties when NFTs are no longer owned
- Admin command to manually trigger verification
- Detailed logging for debugging
- Rate limiting to prevent API throttling

## Installation

1. Copy the `nft_checker` folder to your server's resources directory
2. Add `ensure nft_checker` to your server.cfg
3. Configure the `config.lua` file to match your NFT mappings
4. Restart your server

## Configuration

Edit the `config.lua` file to customize:

- TON API Key
- Check interval (in minutes)
- NFT to property mappings
- NFT to vehicle mappings
- Debug mode

## Dependencies

- QBCore Framework
- oxmysql
- ps-housing (for property management)
- qb-vehiclekeys (for vehicle key management)

## Commands

- `/checknfts` - Manually trigger NFT ownership verification (admin only)

## How It Works

1. The resource checks the `wallet_mappings` table to find all player wallet addresses
2. For each wallet, it fetches the current NFTs from the TON API
3. It compares the NFTs against the configured mappings
4. If a player has a vehicle or property in-game but no longer owns the corresponding NFT:
   - Vehicles: Removed from the `player_vehicles` table
   - Properties: Owner set to NULL and marked for sale in the `properties` table
5. Players are notified if they are online when assets are revoked

## Database Tables

The resource uses the following tables:
- `wallet_mappings` - Maps player CitizenIDs to TON wallet addresses
- `player_vehicles` - QBCore's vehicle ownership table
- `properties` - Property ownership table (from ps-housing)

## Credits

- Original TON Connect implementation from the ton_connect resource
- QBCore Framework team 