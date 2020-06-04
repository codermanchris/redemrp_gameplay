fx_version 'adamant'
games { 'rdr3' }
version '0.0.1'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    
    'config.lua',
    'server/_helpers.lua',
    'server/players.lua',
    'server/bountyhunter.lua',
    'server/delivery.lua',
    'server/doctor.lua',
    'server/farmhand.lua',
    'server/fisher.lua',
    'server/generalstore.lua',
    'server/hunter.lua',
    'server/lawman.lua',
    'server/moonshiner.lua',
    'server/posse.lua',
    'server/vehiclerental.lua',
}

client_scripts {
    'config.lua',
    'client/_helpers.lua',
    'client/localplayer.lua',
    'client/bountyhunter.lua',
    'client/delivery.lua',
    'client/doctor.lua',
    'client/farmhand.lua',
    'client/fisher.lua',
    'client/generalstore.lua',
    'client/hunter.lua',
    'client/lawman.lua',
    'client/moonshiner.lua',
    'client/posse.lua',
    'client/vehiclerental.lua',
}

ui_page 'client/ui/ui.html'
files {
    -- 3rd party
    'client/ui/js/3rdParty/radialprogress.js',
    'client/ui/fonts/chineserocksrg.ttf',

    -- redemrp_gameplay
    'client/ui/ui.html',

    -- css
    'client/ui/css/ui.css',

    -- javascript
    'client/ui/js/config.js',
    'client/ui/js/core.js',
    'client/ui/js/dialogs.js',
    'client/ui/js/bountyhunter.js',
    'client/ui/js/delivery.js',
    'client/ui/js/doctor.js',
    'client/ui/js/farmhand.js',
    'client/ui/js/fisher.js',
    'client/ui/js/hunter.js',
    'client/ui/js/lawman.js',
    'client/ui/js/moonshiner.js',
    'client/ui/js/posse.js',
    'client/ui/js/vehiclerental.js',

    -- images
    'client/ui/images/wanted.jpg',
    'client/ui/images/woodpanels.jpg',
    'client/ui/images/oldparchmentbg.jpg',
}
