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

    if ped.blip and ped.blip.enabled then
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
        label = "Zarządzaj współwłaścicielem",
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
        local model = vehData.model or "nieznany"
        local vin = vehicles[i].vin
        local coowner = vehicles[i].co_owner or 'Brak'
        local display = GetDisplayNameFromVehicleModel(vehData.model)

        menu[#menu+1] = {
            title = string.upper(display) .. " - " .. vin,
            description = "Obecny współwłasciciel: "..coowner,
            icon = ('https://docs.fivem.net/vehicles/%s.webp'):format(display:lower()),
            onSelect = function(data)
                OpenVehicleSharingMenu(data)
            end,
            args = { vin = vin, coowner = coowner, display = display}
        }
    end

    lib.registerContext({
        id = 'select_vehicle_context',
        title = 'Wybierz pojazd',
        options = menu
    })
    lib.showContext('select_vehicle_context')
end

function OpenVehicleSharingMenu(data)
    local vin, coowner = data.vin, data.coowner
    local options = {
        {
            title = "Obecny Współwłaściciel",
            description = coowner or 'Brak',
            icon = 'users',
            readOnly = true
        }
    }

    if not coowner or coowner == 'Brak' then
        options[#options+1] = {
            title = "Dodaj współwłasciciela",
            icon = 'user-plus',
            args = {vin = vin, type = 'add', display = data.display},
            onSelect = function(data)
                local ChosenPlayer = OpenPlayerChoosingMenu()
                print(ChosenPlayer)
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
    else
        print(coowner)
        options[#options+1] = {
            title = "Usuń współwłasciciela",
            icon = 'user-minus',
            -- menu = '', -- moze tutaj wrzucic menu do potwierdzenia??
            disabled = (coowner == 'Brak') and true or false,
            serverEvent = 'flyx_vehiclesharing/updateVehicle',
            args = {vin = vin, display = data.display, type = 'remove'}
        }
        options[#options+1] = {
            title = "Zmień współwłasciciela",
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
        title = 'Współwłaściciel - '..data.display,
        options = options
    })

    lib.showContext('vehicle_coowner_'..vin)

end

function OpenPlayerChoosingMenu()
    local ClosestPlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 20, false)
    if not ClosestPlayers or next(ClosestPlayers) == nil then  
        lib.notify({
            title = 'Współwłaściciel',
            description = 'Nie ma żadnych osób w pobliżu!',
            type = 'error'
        })
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
            label = (playerNames[player] or 'Nieznajomy')..' - ID: '..player
        }
    end

    local input = lib.inputDialog('Wybierz współwłasciciela', {
        {type = 'select', label = 'Osoby w pobliżu', description = 'Wybierz osobę do nadania współwłaściciela', options = players, required = true}
    })
    if not input then return end
    return input
end