local QBCore = exports['qb-core']:GetCoreObject()
local Dmaps = {}
local tableInit = false
local lastBucket = 1

local function initializeTable()
    for _, v in pairs(Config.DM_maps) do
        Dmaps[v.name] = {
            activeMatches = {}
        }
    end
end

RegisterNetEvent('i-tdm:server:set-bucket', function(bucket)
    SetPlayerRoutingBucket(source, bucket)
end)

RegisterNetEvent('i-tdm:server:add-participant', function(map, matchId)
    Dmaps[map].activeMatches[matchId].participants[#Dmaps[map].activeMatches[matchId].participants + 1] = source
end)

RegisterNetEvent('i-tdm:server:remove-participant', function(map, matchId)
    if Dmaps[map].activeMatches[matchId] then
        local participants = Dmaps[map].activeMatches[matchId].participants
        for i = 1, #participants do
            if participants[i] == source then
                print('removed' .. participants[i])
                table.remove(participants, i)
                break
            end
        end
    end
end)

RegisterNetEvent('i-tdm:server:send-kill-msg', function(attackerPlayerId, victimPlayerId, map, matchId)
    local participants = Dmaps[map].activeMatches[matchId].participants
    for i = 1, #participants do
        TriggerClientEvent('i-tdm:client:show-kill-msg', participants[i], attackerPlayerId, victimPlayerId)
    end
end)

QBCore.Functions.CreateCallback('i-tdm:get-new-bucketId', function(source, cb)
    cb(lastBucket + 1)
    lastBucket = lastBucket + 1
end)

QBCore.Functions.CreateCallback('i-tdm:check-match-validity', function(source, cb, map, matchId)
    if Dmaps[map].activeMatches[matchId] then
        cb(true)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('i-tdm:get-time', function(source, cb, map, matchId)
    print(map)
    print(matchId)
    local endTime = Dmaps[map].activeMatches[matchId].endingTime
    local curTime = os.time()
    local timeLeft = (math.floor(math.abs(endTime - curTime))) * 1000
    print(timeLeft)
    cb(timeLeft)
end)

QBCore.Functions.CreateCallback('i-tdm:server:createMatch', function(source, cb, map, bucketId)
    local creator = GetPlayerName(source)
    print(creator)
    local DMTimeInMs = Config.DMTime * 60 * 1000
    local endingTime = os.time() + (DMTimeInMs / 1000)
    local id = #Dmaps[map].activeMatches + 1
    Dmaps[map].activeMatches[id] = {
        id = id,
        participants = {},
        bucketId = bucketId,
        endingTime = endingTime,
        creator = creator
    }
    TriggerClientEvent('i-tdm:client:set-creator-matchid', source, id)
    cb(id)
end)


CreateThread(function()
    while not tableInit do
        initializeTable()
        tableInit = true
    end
end)


CreateThread(function()
    while true do
        for _, v in pairs(Config.DM_maps) do
            for _, value in pairs(Dmaps[v.name].activeMatches) do
                if Dmaps[v.name].activeMatches[value.id] then
                    local curTime = os.time()
                    if (Dmaps[v.name].activeMatches[value.id].endingTime <= curTime) then
                        local participants = Dmaps[v.name].activeMatches[value.id].participants
                        for i = 1, #participants do
                            print('stopping for ' .. participants[i])
                            TriggerClientEvent('i-tdm:client:stop-dm', participants[i])
                            table.remove(participants, i)
                            Dmaps[v.name].activeMatches[value.id] = nil
                        end
                    end
                end
            end
        end
        Wait(0)
    end
end)

QBCore.Commands.Add('leavedm', 'Leave Death Match', {}, false, function(source, args)
    TriggerClientEvent('i-tdm:client:stop-dm', source)
end)
