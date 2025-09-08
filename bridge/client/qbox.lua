if not Config.Framework == string.upper('QBOX') then return end

Bridge = {
    sendNotify = function(description, type)
        lib.notify({
            title = locale('coowner'),
            description = description,
            type = type or 'info'
        })
    end
}