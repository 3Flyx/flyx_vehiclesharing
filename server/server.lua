local ESX = exports.es_extended:getSharedObject()

lib.callback.register('flyx_vehiclesharing/getVehicles', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = ?', {xPlayer.identifier})
    return result
end)

lib.callback.register('flyx_vehiclesharing/getPlayerName', function(source, targetId)
    local xPlayer = ESX.GetPlayerFromId(targetId)
    if not xPlayer then return 'Nieznajomy' end

    local firstName = xPlayer.get('firstName')
    local lastName = xPlayer.get('lastName')

    return firstName..' '..lastName
end)

RegisterNetEvent('flyx_vehiclesharing/updateVehicle', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.single.await('SELECT 1 FROM owned_vehicles WHERE vin = ? AND owner = ?', {data.vin, xPlayer.identifier})
    if not result then return lib.warn('Wystąpił błąd przy pobraniu pojazdu o numerach rej. '..data.plate..' dla '..xPlayer.identifier) end

    if data.type == 'add' then
        if result.co_owner then return end
        local tPlayer = ESX.GetPlayerFromId(data.player)
        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = ? WHERE vin = ? AND owner = ?', {tPlayer.identifier, data.vin, xPlayer.identifier})
        if affectedRows then
            TriggerClientEvent('ox_lib:notify', tPlayer.source, {
                title = 'Współwłaściciel',
                description = xPlayer.firstName..' '..xPlayer.lastName..' Dodał cię jako współwłaściciela pojazdu '..result.model..' o rejestracji '..result.plate,
                type = 'info'
            })
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = 'Współwłaściciel',
                description = 'Dodałeś '..xPlayer.firstName..' '..xPlayer.lastName..' jako współwłaściciela pojazdu '..result.model..' o rejestracji '..result.plate,
                type = 'info'
            })
        end
    elseif data.type == 'replace' then
        local tPlayer = ESX.GetPlayerFromId(data.player)
        local oPlayer = ESX.GetPlayerFromIdentifier(result.co_owner)
        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = ? WHERE vin = ? AND owner = ?', {tPlayer.identifier, data.vin, xPlayer.identifier})
        if affectedRows then
            TriggerClientEvent('ox_lib:notify', tPlayer.source, {
                title = 'Współwłaściciel',
                description = xPlayer.firstName..' '..xPlayer.lastName..' Dodał cię jako współwłaściciela pojazdu '..result.model..' o rejestracji '..result.plate,
                type = 'info'
            })
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = 'Współwłaściciel',
                description = 'Dodałeś '..xPlayer.firstName..' '..xPlayer.lastName..' jako współwłaściciela pojazdu '..result.model..' o rejestracji '..result.plate,
                type = 'info'
            })
            if oPlayer then
                TriggerClientEvent('ox_lib:notify', tPlayer.source, {
                    title = 'Współwłaściciel',
                    description = xPlayer.firstName..' '..xPlayer.lastName..' Usunął cię jako współwłaściciela pojazdu '..result.model..' o rejestracji '..result.plate,
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
                description = 'Usunąłeś współwłasciciela pojazdu '..result.model..' o rejestracji '..result.plate,
                type = 'info'
            })

            if oPlayer then
                TriggerClientEvent('ox_lib:notify', oPlayer.source, {
                    title = 'Współwłaściciel',
                    description = xPlayer.firstName..' '..xPlayer.lastName..' usunął cię jako współwłaściciela pojazdu '..result.model..' o rejestracji '..result.plate,
                    type = 'error'
                })
            end
        end
    end
end)