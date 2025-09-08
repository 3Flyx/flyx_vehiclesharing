if GetResourceState('es_extended') ~= 'started' then return end

ESX = exports['es_extended']:getSharedObject()

Bridge = {
    sendNotify = function(description, type)
        lib.notify({
            title = locale('coowner'),
            description = description,
            type = type or 'info'
        })
    end
}