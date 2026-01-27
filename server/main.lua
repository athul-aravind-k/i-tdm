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

local function initializeDatabase()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `i-tdm_player_stats` (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL UNIQUE,
            name VARCHAR(100) NOT NULL,
            kills INT DEFAULT 0,
            deaths INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_kills (kills),
            INDEX idx_citizenid (citizenid)
        )
    ]], {}, function(success)
        if success then
            print('[i-tdm] Database table i-tdm_player_stats initialized successfully')
        else
            print('[i-tdm] Failed to initialize database table')
        end
    end)
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

local function notifyAllTeamMembers(match, eventName, ...)
    for _, team in ipairs({match.redTeam, match.blueTeam}) do
        for _, playerData in pairs(team) do
            if playerData and playerData.source then
                TriggerClientEvent(eventName, playerData.source, ...)
            end
        end
    end
end

local function SavePlayerStats(citizenid, name, kills, deaths)
    if not citizenid or not name then return end

    exports.oxmysql:execute([[
        INSERT INTO `i-tdm_player_stats` (citizenid, name, kills, deaths)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            kills = kills + VALUES(kills),
            deaths = deaths + VALUES(deaths)
    ]], {
        citizenid,
        name,
        kills or 0,
        deaths or 0
    })
end


local function SaveTDMMatchStats(match)
    if not match or not match.playerStats then return end

    for src, stat in pairs(match.playerStats) do
        local citizenid = stat.citizenid
        local name = stat.name

        if citizenid and name then
            SavePlayerStats(
                citizenid,
                name,
                stat.kills or 0,
                stat.deaths or 0
            )
        end
    end
end




RegisterNetEvent('i-tdm:server:set-bucket', function(bucket)
    SetPlayerRoutingBucket(source, bucket)
end)

