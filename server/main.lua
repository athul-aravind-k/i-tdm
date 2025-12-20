local QBCore = exports['qb-core']:GetCoreObject()
local Dmaps = {}
local TDmaps = {}
local tableInit = false
local lastBucket = 1

local function initializeTable()
    for _, v in pairs(Config.DM_maps) do
        Dmaps[v.name] = {
            activeMatches = {}
        }
    end
    for _, v in pairs(Config.TDM_maps) do
        TDmaps[v.name] = {
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

RegisterNetEvent("i-tdm:server:joinTeam", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local match = TDmaps[data.map].activeMatches[tonumber(data.matchId)]
    if not match then return end

    match.redTeam[citizenid] = nil
    match.blueTeam[citizenid] = nil
    
    match[data.team .. "Team"][citizenid] = {
        source = src,
        name = Player.PlayerData.charinfo.firstname .. " " ..Player.PlayerData.charinfo.lastname
    }
    TriggerClientEvent("i-tdm:client:updateLobby", -1, data.map, tonumber(data.matchId), match)
end)

RegisterNetEvent("i-tdm:server:start-tdm", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local match = TDmaps[data.map].activeMatches[tonumber(data.matchId)]
    if not match then return end

    if src ~= match.creatorId then
        print('not owner')
        return
    end

    local timeInMs = match.time * 60 * 1000
    local endingTime = os.time() + (timeInMs / 1000)
    match.endingTime = endingTime

    for citizenid, playerData in pairs(match.redTeam) do
        if playerData.source then
            TriggerClientEvent(
                "i-tdm:client:startTDM",
                playerData.source,
                {
                    map = data.map,
                    matchId = data.matchId,
                    team = "red",
                    match = match,
                    bucketId = match.bucketId
                }
            )
        end
    end

    for citizenid, playerData in pairs(match.blueTeam) do
        if playerData.source then
            TriggerClientEvent(
                "i-tdm:client:startTDM",
                playerData.source,
                {
                    map = data.map,
                    matchId = data.matchId,
                    team = "blue",
                    match = match,
                    bucketId = match.bucketId
                }
            )
        end
    end
end)


RegisterNetEvent("i-tdm:server:update-settings", function(settings)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local match = TDmaps[settings.map].activeMatches[tonumber(settings.matchId)]
    if not match then return end

    if src ~= match.creatorId then return end

    if settings.weapon then
        match.weapon = settings.weapon
    end

    if settings.time then
        match.time = settings.time
    end
    
    if settings.maxMembers then
        match.maxMembers = settings.maxMembers
    end

    --TriggerClientEvent("i-tdm:client:updateLobby", -1, settings.map, settings.matchId, match)
end)

RegisterNetEvent("i-tdm:server:kickPlayer", function(map, matchId, citizenid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local match = TDmaps[map].activeMatches[matchId]
    if not match then return end

    if Player.PlayerData.citizenid ~= match.creatorId then return end

    match.redTeam[citizenid] = nil
    match.blueTeam[citizenid] = nil

    TriggerClientEvent("tdm:client:updateLobby", -1, map, matchId, match)
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

QBCore.Functions.CreateCallback('i-tdm:get-active-matches-tdm', function(source, cb)
    local activeMatches = {}
    for _, v in pairs(Config.TDM_maps) do
        for key, val in pairs(TDmaps[v.name].activeMatches) do
            if TDmaps[v.name].activeMatches[key] ~= nil then
                QBCore.Debug(TDmaps)
                if TDmaps[v.name].activeMatches[key].started~=true then
                    activeMatches[#activeMatches + 1] = {
                        matchId = val.id,
                        map = v.name,
                        bucketId = val.bucketId,
                        members = (val.redTeam and #val.redTeam or 0) + (val.blueTeam and #val.blueTeam or 0),
                        creator = val.creator,
                        mapLabel = v.label,
                        maxMembers = val.maxMembers,
                        image = v.image,
                        password = val.password,
                        weapon = val.weapon
                    }
                end
            end
        end
    end
    cb(activeMatches)
end)

QBCore.Functions.CreateCallback('i-tdm:server:createTDMatch', function(source, cb, map, bucketId,pass)
    local creator = GetPlayerName(source)
    local creatorId = source
    local id = #TDmaps[map].activeMatches + 1
    TDmaps[map].activeMatches[id] = {
        id = id,
        redTeam = {},
        blueTeam = {},
        bucketId = bucketId,
        time = 5,
        endingTime = nil,
        creator = creator,
        creatorId = creatorId,
        weapon = 'assault',
        password = pass,
        maxMembers = 10,
        started = false
    }
    cb(id,TDmaps[map].activeMatches[id])
end)

QBCore.Functions.CreateCallback('i-tdm:server:get-tdm-details', function(source, cb, matchId,map)
    local activematch = TDmaps[map].activeMatches[matchId]
    cb(activematch)
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

QBCore.Commands.Add('leavedm', 'Leave Death Match/ Team Death Match', {}, false, function(source, args)
    TriggerClientEvent('i-tdm:client:stop-dm', source)
end)

AddEventHandler("playerDropped", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    for _, maps in pairs(TDmaps) do
        for _, match in pairs(maps.activeMatches) do
            match.redTeam[citizenid] = nil
            match.blueTeam[citizenid] = nil

            TriggerClientEvent("tdm:client:updateLobby", -1, map, match.id, match)
        end
    end
end)
