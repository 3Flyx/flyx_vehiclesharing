local webhook = 'YOUR WEBHOOK HERE'

lib.callback.register('flyx_vehiclesharing/getVehicles', function(source)
    local xPlayer = Bridge.GetPlayerFromId(source)
    local result = MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = ?', {xPlayer.identifier})
    return result
end)

lib.callback.register('flyx_vehiclesharing/getPlayers', function(source, players)
    local playerNames = {}
    for _, player in ipairs(players) do
        local tPlayer = Bridge.GetPlayerFromId(player)
        if tPlayer then
            playerNames[player] = Bridge.GetPlayerName(tPlayer, false)
        end
    end
    return playerNames
end)

RegisterNetEvent('flyx_vehiclesharing/updateVehicle', function(data)
    local xPlayer = Bridge.GetPlayerFromId(source)
    if not data.vin then return end
    local result = MySQL.single.await('SELECT * FROM owned_vehicles WHERE vin = ? AND owner = ?', {data.vin, xPlayer.identifier})
    if not result then return lib.warn(locale('error_getting_vehicle'):format(data.vin, xPlayer.identifier)) end

    -- 1.1 PAYMENT ADDED
    if Config.Payments then
        local paymentType = lib.callback.await('flyx_vehiclesharing/PaymentDialog', xPlayer.source)
        local payment = ProcessPayment(xPlayer.source, paymentType, data.type)
        if not payment then return end
    end

    if data.type == 'add' then
        if result.co_owner then 
            Bridge.sendNotify(xPlayer.source, locale('existing_coowner'), 'error')
            return 
        end
        local tPlayer = Bridge.GetPlayerFromId(data.player)
        if not tPlayer then return end

        if Config.RequireConfirmation then
            local confirmation = lib.callback.await('flyx_vehiclesharing/ConfirmationDialog', tPlayer.source, {
                playerName = Bridge.GetPlayerName(xPlayer, false), 
                model = data.model, 
                plate = result.plate
            })
            if not confirmation then
                Bridge.sendNotify(xPlayer.source, locale('player_rejected'), 'error')
                return
            end
        end

        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = ? WHERE vin = ? AND owner = ?', {tPlayer.identifier, data.vin, xPlayer.identifier})
        if affectedRows then
            --DISCORD LOG
            SendDiscordLog(source, locale('log_added'):format(xPlayer.get('firstName')..' '..xPlayer.get('lastName'), tPlayer.get('firstName')..' '..tPlayer.get('lastName'), tPlayer.identifier, data.display, result.model, data.vin))

            Bridge.sendNotify(tPlayer.source, locale('added_you_as_vehicle_coowner'):format(xPlayer.get('firstName'), xPlayer.get('lastName'), data.display, result.plate), 'info')
            Bridge.sendNotify(xPlayer.source, locale('added_a_vehicle_coowner'):format(tPlayer.get('firstName'), tPlayer.get('lastName'), data.display, result.plate), 'info')
        end
    elseif data.type == 'replace' then
        local tPlayer = Bridge.GetPlayerFromId(data.player)
        local oPlayer = Bridge.GetPlayerFromIdentifier(result.co_owner)
        if oPlayer and tPlayer.identifier == oPlayer.identifier then 
            Bridge.sendNotify(xPlayer.source, locale('coowner_same'), 'info')
            return 
        end

        if Config.RequireConfirmation then
            local confirmation = lib.callback.await('flyx_vehiclesharing/ConfirmationDialog', tPlayer.source, {
                playerName = Bridge.GetPlayerName(xPlayer, false), 
                model = data.model, 
                plate = result.plate
            })
            if not confirmation then
                Bridge.sendNotify(xPlayer.source, locale('player_rejected'), 'error')
                return
            end
        end

        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = ? WHERE vin = ? AND owner = ?', {tPlayer.identifier, data.vin, xPlayer.identifier})
        if affectedRows then
            Bridge.sendNotify(tPlayer.source, locale('added_you_as_vehicle_coowner'):format(xPlayer.get('firstName'), xPlayer.get('lastName'), data.display, result.plate), 'info')
            Bridge.sendNotify(xPlayer.source, locale('added_a_vehicle_coowner'):format(tPlayer.get('firstName'), tPlayer.get('lastName'), data.display, result.plate), 'info')

            if oPlayer then
                Bridge.sendNotify(oPlayer.source, locale('removed_as_vehicle_coowner'):format(xPlayer.get('firstName'), xPlayer.get('lastName'), data.display, result.plate), 'info')
            end
        end
    elseif data.type == 'remove' then
        if not result.co_owner then
            Bridge.sendNotify(xPlayer.source, locale('no_coowner'), 'error')
            return 
        end

        local oPlayer = Bridge.GetPlayerFromIdentifier(result.co_owner)
        local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET co_owner = NULL WHERE vin = ? AND owner = ?', {data.vin, xPlayer.identifier})
        if affectedRows then
            Bridge.sendNotify(xPlayer.source, locale('removed_a_vehicle_coowner'):format(data.display, result.plate), 'info')

            if oPlayer then
                Bridge.sendNotify(oPlayer.source, locale('removed_as_vehicle_coowner'):format(xPlayer.get('firstName'), xPlayer.get('lastName'), data.display, result.plate), 'error')
            end
        end
    end
end)

function ProcessPayment(source, paymentType, updateType)
    local xPlayer = Bridge.GetPlayerFromId(source)
    local amount = Config.Payments[updateType]
    if paymentType == 'cash' then
        local moneyCount = exports.ox_inventory:GetItemCount(source, 'money', nil, false)
        if moneyCount < amount then
            Bridge.sendNotify(xPlayer.source, locale('no_money'), 'error')
            return false
        end

        if not exports.ox_inventory:RemoveItem(source, 'money', amount) then
            Bridge.sendNotify(xPlayer.source, locale('no_money'), 'error')
            return false
        end

        return true
    elseif paymentType == 'card' then
        local money = xPlayer.getMoney()
        if money < amount then
            Bridge.sendNotify(xPlayer.source, locale('no_bank_money'), 'error')
            return false
        end

        xPlayer.removeAccountMoney("bank", amount, locale('payment_'..tostring(updateType)))
        return true
    end
end

function SendDiscordLog(playerId, message)
    if not Config.Logs then return end
    if not webhook then return end
    local steamName, steamHex, discordId = 'Unknown', 'Unknown', 'Unknown'
    if playerId then
        steamName = GetPlayerName(playerId)
        local identifiers = GetPlayerIdentifiers(playerId)
        for i = 1, #identifiers do
            if string.find(identifiers[i], 'steam:') then
                steamHex = identifiers[i]
            elseif string.find(identifiers[i], 'discord:') then
                discordId = string.gsub(identifiers[i], 'discord:', '')
            end
        end
    end

    message = message..'\nID: '..(playerId or 'Server')..'\nSteam Name: '..steamName..'\nSteam HEX: '..steamHex..'\nDiscord: <@'..discordId..'>'
	local embedData = { {
		['title'] = 'Flyx VehicleSharing',
		['color'] = 14423100,
		['description'] = message,
	} }
	PerformHttpRequest(webhook, nil, 'POST', json.encode({embeds = embedData}), {['Content-Type'] = 'application/json'})
end