if not Config.Framework == string.upper('ESX') then return end

Bridge = {
    GetPlayerFromId = function(playerId)
        return ESX.GetPlayerFromId(playerId)
    end,

    GetPlayerFromIdentifier = function(identifier)
        return ESX.GetPlayerFromIdentifier(identifier)
    end,

    sendNotify = function(playerId, description, type)
        TriggerClientEvent('ox_lib:notify', playerId, {
            title = locale('notify_title'),
            description = description,
            type = type or 'info'
        })
    end
}