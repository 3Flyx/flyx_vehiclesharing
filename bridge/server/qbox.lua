if string.upper(Config.Framework) ~= 'QBOX' then return end

Bridge = {
    GetPlayerFromId = function(playerId)
        return exports.qbx_core:GetPlayer(playerId)
    end,

    GetPlayerFromIdentifier = function(identifier)
        local xPlayer = exports['qbx_core']:GetPlayerByCitizenId(identifier)
        if not xPlayer then return nil end
        xPlayer.source = xPlayer.PlayerData.source
        xPlayer.identifier = xPlayer.PlayerData.citizenid
        return xPlayer
    end,
    
    sendNotify = function(playerId, description, type)
        TriggerClientEvent('ox_lib:notify', playerId, {
            title = locale('notify_title'),
            description = description,
            type = type or 'info'
        })
    end
}