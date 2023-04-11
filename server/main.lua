local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Commands.Add('leavedm', 'Leave Death Match', {}, false, function(source, args)
    TriggerClientEvent('i-tdm:client:stop-dm', source)
end)
