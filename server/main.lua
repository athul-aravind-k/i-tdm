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

local function splitTeams(match)
    local blueTeamStats = {}
    local redTeamStats  = {}

    if not match or not match.playerStats then
        return blueTeamStats, redTeamStats
    end

    for playerId, stats in pairs(match.playerStats) do
        local entry = {
            name   = stats.name,
            kills  = stats.kills or 0,
            deaths = stats.deaths or 0
        }

        if stats.team == 'blue' then
            blueTeamStats[playerId] = entry
        elseif stats.team == 'red' then
            redTeamStats[playerId] = entry
        end
    end

    return blueTeamStats, redTeamStats
end

local function formatDm(match)
    local playerStats = {}

    if not match or not match.playerStats then
        return playerStats
    end

    for playerId, stats in pairs(match.playerStats) do
        local entry = {
            name   = stats.name,
            kills  = stats.kills or 0,
            deaths = stats.deaths or 0
        }

        playerStats[playerId] = entry
    end

    return playerStats
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

RegisterNetEvent('i-tdm:server:remove-participant-tdm', function(map, matchId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local match = TDmaps[map].activeMatches[tonumber(matchId)]
    if not match then return end

    match.redTeam[citizenid] = nil
    match.blueTeam[citizenid] = nil

    if match.redTeam then
        for _, playerData in pairs(match.redTeam) do
            if playerData and playerData.source then
                TriggerClientEvent("i-tdm:client:updateLobby", playerData.source, map, tonumber(matchId), match)
            end
        end
    end
    if match.blueTeam then
        for _, playerData in pairs(match.blueTeam) do
            if playerData and playerData.source then
                TriggerClientEvent("i-tdm:client:updateLobby", -playerData.source, map, tonumber(matchId), match)
            end
        end
    end
end)

RegisterNetEvent('i-tdm:server:send-kill-msg', function(killerId, victimId, map, matchId)
    local participants = Dmaps[map].activeMatches[matchId].participants
    local match = Dmaps[map].activeMatches[matchId]
    local killer = QBCore.Functions.GetPlayer(killerId)
    local victim = QBCore.Functions.GetPlayer(victimId)
    if not killer or not victim then return end

    local killerName = killer.PlayerData.charinfo.firstname .. ' ' .. killer.PlayerData.charinfo.lastname
    local victimName = victim.PlayerData.charinfo.firstname .. ' ' .. victim.PlayerData.charinfo.lastname

    if killerId == victimId then return end
    match.playerStats[killerId] = match.playerStats[killerId] or { kills = 0, deaths = 0, name = killerName }
    match.playerStats[victimId] = match.playerStats[victimId] or { kills = 0, deaths = 0, name = victimName }

    match.playerStats[killerId].kills += 1
    match.playerStats[victimId].deaths += 1

    TriggerClientEvent(
        'i-tdm:client:update-hud-stats',
        victimId,
        match.playerStats[victimId].kills,
        match.playerStats[victimId].deaths,
        false
    )

    TriggerClientEvent(
        'i-tdm:client:update-hud-stats',
        killerId,
        match.playerStats[killerId].kills,
        match.playerStats[killerId].deaths,
        true
    )
    for i = 1, #participants do
        TriggerClientEvent('i-tdm:client:show-kill-msg', participants[i], killerName, victimName)
    end
end)

RegisterNetEvent('i-tdm:server:send-kill-msg-tdm', function(
    killerId,
    victimId,
    map,
    matchId,
    victimTeam
)
    local killer = QBCore.Functions.GetPlayer(killerId)
    local victim = QBCore.Functions.GetPlayer(victimId)

    if not killer or not victim then return end
    local killerName = killer.PlayerData.charinfo.firstname .. ' ' .. killer.PlayerData.charinfo.lastname
    local victimName = victim.PlayerData.charinfo.firstname .. ' ' .. victim.PlayerData.charinfo.lastname

    if killerId == victimId then return end -- suicide protection



    local match = TDmaps[map]?.activeMatches?[tonumber(matchId)]
    if not match then return end

    local killerTeam = nil
    local victimTeamCheck = nil

    if match.redTeam[killer.PlayerData.citizenid] then
        killerTeam = "red"
    elseif match.blueTeam[killer.PlayerData.citizenid] then
        killerTeam = "blue"
    end
    if match.redTeam[victim.PlayerData.citizenid] then
        victimTeamCheck = "red"
    elseif match.blueTeam[victim.PlayerData.citizenid] then
        victimTeamCheck = "blue"
    end

    if killerTeam == victimTeamCheck then return end

    match.playerStats[killerId] = match.playerStats[killerId] or { kills = 0, deaths = 0, team = killerTeam, name = killerName }
    match.playerStats[victimId] = match.playerStats[victimId] or { kills = 0, deaths = 0, name = victimName,team = victimTeamCheck }

    match.playerStats[killerId].kills += 1
    match.playerStats[victimId].deaths += 1

    if victimTeam == "blue" then
        match.redKills = (match.redKills or 0) + 1
    elseif victimTeam == "red" then
        match.blueKills = (match.blueKills or 0) + 1
    else
        return
    end

    if match.redKills == match.maxKillToWin or match.blueKills == match.maxKillToWin then
        local winningTeam = match.redKills == match.maxKillToWin and 'red' or 'blue'
        local blueTeamStats, redTeamStats = splitTeams(match)
        if match.redTeam then
            for _, playerData in pairs(match.redTeam) do
                if playerData and playerData.source then
                    TriggerClientEvent("i-tdm:client:show-results", playerData.source, {}, 'tdm', winningTeam,
                        blueTeamStats, redTeamStats)
                    TriggerClientEvent("i-tdm:client:stop-dm", playerData.source)
                end
            end
        end
        if match.blueTeam then
            for _, playerData in pairs(match.blueTeam) do
                if playerData and playerData.source then
                    TriggerClientEvent("i-tdm:client:show-results", playerData.source, {}, 'tdm', winningTeam,
                        blueTeamStats, redTeamStats)
                    TriggerClientEvent("i-tdm:client:stop-dm", playerData.source)
                end
            end
        end
    end

    TriggerClientEvent(
        'i-tdm:client:update-hud-stats',
        killerId,
        match.playerStats[killerId].kills,
        match.playerStats[killerId].deaths
    )

    TriggerClientEvent(
        'i-tdm:client:update-hud-stats',
        victimId,
        match.playerStats[victimId].kills,
        match.playerStats[victimId].deaths
    )

    -- Broadcast kill feed
    for _, teamData in pairs({ match.redTeam, match.blueTeam }) do
        for _, playerData in pairs(teamData) do
            if playerData.source then
                TriggerClientEvent(
                    'i-tdm:client:show-kill-msg-tdm',
                    playerData.source,
                    killerName,
                    victimName,
                    victimTeam,
                    match.redKills,
                    match.blueKills
                )
            end
        end
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
        name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        kills = 0,
        deaths = 0
    }
    TriggerClientEvent("i-tdm:client:updateLobby", src, data.map, tonumber(data.matchId), match)
    if match.redTeam then
        for _, playerData in pairs(match.redTeam) do
            if playerData and playerData.source then
                TriggerClientEvent("i-tdm:client:updateLobby", playerData.source, data.map, tonumber(data.matchId), match)
            end
        end
    end
    if match.blueTeam then
        for _, playerData in pairs(match.blueTeam) do
            if playerData and playerData.source then
                TriggerClientEvent("i-tdm:client:updateLobby", playerData.source, data.map, tonumber(data.matchId), match)
            end
        end
    end
end)

