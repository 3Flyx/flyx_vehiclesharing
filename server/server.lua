lib.callback.register('flyx_vehiclesharing/getVehicles', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = ?', {xPlayer.identifier})
    return result
end)

lib.callback.register('flyx_vehiclesharing/getPlayers', function(source, players)
    local playerNames = {}
    for _, player in ipairs(players) do
        local tPlayer = ESX.GetPlayerFromId(player)
        if tPlayer then
            playerNames[player] = tPlayer.get('firstName')..' '..tPlayer.get('lastName')
        end
    end
    return playerNames
end)

RegisterNetEvent('flyx_vehiclesharing/updateVehicle', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.single.await('SELECT * FROM owned_vehicles WHERE vin = ? AND owner = ?', {data.vin, xPlayer.identifier})
    if not result then return lib.warn('Wystąpił błąd przy pobraniu pojazdu o numerze VIN: '..data.vin..' dla '..xPlayer.identifier) end
    local vehData = json.decode(result.vehicle)

    if data.type == 'add' then
        if result.co_owner then return end
        local tPlayer = ESX.GetPlayerFromId(data.player)
        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = ? WHERE vin = ? AND owner = ?', {tPlayer.identifier, data.vin, xPlayer.identifier})
        if affectedRows then
            TriggerClientEvent('ox_lib:notify', tPlayer.source, {
                title = 'Współwłaściciel',
                description = xPlayer.get('firstName')..' '..xPlayer.get('lastName')..' Dodał cię jako współwłaściciela pojazdu '..data.display..' o rejestracji '..result.plate,
                type = 'info'
            })
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = 'Współwłaściciel',
                description = 'Dodałeś '..tPlayer.get('firstName')..' '..tPlayer.get('lastName')..' jako współwłaściciela pojazdu '..data.display..' o rejestracji '..result.plate,
                type = 'info'
            })
        end
    elseif data.type == 'replace' then
        local tPlayer = ESX.GetPlayerFromId(data.player)
        local oPlayer = ESX.GetPlayerFromIdentifier(result.co_owner)
        if oPlayer and tPlayer.identifier == oPlayer.identifier then 
            return TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = 'Współwłaściciel',
                description = 'Nie możesz zmienić współwłaściciela na tego samego!',
                type = 'info'
            })
        end
        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = ? WHERE vin = ? AND owner = ?', {tPlayer.identifier, data.vin, xPlayer.identifier})
        if affectedRows then
            TriggerClientEvent('ox_lib:notify', tPlayer.source, {
                title = 'Współwłaściciel',
                description = xPlayer.get('firstName')..' '..xPlayer.get('lastName')..' Dodał cię jako współwłaściciela pojazdu '..data.display..' o rejestracji '..result.plate,
                type = 'info'
            })
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = 'Współwłaściciel',
                description = 'Dodałeś '..tPlayer.get('firstName')..' '..tPlayer.get('lastName')..' jako współwłaściciela pojazdu '..data.display..' o rejestracji '..result.plate,
                type = 'info'
            })
            if oPlayer then
                TriggerClientEvent('ox_lib:notify', oPlayer.source, {
                    title = 'Współwłaściciel',
                    description = xPlayer.get('firstName')..' '..xPlayer.get('lastName')..' Usunął cię jako współwłaściciela pojazdu '..data.display..' o rejestracji '..result.plate,
                    type = 'info'
                })
            end
        end
    elseif data.type == 'remove' then
        if not result.co_owner then
            return TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = 'Współwłaściciel',
                description = 'Ten pojazd nie ma współwłaściciela.',
                type = 'error'
            })
        end

        local oPlayer = ESX.GetPlayerFromIdentifier(result.co_owner)
        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = NULL WHERE vin = ? AND owner = ?', {data.vin, xPlayer.identifier})
        if affectedRows then
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = 'Współwłaściciel',
                description = 'Usunąłeś współwłasciciela pojazdu '..data.display..' o rejestracji '..result.plate,
                type = 'info'
            })

            if oPlayer then
                TriggerClientEvent('ox_lib:notify', oPlayer.source, {
                    title = 'Współwłaściciel',
                    description = xPlayer.get('firstName')..' '..xPlayer.get('lastName')..' usunął cię jako współwłaściciela pojazdu '..data.display..' o rejestracji '..result.plate,
                    type = 'error'
                })
            end
        end
    end
end)