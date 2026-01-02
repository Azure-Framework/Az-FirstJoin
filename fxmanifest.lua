fx_version 'cerulean'
game 'gta5'

author 'Azure(TheStoicBear)'
description 'Welcome popup on first movement + /firstcar 24h KVP cooldown'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

dependency 'ox_lib'