RegisterNetEvent("i-tdm:server:delete-tdm", function(data)
    local src = source
    local match = TDmaps[data.map].activeMatches[tonumber(data.matchId)]
    if not match then return end
    if match.creatorId ~= src then
        print('only owner can delete')
        return
    end
    for _, playerData in pairs(match.redTeam) do
        if playerData.source then
            TriggerClientEvent("i-tdm:server:kick-tdm-player", playerData.source)
        end
    end

    for _, playerData in pairs(match.blueTeam) do
        if playerData.source then
            TriggerClientEvent("i-tdm:server:kick-tdm-player", playerData.source)
        end
    end

    TDmaps[data.map].activeMatches[tonumber(data.matchId)] = nil
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
    match.started = true

    for _, playerData in pairs(match.redTeam) do
        if playerData.source then
            TriggerClientEvent(
                "i-tdm:client:startTDM",
                playerData.source,
                {
                    map = data.map,
                    matchId = data.matchId,
                    team = "red",
                    match = match,
                    bucketId = match.bucketId,
                    weapon = match.weapon
                }
            )
        end
    end

    for _, playerData in pairs(match.blueTeam) do
        if playerData.source then
            TriggerClientEvent(
                "i-tdm:client:startTDM",
                playerData.source,
                {
                    map = data.map,
                    matchId = data.matchId,
                    team = "blue",
                    match = match,
                    bucketId = match.bucketId,
                    weapon = match.weapon
                }
            )
        end
    end
end)


