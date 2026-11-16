fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Tnoxious'
description 'Two bus jobs for WhipFX: a City Bus line and a Dashound coach line, with worker clothing, depot clerks, extra bus stops and job area props.'
version '2.0.0'

-- The stream folder adds the extra bus stops and job area props
this_is_a_map 'yes'

dependency 'whip_core'
whip_requires '1.0'

shared_scripts {
    '@whip_core/lib/satellite.lua',
    'shared/locale.lua',
    'locales/*.lua',
    'config/config.lua',
    'config/locations.lua',
}

client_script 'client/busjob.lua'
server_script 'server/main.lua'
