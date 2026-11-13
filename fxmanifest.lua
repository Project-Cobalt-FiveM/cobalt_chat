fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'cobalt_chat'
author 'Citgo'
description 'Project Cobalt chat: proximity by default, scoped channels, no persistence'
version '1.0.0'

provide 'chat'

dependencies {
    'ox_lib',
    'cobalt_core',
}

shared_script '@ox_lib/init.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page '_nui/build/index.html'

files {
    'config.lua',
    'client/*.lua',
    '_nui/build/index.html',
    '_nui/build/assets/*',
}
