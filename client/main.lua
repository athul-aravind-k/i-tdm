local QBCore = exports['qb-core']:GetCoreObject()
local deathMatchZone = {}
local startBlip
local currDmap
local currTDmap
local insideDmz = false
local InMatch = false
local inTDM = false
local inDMatch = false
local currBucket
local activeMatchId
local activeTDMId
local DMKills = 0
local DMDeaths = 0
local Zones = {}
local TdmTeam = nil
local TdmMap = nil
local HealThread = nil
local InOwnSpawn = false
local InEnemySpawn = false
local TDMweapon = 'assault'

local function setClothes(team)
    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()

    if not PlayerData or not PlayerData.charinfo then return end

    local gender = PlayerData.charinfo.gender == 0 and "male" or "female"

    local clothes
    if team and Config.TDMClothes[team] then
        clothes = Config.TDMClothes[team][gender]
    else
        clothes = Config.Clothes[gender]
    end

    if not clothes then return end

    ClearAllPedProps(ped)

    -- components
    SetPedComponentVariation(ped, 1,  clothes.mask_1   or 0, clothes.mask_2   or 0, 0) -- mask
    SetPedComponentVariation(ped, 3,  clothes.arms     or 0, 0, 0)                     -- arms
    SetPedComponentVariation(ped, 8,  clothes.tshirt_1 or 0, clothes.tshirt_2 or 0, 0) -- t-shirt
    SetPedComponentVariation(ped, 11, clothes.torso_1  or 0, clothes.torso_2  or 0, 0) -- torso
    SetPedComponentVariation(ped, 9,  clothes.bproof_1 or 0, clothes.bproof_2 or 0, 0) -- vest
    SetPedComponentVariation(ped, 10, clothes.decals_1 or 0, clothes.decals_2 or 0, 0) -- decals
    SetPedComponentVariation(ped, 7,  clothes.chain_1  or 0, clothes.chain_2  or 0, 0) -- chain
    SetPedComponentVariation(ped, 4,  clothes.pants_1  or 0, clothes.pants_2  or 0, 0) -- pants
    SetPedComponentVariation(ped, 6,  clothes.shoes_1  or 0, clothes.shoes_2  or 0, 0) -- shoes

    -- props
    if clothes.helmet_1 and clothes.helmet_1 >= 0 then
        SetPedPropIndex(ped, 0, clothes.helmet_1, clothes.helmet_2 or 0, true)
    end

    if clothes.ears_1 and clothes.ears_1 >= 0 then
        SetPedPropIndex(ped, 2, clothes.ears_1, clothes.ears_2 or 0, true)
    end
end

