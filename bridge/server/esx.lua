if not GetResourceState('es_extended'):find('start') then return end
lib.print.info('Loaded ESX Bridge')

ESX = exports['es_extended']:getSharedObject()

Bridge = {
    GetPlayerFromId = function(playerId)
        return ESX.GetPlayerFromId(playerId)
    end,

    GetPlayerFromIdentifier = function(identifier)
        return ESX.GetPlayerFromIdentifier(identifier)
    end,

    GetPlayerName = function(xPlayer, separate)
        local xPlayer = type(xPlayer) == 'number' and Bridge.GetPlayerFromId(xPlayer) or xPlayer
        if not xPlayer or type(xPlayer) ~= 'table' then return 'Unknown' end
        if separate then
            return xPlayer.get('firstName'), xPlayer.get('lastName')
        else
            return xPlayer.get('firstName')..' '..xPlayer.get('lastName')
        end
    end,

    sendNotify = function(playerId, description, type)
        TriggerClientEvent('ox_lib:notify', playerId, {
            title = locale('notify_title'),
            description = description,
            type = type or 'info'
        })
    end,
}