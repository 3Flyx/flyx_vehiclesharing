if not GetResourceState('qbx_core'):find('start') then return end
lib.print.info('Loaded QBOX Bridge')

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

    GetPlayerName = function(xPlayer, separate)
        local xPlayer = type(xPlayer) == 'number' and Bridge.GetPlayerFromId(xPlayer) or xPlayer
        if not xPlayer or type(xPlayer) ~= 'table' then return 'Unknown' end
        if separate then
            return xPlayer.PlayerData.charinfo.firstname, xPlayer.PlayerData.charinfo.lastname
        else
            return xPlayer.PlayerData.charinfo.firstname..' '..xPlayer.PlayerData.charinfo.lastname
        end
    end,
    
    sendNotify = function(playerId, description, type)
        TriggerClientEvent('ox_lib:notify', playerId, {
            title = locale('notify_title'),
            description = description,
            type = type or 'info'
        })
    end
}