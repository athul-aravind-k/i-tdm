fx_version 'cerulean'

game 'gta5'

description 'Insane Death-Match'

shared_scripts {
    'config.lua',
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/ComboZone.lua',
    'client/main.lua',
}

lua54 'yes'

files {
    'html/*.html',
    'html/*.css',
    'html/*.js',
    'html/assets/*.*',
    'html/assets/maps/*.*'
}

ui_page {
    'html/index.html'
}

dependencies {
    'qb-core',
    'PolyZone',
}
