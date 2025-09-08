CreateThread(function()
    local npc
    local ped = Config.Ped
    
    lib.requestModel(ped.model, 10000)

    npc = CreatePed(4, ped.model, ped.coords.x, ped.coords.y, ped.coords.z-1, ped.coords.w, false, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)

    if ped.scenario then
        TaskStartScenarioInPlace(npc, ped.scenario, 0, true)
    end

    if ped.blip then
        local blip = AddBlipForCoord(ped.coords.x, ped.coords.y, ped.coords.z)
        SetBlipSprite(blip, ped.blip.sprite)
        SetBlipColour(blip, ped.blip.color)
        SetBlipScale(blip, ped.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(ped.blip.label)
        EndTextCommandSetBlipName(blip)
    end

    exports.ox_target:addLocalEntity(npc, {
        name = "flyx_vehiclesharing/npc",
        icon = "fa-solid fa-car",
        label = locale('target_label'),
        onSelect = function()
            OpenSelectVehicleMenu()
        end
    })
end)

function OpenSelectVehicleMenu()
    local vehicles = lib.callback.await('flyx_vehiclesharing/getVehicles', false)
    local menu = {}

    for i=1, #vehicles do
        local vehData = json.decode(vehicles[i].vehicle)
        local model = vehData.model or "unknown"
        local vin = vehicles[i].vin
        local coowner = vehicles[i].co_owner or locale('coowner_unknown')
        local display = GetDisplayNameFromVehicleModel(vehData.model)

        menu[#menu+1] = {
            title = string.upper(display) .. " - " .. vin,
            description = locale('coowner_current')..': '..coowner,
            icon = ('https://docs.fivem.net/vehicles/%s.webp'):format(display:lower()),
            onSelect = function(data)
                OpenVehicleSharingMenu(data)
            end,
            args = { vin = vin, coowner = coowner, display = display}
        }
    end

    lib.registerContext({
        id = 'select_vehicle_context',
        title = locale('choose_vehicle'),
        options = menu
    })
    lib.showContext('select_vehicle_context')
end

function OpenVehicleSharingMenu(data)
    local vin, coowner = data.vin, data.coowner
    local options = {
        {
            title = locale('coowner_current'),
            description = coowner or locale('coowner_none'),
            icon = 'users',
            readOnly = true
        }
    }

    if not coowner or coowner == locale('coowner_unknown') then
        options[#options+1] = {
            title = locale('coowner_add'),
            icon = 'user-plus',
            args = {vin = vin, type = 'add', display = data.display},
            onSelect = function(data)
                local ChosenPlayer = OpenPlayerChoosingMenu()
                if ChosenPlayer then
                    TriggerServerEvent('flyx_vehiclesharing/updateVehicle', {
                        vin = data.vin,
                        player = ChosenPlayer,
                        display = data.display,
                        type = data.type
                    })
                end
            end,
        }
    else
        options[#options+1] = {
            title = locale('coowner_remove'),
            icon = 'user-minus',
            disabled = (coowner == 'Brak') and true or false,
            -- serverEvent = 'flyx_vehiclesharing/updateVehicle',
            onSelect = function(args) -- god damn, how many datas can there be? This one will be special :p
                local alert = lib.alertDialog({
                    header = locale('confirmation_title'),
                    content = locale('are_you_sure'):format(coowner),
                    centered = true,
                    cancel = true,
                    labels = {
                        cancel = locale('confirmation_decline'),
                        confirm = locale('confirmation_accept')
                    }
                })
                if alert == 'confirm' then
                    TriggerServerEvent('flyx_vehiclesharing/updateVehicle', {args.vin, args.display, args.type})
                end
            end,
            args = {vin = vin, display = data.display, type = 'remove'}
        }
        options[#options+1] = {
            title = locale('coowner_replace'),
            icon = 'user-pen',
            args = {vin = vin, type = 'replace', display = data.display},
            onSelect = function(data)
                local ChosenPlayer = OpenPlayerChoosingMenu()
                if ChosenPlayer then
                    TriggerServerEvent('flyx_vehiclesharing/updateVehicle', {
                        vin = data.vin,
                        player = ChosenPlayer[1],
                        display = data.display,
                        type = data.type
                    })
                end
            end,
        }
    end

    lib.registerContext({
        id = 'vehicle_coowner_'..vin,
        title = locale('coowner')..' - '..data.display,
        options = options
    })

    lib.showContext('vehicle_coowner_'..vin)

end

function OpenPlayerChoosingMenu()
    local ClosestPlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 20, false)
    if not ClosestPlayers or next(ClosestPlayers) == nil then  
        Bridge.sendNotify(locale('noone_nearby'), 'error')
        return false
    end

    local playerServerIds = {}
    for i=1, #ClosestPlayers do
        local player = ClosestPlayers[i]
        local serverId = GetPlayerServerId(player.id)
        table.insert(playerServerIds, serverId)
    end

    local playerNames = lib.callback.await('flyx_vehiclesharing/getPlayers', false, playerServerIds)
    local players = {}
    for i=1, #playerServerIds do
        local player = playerServerIds[i]

        players[#players+1] = {
            value = player,
            label = (playerNames[player] or locale('coowner_unknown'))..' - ID: '..player
        }
    end

    local input = lib.inputDialog(locale('coowner_choose'), {
        {type = 'select', label = locale('coowner_choosing_label'), description = locale('coowner_choosing_description'), options = players, required = true}
    })
    if not input then return end
    return input[1]
end

lib.callback.register('flyx_vehiclesharing/PaymentDialog', function()
    local input = lib.inputDialog(locale('payment_title'), {
        {type = 'select', label = locale('payment_type'), required = true, options = {
            [1] = {value = 'card', label = locale('card')}, 
            [2] = {value = 'cash', label = locale('cash')}}
        }
    }, {allowCancel = false})
    return input and input[1] or 'cash'
end)

lib.callback.register('flyx_vehiclesharing/ConfirmationDialog', function(data)
    local alert = lib.alertDialog({
        header = locale('confirmation_title'),
        content = locale('wants_to_add_you'):format(data.playerName, data.model, data.plate),
        centered = true,
        cancel = true,
        labels = {
            cancel = locale('confirmation_decline'),
            confirm = locale('confirmation_accept')
        }
    })

    return alert == 'confirm' and true or false
end)
