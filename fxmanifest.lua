fx_version 'cerulean'
game 'gta5'
lua54 "yes"

author 'Kamilsemm'
description 'Kamilsemm V Hud'
version '1.1.0'


ui_page 'web/index.html'

shared_script 'config.lua'

client_scripts {
    'client/framework.lua',
    'client/main.lua',
    'client/player.lua',
    'client/vehicle.lua',
    'client/minimap.lua'
}

server_script 'server/framework.lua'

files {
    'web/index.html',
    'web/css/*.css',
    'web/fonts/*.woff2',
    'web/js/*.js'
}

escrow_ignore {
    "config.lua",
}

dependency '/assetpacks'