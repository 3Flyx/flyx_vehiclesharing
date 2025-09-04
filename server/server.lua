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
    if not data.vin then return end
    local result = MySQL.single.await('SELECT * FROM owned_vehicles WHERE vin = ? AND owner = ?', {data.vin, xPlayer.identifier})
    if not result then return lib.warn(locale('error_getting_vehicle'):format(data.vin, xPlayer.identifier)) end

    -- 1.1 PAYMENT ADDED
    if Config.Payments then
        local paymentType = lib.callback.await('flyx_vehiclesharing/PaymentDialog', source)
        local payment = ProcessPayment(source, paymentType, data.type)
        if not payment then return end
    end

    if data.type == 'add' then
        if result.co_owner then 
            return TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = locale('notify_title'),
                description = locale('existing_coowner'),
                type = 'error'
            })
        end
        local tPlayer = ESX.GetPlayerFromId(data.player)
        
        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = ? WHERE vin = ? AND owner = ?', {tPlayer.identifier, data.vin, xPlayer.identifier})
        if affectedRows then
            TriggerClientEvent('ox_lib:notify', tPlayer.source, {
                title = locale('notify_title'),
                description = locale('added_you_as_vehicle_coowner'):format(xPlayer.get('firstName'), xPlayer.get('lastName'), data.display, result.plate),
                type = 'info'
            })
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = locale('notify_title'),
                description = locale('added_a_vehicle_coowner'):format(tPlayer.get('firstName'), tPlayer.get('lastName'), data.display, result.plate),
                type = 'info'
            })
        end
    elseif data.type == 'replace' then
        local tPlayer = ESX.GetPlayerFromId(data.player)
        local oPlayer = ESX.GetPlayerFromIdentifier(result.co_owner)
        if oPlayer and tPlayer.identifier == oPlayer.identifier then 
            return TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = locale('notify_title'),
                description = locale('coowner_same'),
                type = 'info'
            })
        end

        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = ? WHERE vin = ? AND owner = ?', {tPlayer.identifier, data.vin, xPlayer.identifier})
        if affectedRows then
            TriggerClientEvent('ox_lib:notify', tPlayer.source, {
                title = locale('notify_title'),
                description = locale('added_you_as_vehicle_coowner'):format(xPlayer.get('firstName'), xPlayer.get('lastName'), data.display, result.plate),
                type = 'info'
            })
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = locale('notify_title'),
                description = locale('added_a_vehicle_coowner'):format(tPlayer.get('firstName'), tPlayer.get('lastName'), data.display, result.plate),
                type = 'info'
            })
            if oPlayer then
                TriggerClientEvent('ox_lib:notify', oPlayer.source, {
                    title = locale('notify_title'),
                    description = locale('removed_as_vehicle_coowner'):format(xPlayer.get('firstName'), xPlayer.get('lastName'), data.display, result.plate),
                    type = 'info'
                })
            end
        end
    elseif data.type == 'remove' then
        if not result.co_owner then
            return TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = locale('notify_title'),
                description = locale('no_coowner'),
                type = 'error'
            })
        end

        local oPlayer = ESX.GetPlayerFromIdentifier(result.co_owner)
        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = NULL WHERE vin = ? AND owner = ?', {data.vin, xPlayer.identifier})
        if affectedRows then
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = locale('notify_title'),
                description = locale('removed_a_vehicle_coowner'):format(data.display, result.plate),
                type = 'info'
            })

            if oPlayer then
                TriggerClientEvent('ox_lib:notify', oPlayer.source, {
                    title = locale('notify_title'),
                    description = locale('removed_as_vehicle_coowner'):format(xPlayer.get('firstName'), xPlayer.get('lastName'), data.display, result.plate),
                    type = 'error'
                })
            end
        end
    end
end)

function ProcessPayment(source, paymentType, updateType)
    local xPlayer = ESX.GetPlayerFromId(source)
    local amount = Config.Payments[updateType]
    if paymentType == 'cash' then
        local moneyCount = exports.ox_inventory:GetItemCount(source, 'money', nil, false)
        if moneyCount < amount then
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = locale('notify_title'),
                description = locale('no_money'),
                type = 'error'
            })
            return false
        end

        if not exports.ox_inventory:RemoveItem(source, 'money', amount) then
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = locale('notify_title'),
                description = locale('no_money'),
                type = 'error'
            })
            return false
        end

        return true
    elseif paymentType == 'card' then
        local money = xPlayer.getMoney()
        if money < amount then
            TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = locale('notify_title'),
                description = locale('no_bank_money'),
                type = 'error'
            })
            return false
        end

        xPlayer.removeAccountMoney("bank", amount, locale('payment_'..tostring(updateType)))
        
        return true
    end
end