fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Flyx'
version '1.2'

dependencies {
    'ox_lib'
}

client_scripts{
    'client/**.lua'
}

shared_scripts{
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'config.lua',
} 

server_scripts{
    'server/**.lua',
    '@oxmysql/lib/MySQL.lua'
}

files {
    'locales/*.json'
}