CreateThread(function()
    local npc
    local ped = Config.Ped
    
    lib.RequestModel(ped.model, 10000)

    npc = CreatePed(4, ped.model, ped.coords.x, ped.coords.y, ped.coords.z, ped.coords.w, false, true)
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
        local coowner = vehicles[i].coowner
        local display = GetDisplayNameFromVehicleModel(vehData.model)

        menu[#menu+1] = {
            title = string.upper(model) .. " - " .. vin,
            description = "Obecny Współwłasciciel "..coowner,
            icon = ('https://docs.fivem.net/vehicles/%s.webp'):format(display:lower()),
            onSelect = function(data)
                OpenVehicleSharingMenu(data)
            end,
            args = { vin = vin, coowner = coowner, model = model}
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
        title = "Obecny Współwłaściciel",
        description = coowner or 'Brak',
        icon = 'users'
    }

    if not coowner then
        options[#options+1] = {
            title = "Dodaj współwłasciciela",
            icon = 'user-plus',
            args = {vin = vin, type = 'add'},
            onSelect = function(data)
                local ChosenPlayer = OpenPlayerChoosingMenu()
                if ChosenPlayer then
                    TriggerServerEvent('flyx_vehiclesharing/updateVehicle', {
                        vin = data.vin,
                        player = ChosenPlayer[1],
                        type = data.type
                    })
                end
            end,
        }
    else
        options[#options+1] = {
            title = "Usuń współwłasciciela",
            icon = 'user-minus',
            -- menu = '', -- moze tutaj wrzucic menu do potwierdzenia??
            disabled = coowner and false or true,
            serverEvent = 'flyx_vehiclesharing/updateVehicle',
            args = {vin = vin, type = 'remove'}
        }
        options[#options+1] = {
            title = "Zmień współwłasciciela",
            icon = 'user-pen',
            args = {vin = vin, type = 'replace'},
            onSelect = function(data)
                local ChosenPlayer = OpenPlayerChoosingMenu()
                if ChosenPlayer then
                    TriggerServerEvent('flyx_vehiclesharing/updateVehicle', {
                        vin = data.vin,
                        player = ChosenPlayer[1],
                        type = data.type
                    })
                end
            end,
        }
    end

    lib.registerContext({
        id = 'vehicle_coowner_'..vin,
        title = 'Współwłaściciel - '..data.model,
        options = options
    })

    lib.showContext('vehicle_coowner_'..vin)

end

function OpenPlayerChoosingMenu()
    local ClosestPlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 20, false)
    local players = {}
    local playerNames = lib.callback.await('flyx_vehiclesharing/getPlayers', false, ClosestPlayers)
    for i=1, #ClosestPlayers do
        local player = ClosestPlayers[i]

        players[#players+1] = {
            value = player.id,
            label = (playerNames[player.id] or 'Nieznajomy')..' - ID: '..player.id
        }
    end

    local input = lib.inputDialog('Wybierz współwłasciciela', {
        {type = 'select', label = 'Osoby w pobliżu', description = 'Wybierz osobę do nadania współwłaściciela', options = players, required = true, }
    })
    return input
end
