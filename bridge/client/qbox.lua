if GetResourceState('qbx_core') ~= 'started' then return end

Bridge = {
    sendNotify = function(description, type)
        lib.notify({
            title = locale('coowner'),
            description = description,
            type = type or 'info'
        })
    end
}