RegisterNetEvent("i-tdm:server:update-settings", function(settings)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

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
    if settings.maxKillToWin then
        match.maxKillToWin = settings.maxKillToWin
    end

    if match.redTeam then
        for _, playerData in pairs(match.redTeam) do
            if playerData and playerData.source then
                TriggerClientEvent("i-tdm:client:updateLobby", playerData.source, settings.map, settings.matchId, match)
            end
        end
    end
    if match.blueTeam then
        for _, playerData in pairs(match.blueTeam) do
            if playerData and playerData.source then
                TriggerClientEvent("i-tdm:client:updateLobby", playerData.source, settings.map, settings.matchId, match)
            end
        end
    end
end)

RegisterNetEvent("i-tdm:server:kick-tdm-player", function(data)
    local src = source
    local kickedPlayer = QBCore.Functions.GetPlayer(data.playerId)
    if not kickedPlayer then return end

    local citizenid = kickedPlayer.PlayerData.citizenid

    local match = TDmaps[data.map].activeMatches[data.matchId]
    if not match then return end

    if src ~= match.creatorId then return end

    match.redTeam[citizenid] = nil
    match.blueTeam[citizenid] = nil

    TriggerClientEvent("i-tdm:client:kick-player-tdm", data.playerId)
    if match.redTeam then
        for _, playerData in pairs(match.redTeam) do
            if playerData and playerData.source then
                TriggerClientEvent("i-tdm:client:updateLobby", playerData.source, data.map, data.matchId, match)
            end
        end
    end
    if match.blueTeam then
        for _, playerData in pairs(match.blueTeam) do
            if playerData and playerData.source then
                TriggerClientEvent("i-tdm:client:updateLobby", playerData.source, data.map, data.matchId, match)
            end
        end
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

QBCore.Functions.CreateCallback('i-tdm:get-time', function(source, cb, map, matchId, isTDM)
    if isTDM then
        local endTime = TDmaps[map].activeMatches[matchId].endingTime
        local curTime = os.time()
        local timeLeft = (math.floor(math.abs(endTime - curTime))) * 1000
        cb(timeLeft)
    else
        local endTime = Dmaps[map].activeMatches[matchId].endingTime
        local curTime = os.time()
        local timeLeft = (math.floor(math.abs(endTime - curTime))) * 1000
        cb(timeLeft)
    end
end)

QBCore.Functions.CreateCallback('i-tdm:server:createMatch', function(source, cb, map, bucketId)
    local player = QBCore.Functions.GetPlayer(source)
    local creator = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local DMTimeInMs = Config.DMTime * 60 * 1000
    local endingTime = os.time() + (DMTimeInMs / 1000)
    local id = #Dmaps[map].activeMatches + 1
    Dmaps[map].activeMatches[id] = {
        id = id,
        participants = {},
        bucketId = bucketId,
        endingTime = endingTime,
        creator = creator,
        playerStats = {}
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
                    maxMembers = v.maxMembers,
                    image = v.image,
                    playerStats = {}

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
                if TDmaps[v.name].activeMatches[key].started ~= true then
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
                        weapon = val.weapon,
                        maxKillToWin = val.maxKillToWin or 10
                    }
                end
            end
        end
    end
    cb(activeMatches)
end)

QBCore.Functions.CreateCallback('i-tdm:server:createTDMatch', function(source, cb, map, bucketId, pass)
    local player = QBCore.Functions.GetPlayer(source)
    local creator = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
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
        started = false,
        blueKills = 0,
        redKills = 0,
        maxKillToWin = 10,
        playerStats = {}
    }
    cb(id, TDmaps[map].activeMatches[id])
end)

