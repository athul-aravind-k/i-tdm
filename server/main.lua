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
    print('added ' .. source)
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
    if Dmaps[map].activeMatches[tonumber(matchId)] then
        if Config.DM_maps[map].maxMembers > #Dmaps[map].activeMatches[tonumber(matchId)].participants then
            cb(true, true)
        else
            cb(true, false)
        end
    else
        cb(false, false)
    end
end)

QBCore.Functions.CreateCallback('i-tdm:get-time', function(source, cb, map, matchId)
    local endTime = Dmaps[map].activeMatches[matchId].endingTime
    local curTime = os.time()
    local timeLeft = (math.floor(math.abs(endTime - curTime))) * 1000
    cb(timeLeft)
end)

QBCore.Functions.CreateCallback('i-tdm:server:createMatch', function(source, cb, map, bucketId)
    local creator = GetPlayerName(source)
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
    cb(id)
end)

QBCore.Functions.CreateCallback('i-tdm:get-active-matches', function(source, cb)
    local activeMatches = {}
    for _, v in pairs(Config.DM_maps) do
        for key, val in pairs(Dmaps[v.name].activeMatches) do
            if Dmaps[v.name].activeMatches[key] ~= nil then
                local curTime = os.time()
                local timeLeft = (math.floor(math.abs(val.endingTime - curTime))) * 1000
                activeMatches[#activeMatches + 1] = {
                    matchId = val.id,
                    map = v.name,
                    bucketId = val.bucketId,
                    timeLeft = timeLeft,
                    members = #val.participants,
                    creator = val.creator,
                    mapLabel = v.label,
                    maxMembers = v.maxMembers
                }
            end
        end
    end
    cb(activeMatches)
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
                        for i = #participants, 1, -1 do
                            if QBCore.Functions.GetPlayer(tonumber(participants[i])) then
                                print('stopping for ' .. participants[i])
                                TriggerClientEvent('i-tdm:client:stop-dm', participants[i])
                                table.remove(participants, i)
                            end
                        end
                        Dmaps[v.name].activeMatches[value.id] = nil
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