RegisterNetEvent('i-tdm:server:add-participant', function(map, matchId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    Dmaps[map].activeMatches[matchId].participants[#Dmaps[map].activeMatches[matchId].participants + 1] = src

    local match = Dmaps[map].activeMatches[matchId]
    if match then
        local existingStats = match.playerStats[src]
        match.playerStats[src] = {
            kills = existingStats and existingStats.kills or 0,
            deaths = existingStats and existingStats.deaths or 0,
            name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            citizenid = Player.PlayerData.citizenid
        }
    end
end)

RegisterNetEvent('i-tdm:server:remove-participant', function(map, matchId)
    local match = Dmaps[map].activeMatches[matchId]
    if not match then return end
    local participants = match.participants
    for i = #participants, 1, -1 do
        if participants[i] == source then
            table.remove(participants, i)
            break
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

    notifyAllTeamMembers(match, "i-tdm:client:updateLobby", map, tonumber(matchId), match)
end)

RegisterNetEvent('i-tdm:server:send-kill-msg', function(killerId, victimId, map, matchId)
    local match = Dmaps[map].activeMatches[matchId]
    if not match then return end
    local participants = match.participants
    local killer = QBCore.Functions.GetPlayer(killerId)
    local victim = QBCore.Functions.GetPlayer(victimId)
    if not killer or not victim then return end

    local killerName = killer.PlayerData.charinfo.firstname .. ' ' .. killer.PlayerData.charinfo.lastname
    local victimName = victim.PlayerData.charinfo.firstname .. ' ' .. victim.PlayerData.charinfo.lastname

    if killerId == victimId then return end
    match.playerStats[killerId] = match.playerStats[killerId] or { kills = 0, deaths = 0, name = killerName, citizenid = killer.PlayerData.citizenid }
    match.playerStats[victimId] = match.playerStats[victimId] or { kills = 0, deaths = 0, name = victimName, citizenid = victim.PlayerData.citizenid }

    local killerStats = match.playerStats[killerId]
    local victimStats = match.playerStats[victimId]
    killerStats.kills = killerStats.kills + 1
    victimStats.deaths = victimStats.deaths + 1

    TriggerClientEvent(
        'i-tdm:client:update-hud-stats',
        victimId,
        victimStats.kills,
        victimStats.deaths,
        false
    )

    TriggerClientEvent(
        'i-tdm:client:update-hud-stats',
        killerId,
        killerStats.kills,
        killerStats.deaths,
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



    if not TDmaps[map] then return end
    local match = TDmaps[map].activeMatches[tonumber(matchId)]
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

    match.playerStats[killerId] = match.playerStats[killerId] or
        { kills = 0, deaths = 0, team = killerTeam, name = killerName, citizenid = killer.PlayerData.citizenid }
    match.playerStats[victimId] = match.playerStats[victimId] or
        { kills = 0, deaths = 0, name = victimName, team = victimTeamCheck, citizenid = victim.PlayerData.citizenid }

    local killerStats = match.playerStats[killerId]
    local victimStats = match.playerStats[victimId]
    killerStats.kills = killerStats.kills + 1
    victimStats.deaths = victimStats.deaths + 1

    if victimTeam == "blue" then
        match.redKills = (match.redKills or 0) + 1
    elseif victimTeam == "red" then
        match.blueKills = (match.blueKills or 0) + 1
    else
        return
    end

    if match.redKills == match.maxKillToWin or match.blueKills == match.maxKillToWin then
        SaveTDMMatchStats(match)
        local winningTeam = match.redKills == match.maxKillToWin and 'red' or 'blue'
        local blueTeamStats, redTeamStats = splitTeams(match)
        notifyAllTeamMembers(match, "i-tdm:client:show-results", {}, 'tdm', winningTeam, blueTeamStats, redTeamStats)
        notifyAllTeamMembers(match, "i-tdm:client:stop-dm")
    end

    TriggerClientEvent(
        'i-tdm:client:update-hud-stats',
        killerId,
        killerStats.kills,
        killerStats.deaths,
        true
    )

    TriggerClientEvent(
        'i-tdm:client:update-hud-stats',
        victimId,
        victimStats.kills,
        victimStats.deaths,
        false
    )

    notifyAllTeamMembers(match, 'i-tdm:client:show-kill-msg-tdm', killerName, victimName, victimTeam, match.redKills, match.blueKills)
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

    match.playerStats[src] = {
        kills = 0,
        deaths = 0,
        team = data.team,
        name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        citizenid = citizenid
    }

    TriggerClientEvent("i-tdm:client:updateLobby", src, data.map, tonumber(data.matchId), match)
    notifyAllTeamMembers(match, "i-tdm:client:updateLobby", data.map, tonumber(data.matchId), match)
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

    notifyAllTeamMembers(match, "i-tdm:client:updateLobby", settings.map, settings.matchId, match)
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
    notifyAllTeamMembers(match, "i-tdm:client:updateLobby", data.map, data.matchId, match)
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
    local match = isTDM and TDmaps[map].activeMatches[tonumber(matchId)] or Dmaps[map].activeMatches[tonumber(matchId)]
    if not match or not match.endingTime then
        cb(0)
        return
    end
    local curTime = os.time()
    cb(math.floor(math.abs(match.endingTime - curTime)) * 1000)
end)

QBCore.Functions.CreateCallback('i-tdm:get-player-stats', function(source, cb, map, matchId, isTDM)
    local src = source
    if isTDM then
        local match = TDmaps[map].activeMatches[tonumber(matchId)]
        if match and match.playerStats[src] then
            cb(match.playerStats[src].kills or 0, match.playerStats[src].deaths or 0)
        else
            cb(0, 0)
        end
    else
        local match = Dmaps[map].activeMatches[tonumber(matchId)]
        if match and match.playerStats[src] then
            cb(match.playerStats[src].kills or 0, match.playerStats[src].deaths or 0)
        else
            cb(0, 0)
        end
    end
end)

QBCore.Functions.CreateCallback('i-tdm:server:createMatch', function(source, cb, map, bucketId, password)
    local player = QBCore.Functions.GetPlayer(source)
    local creator = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local DMTimeInMs = Config.DMTime * 60 * 1000
    local endingTime = os.time() + (DMTimeInMs / 1000)
    local id = #Dmaps[map].activeMatches + 1
    Dmaps[map].activeMatches[id] = {
        id = id,
        map = map,
        participants = {},
        bucketId = bucketId,
        endingTime = endingTime,
        creator = creator,
        password = password or '',
        playerStats = {}
    }
    cb(id)
end)

QBCore.Functions.CreateCallback('i-tdm:get-active-matches', function(source, cb)
    local activeMatches = {}
    for _, v in pairs(Config.DM_maps) do
        for _, val in pairs(Dmaps[v.name].activeMatches) do
            local curTime = os.time()
            local timeLeft = math.floor(math.abs(val.endingTime - curTime)) * 1000
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
                password = val.password,
                playerStats = {}
            }
        end
    end
    cb(activeMatches)
end)

QBCore.Functions.CreateCallback('i-tdm:get-active-matches-tdm', function(source, cb)
    local activeMatches = {}
    for _, v in pairs(Config.TDM_maps) do
        for _, val in pairs(TDmaps[v.name].activeMatches) do
            if val.started ~= true then
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
    cb(activeMatches)
end)

QBCore.Functions.CreateCallback('i-tdm:server:createTDMatch', function(source, cb, map, bucketId, pass)
    local player = QBCore.Functions.GetPlayer(source)
    local creator = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local creatorId = source
    local id = #TDmaps[map].activeMatches + 1
    TDmaps[map].activeMatches[id] = {
        id = id,
        map = map,
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

QBCore.Functions.CreateCallback('i-tdm:get-leaderboard', function(source, cb)
    exports.oxmysql:execute([[
        SELECT name, kills, deaths
        FROM `i-tdm_player_stats`
        ORDER BY kills DESC
        LIMIT 50
    ]], {}, function(result)
        cb(result or {})
    end)
end)

CreateThread(function()
    while not tableInit do
        initializeTable()
        initializeDatabase()
        tableInit = true
    end
end)


CreateThread(function()
    while true do
        local curTime = os.time()
        for _, v in pairs(Config.DM_maps) do
            local mapMatches = Dmaps[v.name].activeMatches
            for matchId, match in pairs(mapMatches) do
                if match and match.endingTime and match.endingTime <= curTime then
                    local participants = match.participants
                    for i = #participants, 1, -1 do
                        if QBCore.Functions.GetPlayer(tonumber(participants[i])) then
                            local stats = formatDm(match)
                            TriggerClientEvent("i-tdm:client:show-results", participants[i], stats, 'dm')
                            TriggerClientEvent('i-tdm:client:stop-dm', participants[i])
                            table.remove(participants, i)
                        end
                    end
                    for src, stat in pairs(match.playerStats or {}) do
                        local citizenid = stat.citizenid
                        local name = stat.name
                        if citizenid and name then
                            SavePlayerStats(citizenid, name, stat.kills or 0, stat.deaths or 0)
                        end
                    end
                    mapMatches[matchId] = nil
                end
            end
        end
        for _, v in pairs(Config.TDM_maps) do
            local mapMatches = TDmaps[v.name].activeMatches
            for matchId, match in pairs(mapMatches) do
                if match and match.endingTime and match.endingTime <= curTime then
                    SaveTDMMatchStats(match)
                    local winningTeam = match.redKills == match.maxKillToWin and 'red' or 'blue'
                    local blueTeamStats, redTeamStats = splitTeams(match)
                    notifyAllTeamMembers(match, "i-tdm:client:show-results", {}, 'tdm', winningTeam, blueTeamStats, redTeamStats)
                    notifyAllTeamMembers(match, "i-tdm:client:stop-dm")
                    mapMatches[matchId] = nil
                end
            end
        end
        Wait(1000)
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
            notifyAllTeamMembers(match, "i-tdm:client:updateLobby", match.map, match.id, match)
        end
    end
end)