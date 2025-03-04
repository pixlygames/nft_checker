fx_version 'cerulean'
game 'gta5'

author 'Pixly Games'

description 'NFT Checker - Verifies NFT ownership and revokes assets when NFTs are no longer owned'
version '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server.lua'
}

lua54 'yes' 