local function createSpawnBlip()
    startBlip = AddBlipForCoord(Config.startPed.pos)
    SetBlipSprite(startBlip, 364)
    SetBlipDisplay(startBlip, 4)
    SetBlipColour(startBlip, 1)
    SetBlipScale(startBlip, 1.0)
    SetBlipAsShortRange(startBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(tostring("TDM"))
    EndTextCommandSetBlipName(startBlip)
end

local function createDeathMatchZone(map)
    local selectedMap = Config.DM_maps[map]
    deathMatchZone = PolyZone:Create(selectedMap.zone.zones, {
        name = selectedMap.zone.name,
        minZ = selectedMap.zone.minZ,
        maxZ = selectedMap.zone.maxZ,
        debugPoly = true
    })

    deathMatchZone:onPlayerInOut(function(isPointInsideDmz)
        if insideDmz == nil then
            insideDmz = isPointInsideDmz
            if isPointInsideDmz and inDMatch then
                SendNUIMessage({ action = 'zone:clear' })
            elseif ~isPointInsideDmz and inDMatch then
                SendNUIMessage({ action = 'zone:out', time = Config.DMZoneoutKillTime })
            end
            return
        end

        if insideDmz ~= isPointInsideDmz then
            insideDmz = isPointInsideDmz

            if isPointInsideDmz and inDMatch then
                SendNUIMessage({ action = 'zone:clear' })
            elseif isPointInsideDmz ~= true and inDMatch then
                SendNUIMessage({ action = 'zone:out', time = Config.DMZoneoutKillTime })
            end
        end
    end)
end

local function setPedProperties(clipReload, lastWeapon)
    local ped = PlayerPedId()
    local weapons = Config.DM_Weapons
    for i = 1, #weapons do
        GiveWeaponToPed(ped, weapons[i], 200, false, false)
        if (clipReload) then
            SetAmmoInClip(ped, weapons[i], 30)
        end
        if lastWeapon and weapons[i] == lastWeapon then
            GiveWeaponToPed(ped, lastWeapon, 200, false, true)
        end
    end
    TriggerServerEvent('hud:server:RelieveStress', 100)
    SetPedArmour(ped, 100)
    SetEntityHealth(ped, 200)
end

local function setPedPropertiesTdm(clipReload, lastWeapon)
    local ped = PlayerPedId()
    local weapons = Config.TDM_Weapons[TDMweapon]
    for i = 1, #weapons do
        GiveWeaponToPed(ped, weapons[i], 200, false, false)
        if (clipReload) then
            SetAmmoInClip(ped, weapons[i], 30)
        end
        if lastWeapon and weapons[i] == lastWeapon then
            GiveWeaponToPed(ped, lastWeapon, 200, false, true)
        end
    end
    TriggerServerEvent('hud:server:RelieveStress', 100)
    SetPedArmour(ped, 100)
    SetEntityHealth(ped, 200)
end

local function spawnToRandomPosDm(map, lastWeapon)
    ped = PlayerPedId()
    local selectedMap = Config.DM_maps[map]
    local spawnPoints = selectedMap.spawnpoints
    local spawnPoint = spawnPoints[math.random(1, #spawnPoints)]
    local heading = GetEntityHeading(ped)
    NetworkResurrectLocalPlayer(spawnPoint.x, spawnPoint.y, spawnPoint.z + 0.5, heading, true, false)
    TriggerEvent("hospital:client:Revive")
    setPedProperties(true, lastWeapon)
    SetEntityCoords(ped, spawnPoint, false, false, false, false)
    SetEntityInvincible(ped, true)
    Wait(Config.pedInvincibleTime * 1000)
    SetEntityInvincible(ped, false)
end

local function toggleHud(bool, time, isTdm)
    SendNUIMessage({
        type = 'toggle-hud',
        message = {
            bool = bool,
            time = time,
            totalTime = time,
            isTdm = isTdm
        }
    })
end

local function notify(message, type)
    SendNUIMessage({
        type = 'notify',
        action = type,
        message = message,
    })
end

-- local function GetPlayerTeamByServerId(id)
--     QBCore.Functions.TriggerCallback('i-tdm:get-player-team', function(timeLeft)

--     end, id)
-- end


local function sendToDmatchMap(map, matchId, bucketId)
    local mId = tonumber(matchId)
    local bId = tonumber(bucketId)
    QBCore.Functions.TriggerCallback('i-tdm:check-match-validity', function(active, joinable)
        if active then
            if joinable then
                local ped = PlayerPedId()
                createDeathMatchZone(map)
                TriggerEvent("hospital:client:Revive")
                -- TriggerEvent('i-tdm:toggle-ambulance-job', false)
                TriggerServerEvent('i-tdm:server:set-bucket', bId)
                TriggerServerEvent('i-tdm:server:add-participant', map, mId)
                activeMatchId = mId
                local selectedMap = Config.DM_maps[map]
                local spawnPoints = selectedMap.spawnpoints
                local spawnPoint = spawnPoints[math.random(1, #spawnPoints)]
                QBCore.Functions.TriggerCallback('i-tdm:get-time', function(timeLeft)
                    QBCore.Functions.TriggerCallback('i-tdm:get-player-stats', function(kills, deaths)
                        DMKills = kills
                        DMDeaths = deaths
                        FreezeEntityPosition(ped, true)
                        SwitchOutPlayer(ped, 0, 1)
                        RequestCollisionAtCoord(spawnPoint.x, spawnPoint.y, spawnPoint.z)
                        Wait(2000)
                        SetEntityInvincible(ped, true)
                        SetEntityCoordsNoOffset(ped, spawnPoint.x, spawnPoint.y, spawnPoint.z, false, false, false, true)

                        while not HasCollisionLoadedAroundEntity(ped) do
                            RequestCollisionAtCoord(spawnPoint.x, spawnPoint.y, spawnPoint.z)
                            Wait(0)
                        end

                        NetworkResurrectLocalPlayer(spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.heading, true, true,
                            false)
                        ClearPedTasksImmediately(ped)
                        Wait(2000)
                        SwitchInPlayer(ped)
                        toggleHud(true, timeLeft, false)
                        setClothes()
                        setPedProperties(false, nil)
                        Wait(2000)
                        FreezeEntityPosition(ped, false)
                        SetEntityInvincible(ped, false)
                        inDMatch = true
                        InMatch = true
                        TriggerEvent('wais:hudv6:client:hideHud', true)
                        exports.ox_inventory:weaponWheel(true)
                    end, map, mId, false)
                end, map, mId, false)
            else
                notify('match Full', 'error')
            end
        else
            notify('match doesnt exist', 'error')
        end
    end, map, matchId)
end

local function startDeathMatch(map)
    currDmap = map
    currBucket = GetEntityPopulationType(GetEntityCoords(ped))
    QBCore.Functions.TriggerCallback('i-tdm:get-new-bucketId', function(bucketId)
        QBCore.Functions.TriggerCallback('i-tdm:server:createMatch', function(matchId)
            activeMatchId = matchId
            sendToDmatchMap(map, matchId, bucketId)
        end, map, bucketId)
    end)
end

local function showKillMessage(killer, killed, type)
    SendNUIMessage({
        type = "kill-msg",
        message = {
            killer = killer,
            killed = killed,
            type = type
        }
    })
end

local function updateHealthStats(hp, armor, ammo, clip)
    SendNUIMessage({
        type = "update-stats",
        message = {
            hp = hp,
            armor = armor,
            ammo = ammo,
            clip = clip,
            kills = DMKills,
            deaths = DMDeaths
        }
    })
end

local function showJoinUi(map, mapTable)
    SendNUIMessage({
        type = "show-tdm-join",
        matchId = activeTDMId,
        playerId = GetPlayerServerId(PlayerId()),
        map = map,
        mapTable = mapTable
    })
end

local function startTeamDeathMatch(map, password)
    currTDmap = map
    currBucket = GetEntityPopulationType(GetEntityCoords(ped))
    QBCore.Functions.TriggerCallback('i-tdm:get-new-bucketId', function(bucketId)
        QBCore.Functions.TriggerCallback('i-tdm:server:createTDMatch', function(matchId, mapTable)
            activeTDMId = matchId
            showJoinUi(map, mapTable)
        end, map, bucketId, password)
    end)
end

local function joinTeamDeathMatch(matchId, map)
    currTDmap = map
    currBucket = GetEntityPopulationType(GetEntityCoords(ped))
    QBCore.Functions.TriggerCallback('i-tdm:server:get-tdm-details', function(mapTable)
        activeTDMId = matchId
        showJoinUi(map, mapTable)
    end, matchId, map)
end

RegisterNetEvent("i-tdm:client:updateLobby", function(map, matchId, matchData)
    if InMatch then return end
    showJoinUi(map, matchData);
end);

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createSpawnBlip()
end)


local function DrawPolyZone(zoneData, color)
    local zone = PolyZone:Create(zoneData.zones, {
        name = zoneData.name,
        minZ = zoneData.minZ,
        maxZ = zoneData.maxZ,
        debugPoly = true,
        debugColors = {
            walls = color,
            outline = { 0, 0, 255 },
            grid = { 0, 0, 255 }
        }
    })
    return zone
end

local function GetRandomPointInZone(zoneData)
    local points = zoneData.zones
    local centerX, centerY = 0.0, 0.0
    for _, point in ipairs(points) do
        centerX += point.x
        centerY += point.y
    end
    centerX /= #points
    centerY /= #points
    return vector3(centerX, centerY, zoneData.minZ + 1.0)
end

local function sendToTeamSpawn()
    TriggerEvent("hospital:client:Revive")
    local ped = PlayerPedId()
    if TdmTeam == "blue" then
        local spawn = GetRandomPointInZone(TdmMap.blueZone)
        FreezeEntityPosition(ped, true)
        RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
        SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false)
        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
            Wait(0)
        end
        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, 0.0, 1000, true)
        FreezeEntityPosition(ped, false)
    elseif TdmTeam == "red" then
        local spawn = GetRandomPointInZone(TdmMap.redZone)
        FreezeEntityPosition(ped, true)
        RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
        SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false)
        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
            Wait(0)
        end
        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, 0.0, 1000, true)
        FreezeEntityPosition(ped, false)
    end