QBCore.Functions.CreateCallback('i-tdm:server:get-tdm-details', function(source, cb, matchId, map)
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
                                local stats = formatDm(Dmaps[v.name].activeMatches[value.id])
                                TriggerClientEvent("i-tdm:client:show-results", participants[i],stats, 'dm')
                                TriggerClientEvent('i-tdm:client:stop-dm', participants[i])
                                table.remove(participants, i)
                            end
                        end
                        Dmaps[v.name].activeMatches[value.id] = nil
                    end
                end
            end
        end
        for _, v in pairs(Config.TDM_maps) do
            for _, value in pairs(TDmaps[v.name].activeMatches) do
                local match = TDmaps[v.name].activeMatches[value.id]
                if match and match.endingTime then
                    local curTime = os.time()
                    if match.endingTime <= curTime then
                        local winningTeam = match.redKills == match.maxKillToWin and 'red' or 'blue'
                        local blueTeamStats, redTeamStats = splitTeams(match)
                        if match.redTeam then
                            for _, playerData in pairs(match.redTeam) do
                                if playerData and playerData.source then
                                    TriggerClientEvent("i-tdm:client:show-results", playerData.source, {}, 'tdm',
                                        winningTeam, blueTeamStats, redTeamStats)
                                    TriggerClientEvent("i-tdm:client:stop-dm", playerData.source)
                                end
                            end
                        end
                        if match.blueTeam then
                            for _, playerData in pairs(match.blueTeam) do
                                if playerData and playerData.source then
                                    TriggerClientEvent("i-tdm:client:show-results", playerData.source, {}, 'tdm',
                                        winningTeam, blueTeamStats, redTeamStats)
                                    TriggerClientEvent("i-tdm:client:stop-dm", playerData.source)
                                end
                            end
                        end
                        TDmaps[v.name].activeMatches[value.id] = nil
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

-- --remove
-- QBCore.Commands.Add('mockKill', 'mockKillDM', {{ name = 'arg 1', help = 'kill' }}, false, function(source, args)
--     QBCore.Debug(args)
--     TriggerClientEvent(
--         'i-tdm:client:update-hud-stats',
--         2,
--         args[1],
--         2,
--         false
--     )
-- end)

AddEventHandler("playerDropped", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    for _, maps in pairs(TDmaps) do
        for _, match in pairs(maps.activeMatches) do
            match.redTeam[citizenid] = nil
            match.blueTeam[citizenid] = nil
            if match.redTeam then
                for _, playerData in pairs(match.redTeam) do
                    if playerData and playerData.source then
                        TriggerClientEvent("i-tdm:client:updateLobby", playerData.source, match.map, match.id, match)
                    end
                end
            end
            if match.blueTeam then
                for _, playerData in pairs(match.blueTeam) do
                    if playerData and playerData.source then
                        TriggerClientEvent("i-tdm:client:updateLobby", playerData.source, match.map, match.id, match)
                    end
                end
            end
        end
    end
end)