end

local function StartHealing()
    if HealThread then return end

    SetEntityInvincible(PlayerPedId(), true)

    HealThread = CreateThread(function()
        while InOwnSpawn do
            local ped = PlayerPedId()
            local hp = GetEntityHealth(ped)
            if hp < 200 then
                SetEntityHealth(ped, math.min(hp + 2, 200))
            end
            Wait(1000)
        end
    end)
end

local function StopHealing()
    InOwnSpawn = false
    HealThread = nil
    SetEntityInvincible(PlayerPedId(), false)
end

RegisterNetEvent("i-tdm:client:startTDM", function(data)
    SendNUIMessage({
        type = "close-ui",
        message = {}
        })
        SetNuiFocus(false, false)
    local mapName = data.map
    TdmTeam = data.team
    TdmMap = Config.TDM_maps[mapName]
    local matchId = data.matchId
    local bId = data.bucketId
    local ped = PlayerPedId()
    activeMatchId = matchId
    TDMMatchData = data.match
    TDMweapon = data.weapon

    if not TdmMap then return end
    for _, z in pairs(Zones) do
        z:destroy()
    end

    Zones = {}
    Zones.blue = DrawPolyZone(TdmMap.blueZone, { 0, 100, 255 })
    Zones.red = DrawPolyZone(TdmMap.redZone, { 255, 50, 50 })
    Zones.outer = DrawPolyZone(TdmMap.outerZone, { 255, 255, 255 })
    TriggerServerEvent('i-tdm:server:set-bucket', bId)
    SwitchOutPlayer(ped, 0, 1)
    Wait(2000)
    SetEntityInvincible(ped, true)
    ClearPedTasksImmediately(ped)
    Wait(2000)
    SwitchInPlayer(ped)
    QBCore.Functions.TriggerCallback('i-tdm:get-time', function(timeLeft)
        QBCore.Functions.TriggerCallback('i-tdm:get-player-stats', function(kills, deaths)
            DMKills = kills
            DMDeaths = deaths
            toggleHud(true, timeLeft, true)
            inTDM = true
            InMatch = true
            exports.ox_inventory:weaponWheel(true)
            TriggerEvent('wais:hudv6:client:hideHud', true)
            setClothes(TdmTeam)
            setPedPropertiesTdm(false, nil)
            Wait(2000)
            SetEntityInvincible(ped, false)
            sendToTeamSpawn()
            SetPedArmour(ped, 100)
            SetEntityHealth(ped, 200)
        end, mapName, matchId, true)
    end, mapName, matchId, true)

    local wasInsideOuter = nil

    Zones.outer:onPlayerInOut(function(isInside)
        if inTDM ~= true then return end
        if wasInsideOuter == nil then
            wasInsideOuter = isInside
            SendNUIMessage({ action = isInside and 'zone:clear' or 'zone:out', time = Config.TDMZoneOutKillTime })
            return
        end

        if wasInsideOuter ~= isInside then
            wasInsideOuter = isInside

            if isInside then
                SendNUIMessage({ action = 'zone:clear' })
            else
                SendNUIMessage({ action = 'zone:out', time = Config.TDMZoneOutKillTime })
            end
        end
    end)


    local ownZone = TdmTeam == "red" and Zones.red or Zones.blue
    ownZone:onPlayerInOut(function(isInside)
        InOwnSpawn = isInside
        if isInside then
            StartHealing()
        else
            StopHealing()
        end
    end)

    local enemyZone = TdmTeam == "red" and Zones.blue or Zones.red
    enemyZone:onPlayerInOut(function(isInside)
        InEnemySpawn = isInside
        if isInside then
            SendNUIMessage({ action = 'zone:enemy', time = Config.TDMEnemyZoneKillTime })
        else
            SendNUIMessage({ action = 'zone:clear' })
        end
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    RemoveBlip(startBlip)
    TriggerEvent('i-tdm:client:stop-dm')
end)

RegisterNetEvent('i-tdm:client:open-menu', function()
    SendNUIMessage({
        type = "open-ui",
        message = {}
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('i-tdm:client:stop-dm', function()
    if inTDM then
        inTDM = false
        InMatch = false
        exports.ox_inventory:weaponWheel(false)
        TriggerEvent('wais:hudv6:client:hideHud', false)
        local ped = PlayerPedId()
        toggleHud(false, 0, false)
        SwitchOutPlayer(ped, 0, 1)
        Wait(2000)
        TriggerServerEvent('i-tdm:server:set-bucket', currBucket)
        currBucket = nil
        SetEntityCoords(ped, Config.leaveSpawn, false, false, false, false)
        RemoveAllPedWeapons(ped)
        Wait(2000)
        SwitchInPlayer(PlayerPedId())
        NetworkResurrectLocalPlayer(Config.leaveSpawn, 1000, true)
        TriggerEvent("hospital:client:Revive")
        ExecuteCommand(Config.reloadSkinCommand)
        ExecuteCommand('refreshskin')
        TriggerServerEvent('i-tdm:server:remove-participant-tdm', currTDmap, activeMatchId)
        TdmTeam = nil
        currTDmap = nil
        InOwnSpawn = false
        InEnemySpawn = false
        HealThread = nil
        activeMatchId = nil
        DMDeaths = 0
        DMKills = 0
        for _, z in pairs(Zones) do
            z:destroy()
        end
    elseif inDMatch then
        inDMatch = false
        InMatch = false
        TriggerEvent('wais:hudv6:client:hideHud', false)
        exports.ox_inventory:weaponWheel(false)
        local ped = PlayerPedId()
        toggleHud(false, 0, false)
        SwitchOutPlayer(ped, 0, 1)
        Wait(2000)
        TriggerServerEvent('i-tdm:server:set-bucket', currBucket)
        DMDeaths = 0
        DMKills = 0
        currBucket = nil
        SetEntityCoordsNoOffset(ped, Config.leaveSpawn.x, Config.leaveSpawn.y, Config.leaveSpawn.z, false, false,
            false)
        RequestCollisionAtCoord(Config.leaveSpawn.x, Config.leaveSpawn.y, Config.leaveSpawn.z)
        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(Config.leaveSpawn.x, Config.leaveSpawn.y, Config.leaveSpawn.z)
            Wait(0)
        end
        RemoveAllPedWeapons(ped)
        Wait(2000)
        SwitchInPlayer(PlayerPedId())
        NetworkResurrectLocalPlayer(Config.leaveSpawn, true, false)
        TriggerEvent("hospital:client:Revive")
        ExecuteCommand(Config.reloadSkinCommand)
        deathMatchZone:destroy()
        TriggerEvent('i-tdm:toggle-ambulance-job', true)
        TriggerServerEvent('i-tdm:server:remove-participant', currDmap, activeMatchId)
        currDmap = nil
        activeMatchId = nil
    else
        notify('you are not in a match', 'error')
    end
end)

RegisterNetEvent('i-tdm:client:show-kill-msg', function(killerName, victimName)
    pedId = PlayerId()
    local localPlayerName = QBCore.Functions.GetPlayerData().charinfo.firstname .. " " .. QBCore.Functions.GetPlayerData().charinfo.lastname
    if (killerName == localPlayerName) then
        showKillMessage(killerName, victimName, 'killed')
    elseif (victimName == localPlayerName) then
        showKillMessage(killerName, victimName, 'dead')
    elseif (killerName == victimName) then
        showKillMessage(killerName, victimName, 'suicide')
    else
        showKillMessage(killerName, victimName, 'other')
    end
end)

RegisterNetEvent('i-tdm:client:show-kill-msg-tdm', function(killerName, victimName, victimTeam, redKills, blueKills)
    SendNUIMessage({
        type = "kill-msg-tdm",
        message = {
            killer = killerName,
            killed = victimName,
            type = victimTeam==TdmTeam and 'dead' or 'killed',
            redKills = redKills,
            blueKills = blueKills
        }
    })
end)

RegisterNetEvent('i-tdm:client:update-hud-stats', function(kills, deaths, heal)
    DMKills = kills
    DMDeaths = deaths
    if heal then
        SetEntityHealth(PlayerPedId(), 200)
        SetPedArmour(ped, 100)
    end
end)

RegisterNetEvent('i-tdm:client:show-results', function(stats, type, winningTeam,blueTeamStats,redTeamStats)
    if type == 'dm' then 
        SendNUIMessage({
            type = 'matchend',
            mode = 'deathmatch',
            players = stats
        })
    elseif type == 'tdm' then
            SendNUIMessage({
                type = 'matchend',
                mode = 'team-deathmatch',
                winningTeam= winningTeam,
                players = {},
                blueTeamPlayers = blueTeamStats,
                redTeamPlayers= redTeamStats
        })
    end
    SetNuiFocus(true,true)
end)

RegisterNetEvent('i-tdm:client:kick-player-tdm', function()
    SendNUIMessage({
        type = "close-ui",
        message = {}
    })
    SetNuiFocus(false, false)
    notify('You have been kicked from the match', 'error')
end)

AddEventHandler('onResourceStart', function(resource)
    if (GetCurrentResourceName() ~= resource) then
        return
    end
    createSpawnBlip()
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('startDeathMatch', function(data, cb)
    startDeathMatch(data.selectedMap)
    cb("ok")
end)

RegisterNUICallback('get-maps', function(data, cb)
    local maps = {}
    if data.isTdm then
        for _, v in pairs(Config.TDM_maps) do
            maps[#maps + 1] = {
                name = v.name,
                label = v.label,
                image = v.image
            }
        end
    else
        for _, v in pairs(Config.DM_maps) do
            maps[#maps + 1] = {
                name = v.name,
                label = v.label,
                image = v.image
            }
        end
    end
    cb(maps)
end)

RegisterNUICallback('get-active-matches', function(data, cb)
    QBCore.Functions.TriggerCallback('i-tdm:get-active-matches', function(matches)
        cb(matches)
    end)
end)

RegisterNUICallback('get-active-matches-tdm', function(data, cb)
    QBCore.Functions.TriggerCallback('i-tdm:get-active-matches-tdm', function(matches)
        cb(matches)
    end)
end)

RegisterNUICallback('join-dm', function(data, cb)
    sendToDmatchMap(data.map, data.matchId, data.bucketId)
    activeMatchId = data.matchId
    currDmap = data.map
    cb(true)
end)

RegisterNUICallback('join-tdm', function(data, cb)
    TriggerServerEvent('i-tdm:server:joinTeam', data)
    cb("ok")
end)

RegisterNUICallback("createTDM", function(data, cb)
    local password = data.password
    local map = data.map
    startTeamDeathMatch(map, password)
    cb("ok")
end)

RegisterNUICallback("join-tdm-lobby", function(data, cb)
    local matchId = data.matchId
    local map = data.map
    joinTeamDeathMatch(matchId, map)
    cb("ok")
end)

RegisterNUICallback("tdm-update-settings", function(data, cb)
    TriggerServerEvent('i-tdm:server:update-settings', data)
    cb("ok")
end)

RegisterNUICallback('start-tdm', function(data, cb)
    TriggerServerEvent('i-tdm:server:start-tdm', data)
    cb("ok")
end)

RegisterNUICallback('kick-tdm-player', function(data, cb)
    TriggerServerEvent('i-tdm:server:kick-tdm-player', data)
    cb("ok")
end)

RegisterNUICallback('delete-tdm', function(data, cb)
    TriggerServerEvent('i-tdm:server:delete-tdm', data)
    cb("ok")
end)

RegisterNUICallback('zoneDeath', function(data, cb)
    if data.reason == 'out-of-zone' then
        -- kill player
        SetEntityHealth(PlayerPedId(), 101)
        SetPedCanRagdoll(ped, true)
        SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)
        Wait(1000)
        if inDMatch then
            local _, lastWeapon = GetCurrentPedWeapon(ped)
            spawnToRandomPosDm(currDmap, lastWeapon)
        else
            local _, lastWeapon = GetCurrentPedWeapon(ped)
            setPedPropertiesTdm(true, lastWeapon)
            sendToTeamSpawn()
        end
    elseif data.reason == 'enemy-zone' then
        SetEntityHealth(PlayerPedId(), 101)
        SetPedCanRagdoll(ped, true)
        SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)
        local _, lastWeapon = GetCurrentPedWeapon(ped)
        setPedPropertiesTdm(true, lastWeapon)
        sendToTeamSpawn()
    end

    cb('ok')
end)



CreateThread(function()
    RequestModel(GetHashKey(Config.startPed.model))
    while (not HasModelLoaded(GetHashKey(Config.startPed.model))) do
        Wait(1)
    end
    local starterPed = CreatePed(1, Config.startPed.hash, Config.startPed.pos, false, true)
    SetEntityInvincible(starterPed, true)
    SetBlockingOfNonTemporaryEvents(starterPed, true)
    FreezeEntityPosition(starterPed, true)

    exports.ox_target:addBoxZone({
        name = 'i-tdm-start',
        coords = Config.startPed.targetZone, -- vector3
        size = vec3(1, 1, Config.startPed.maxZ - Config.startPed.minZ),
        rotation = Config.startPed.targetHeading,
        debug = false,
        options = {
            {
                type = 'client',
                event = 'i-tdm:client:open-menu',
                icon = 'fa-solid fa-gun',
                label = 'Open TDM Menu',
                distance = 1.5
            }
        }
    })
end)

CreateThread(function()
    while true do
        if not InMatch then
            HideHudComponentThisFrame(19)
            DisableControlAction(2, 37, true)
        else
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
        end
        Wait(1)
    end
end)

local dmRespawning = false

AddEventHandler('gameEventTriggered', function(event, data)
    if (not inDMatch) and (not inTDM) then return end
    
    local ped = PlayerPedId()
    
    if event == 'CEventShockingSeenWeapon' or 
       event == 'CEventShockingGunshotFired' or 
       event == 'CEventShockingDeadPed' or
       event == 'CEventShockingPedInjured' or
       event == 'CEventShockingExplosion' or
       event == 'CEventShockingPedThreat' then
        return
    end
    
    if event ~= 'CEventNetworkEntityDamage' then return end
    local victim   = data[1]
    local attacker = data[2]

    if victim ~= PlayerPedId() then return end

    local health = GetEntityHealth(ped)

    if health <= 103 then
        if dmRespawning then return end
        CancelEvent()
        SetEntityHealth(ped, 200)

        dmRespawning = true
        if inDMatch then

            SetPedCanRagdoll(ped, true)
            SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)

            local attackerId = nil
            if attacker ~= ped and IsEntityAPed(attacker) and IsPedAPlayer(attacker) then
                attackerId = NetworkGetPlayerIndexFromPed(attacker)
            end

            if attackerId and attackerId ~= PlayerId() then
                TriggerServerEvent(
                    'i-tdm:server:send-kill-msg',
                    GetPlayerServerId(attackerId),
                    GetPlayerServerId(PlayerId()),
                    currDmap,
                    activeMatchId
                )
            end

            CreateThread(function()
                Wait(1000)

                local _, lastWeapon = GetCurrentPedWeapon(ped)
                spawnToRandomPosDm(currDmap, lastWeapon)

                ClearPedBloodDamage(ped)
                ResetPedMovementClipset(ped, 0.0)
                setPedProperties(true, lastWeapon)

                dmRespawning = false
            end)
        end

        if inTDM then
            -- local attackerPlayer = NetworkGetPlayerIndexFromPed(attacker)
            -- if attackerPlayer ~= -1 then
            --     local attackerSid = GetPlayerServerId(attackerPlayer)
            --     local victimSid   = GetPlayerServerId(PlayerId())

            --     print(GetPlayerServerId(attackerPlayer))
            --     print(GetPlayerServerId(victimSid))

            --     if GetPlayerTeamByServerId(attackerSid) == GetPlayerTeamByServerId(victimSid) then
            --         CancelEvent()
            --         return
            --     end
            -- end

            SetPedCanRagdoll(ped, true)
            SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)

            local attackerId = nil
            if attacker ~= ped and IsEntityAPed(attacker) and IsPedAPlayer(attacker) then
                attackerId = NetworkGetPlayerIndexFromPed(attacker)
            end

            if attackerId and attackerId ~= PlayerId() then
                TriggerServerEvent(
                    'i-tdm:server:send-kill-msg-tdm',
                    GetPlayerServerId(attackerId),
                    GetPlayerServerId(PlayerId()),
                    currTDmap,
                    activeTDMId,
                    TdmTeam
                )
            end

            CreateThread(function()
                Wait(1000)

                local _, lastWeapon = GetCurrentPedWeapon(ped)
                setPedPropertiesTdm(true, lastWeapon)
                sendToTeamSpawn()

                ClearPedBloodDamage(ped)
                ResetPedMovementClipset(ped, 0.0)

                dmRespawning = false
            end)
        end
    end
end)


CreateThread(function()
    while true do
        Wait(250)
        if inDMatch or inTDM then
            local ped = PlayerPedId()
            if GetEntityHealth(ped) <= 100 then
                SetEntityHealth(ped, 200)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if inDMatch or inTDM then
            local ped = PlayerPedId()
            local hp = GetEntityHealth(ped)
            local armor = GetPedArmour(ped)
            local weapon = GetSelectedPedWeapon(ped)
            local ammotype = GetPedAmmoTypeFromWeapon(ped, weapon)
            local ammo = GetPedAmmoByType(ped, ammotype)
            local _, clip = GetAmmoInClip(ped, weapon)
            local totalAmmo = ammo - clip
            updateHealthStats(hp, armor, totalAmmo, clip)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if TdmTeam and (InOwnSpawn or InEnemySpawn) then
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true) -- attack
            DisableControlAction(0, 25, true) -- aim
        end
    end
end)

exports('IsInMatch', function()
    return InMatch
end)