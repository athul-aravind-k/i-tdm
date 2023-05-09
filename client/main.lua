local QBCore = exports['qb-core']:GetCoreObject()
local blueZone = {}
local redZone = {}
local deathMatchZone = {}
local startBlip
local currDmap
local currTDmap
insideBlue = false
insideRed = false
insideDmz = false
InMatch = false
inTDM = false
inDMatch = false
local currBucket
local activeMatchId
local DMKills = 0
local DMDeaths = 0

--hoping tha this shit works and moving onn :(
local function getRandomLocation(variable)
    return variable[math.random(1, #variable)]
end

local function setClothes()
    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.charinfo.gender == 0 then
        SetPedComponentVariation(ped, 1, Config.Clothes.male['mask_1'], Config.Clothes.male['mask_2'], 0)          --mask
        SetPedComponentVariation(ped, 3, Config.Clothes.male['arms'], 0, 0)                                        --arms
        SetPedComponentVariation(ped, 8, Config.Clothes.male['tshirt_1'], Config.Clothes.male['tshirt_2'], 0)      --t-shirt
        SetPedComponentVariation(ped, 11, Config.Clothes.male['torso_1'], Config.Clothes.male['torso_2'], 0)       --torso2
        SetPedComponentVariation(ped, 9, Config.Clothes.male['bproof_1'], Config.Clothes.male['bproof_2'], 0)      --vest
        SetPedComponentVariation(ped, 10, Config.Clothes.male['decals_1'], Config.Clothes.male['decals_2'], 0)     --decals
        SetPedComponentVariation(ped, 7, Config.Clothes.male['chain_1'], Config.Clothes.male['chain_2'], 0)        --accessory
        SetPedComponentVariation(ped, 4, Config.Clothes.male['pants_1'], Config.Clothes.male['pants_2'], 0)        -- pants
        SetPedComponentVariation(ped, 6, Config.Clothes.male['shoes_1'], Config.Clothes.male['shoes_2'], 0)        --shoes
        SetPedPropIndex(ped, 0, Config.Clothes.male['helmet_1'], Config.Clothes.male['helmet_2'], true)            --hat
        SetPedPropIndex(ped, 2, Config.Clothes.male['ears_1'], Config.Clothes.male['ears_2'], true)                --ear
    else
        SetPedComponentVariation(ped, 1, Config.Clothes.female['mask_1'], Config.Clothes.female['mask_2'], 0)      --mask
        SetPedComponentVariation(ped, 3, Config.Clothes.female['arms'], 0, 0)                                      --arms
        SetPedComponentVariation(ped, 8, Config.Clothes.female['tshirt_1'], Config.Clothes.female['tshirt_2'], 0)  --t-shirt
        SetPedComponentVariation(ped, 11, Config.Clothes.female['torso_1'], Config.Clothes.female['torso_2'], 0)   --torso2
        SetPedComponentVariation(ped, 9, Config.Clothes.female['bproof_1'], Config.Clothes.female['bproof_2'], 0)  --vest
        SetPedComponentVariation(ped, 10, Config.Clothes.female['decals_1'], Config.Clothes.female['decals_2'], 0) --decals
        SetPedComponentVariation(ped, 7, Config.Clothes.female['chain_1'], Config.Clothes.female['chain_2'], 0)    --accessory
        SetPedComponentVariation(ped, 4, Config.Clothes.female['pants_1'], Config.Clothes.female['pants_2'], 0)    -- pants
        SetPedComponentVariation(ped, 6, Config.Clothes.female['shoes_1'], Config.Clothes.female['shoes_2'], 0)    --shoes
        SetPedPropIndex(ped, 0, Config.Clothes.female['helmet_1'], Config.Clothes.female['helmet_2'], true)        --hat
        SetPedPropIndex(ped, 2, Config.Clothes.female['ears_1'], Config.Clothes.female['ears_2'], true)            --ear
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
        if isPointInsideDmz then
            insideDmz = true
            --logic
        else
            insideDmz = false
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

local function spawnToRandomPosDm(map, lastWeapon)
    ped = PlayerPedId()
    local selectedMap = Config.DM_maps[map]
    local spawnPoints = selectedMap.spawnpoints
    local spawnPoint = spawnPoints[math.random(1, #spawnPoints)]
    local heading = GetEntityHeading(ped)
    NetworkResurrectLocalPlayer(spawnPoint.x, spawnPoint.y, spawnPoint.z + 0.5, heading, true, false)
    setPedProperties(true, lastWeapon)
    SetEntityCoords(ped, spawnPoint, false, false, false, false)
    SetEntityInvincible(ped, true)
    Wait(Config.pedInvincibleTime * 1000)
    SetEntityInvincible(ped, false)
end

local function toggleHud(bool, time)
    SendNUIMessage({
        type = 'toggle-hud',
        message = {
            bool = bool,
            time = time,
            totalTime = (Config.DMTime * 60 * 1000)
        }
    })
end

local function sendToDmatchMap(map, matchId, bucketId)
    local mId = tonumber(matchId)
    local bId = tonumber(bucketId)
    QBCore.Functions.TriggerCallback('i-tdm:check-match-validity', function(active, joinable)
        if active then
            if joinable then
                local ped = PlayerPedId()
                createDeathMatchZone(map)
                TriggerEvent("hospital:client:Revive")
                TriggerEvent('i-tdm:toggle-ambulance-job', false)
                TriggerServerEvent('i-tdm:server:set-bucket', bId)
                TriggerServerEvent('i-tdm:server:add-participant', map, mId)
                activeMatchId = mId
                local selectedMap = Config.DM_maps[map]
                local spawnPoints = selectedMap.spawnpoints
                local spawnPoint = spawnPoints[math.random(1, #spawnPoints)]
                QBCore.Functions.TriggerCallback('i-tdm:get-time', function(timeLeft)
                    SwitchOutPlayer(ped, 0, 1)
                    Wait(2000)
                    SetEntityInvincible(ped, true)
                    RequestCollisionAtCoord(spawnPoint.x, spawnPoint.y, spawnPoint.z)
                    SetEntityCoordsNoOffset(ped, spawnPoint.x, spawnPoint.y, spawnPoint.z, false, false, false, true)
                    NetworkResurrectLocalPlayer(spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.heading, true, true,
                        false)
                    ClearPedTasksImmediately(ped)
                    Wait(2000)
                    SwitchInPlayer(ped)
                    toggleHud(true, timeLeft)
                    setClothes()
                    setPedProperties(false, nil)
                    Wait(2000)
                    SetEntityInvincible(ped, false)
                    inDMatch = true
                    InMatch = true
                end, map, mId)
            else
                QBCore.Functions.Notify('match Full', 'error', 2000)
            end
        else
            QBCore.Functions.Notify('match doesnt exist', 'error', 2000)
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

local function createZones(mapName)
    local selectedMap = Config.maps[mapName]

    blueZone = PolyZone:Create(selectedMap.blueZone.zones, {
        name = selectedMap.blueZone.name,
        minZ = selectedMap.blueZone.minZ,
        maxZ = selectedMap.blueZone.maxZ,
        debugPoly = true
    })
    blueZone:onPlayerInOut(function(isPointInsideBlue)
        if isPointInsideBlue then
            insideBlue = true
            --logic
        else
            insideBlue = false
            --logic
        end
    end)
    redZone = PolyZone:Create(selectedMap.redZone.zones, {
        name = selectedMap.redZone.name,
        minZ = selectedMap.redZone.minZ,
        maxZ = selectedMap.redZone.maxZ,
        debugPoly = true
    })
    redZone:onPlayerInOut(function(isPointInsideBlue)
        if isPointInsideBlue then
            insideRed = true
            --logic
        else
            insideRed = false
            --logic
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createSpawnBlip()
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
    if inDMatch then
        inDMatch = false
        InMatch = false
        local ped = PlayerPedId()
        toggleHud(false, 0)
        SwitchOutPlayer(ped, 0, 1)
        Wait(2000)
        TriggerServerEvent('i-tdm:server:set-bucket', currBucket)
        DMDeaths = 0
        DMKills = 0
        currBucket = nil
        SetEntityCoords(ped, Config.startPed.pos, false, false, false, false)
        RemoveAllPedWeapons(ped)
        Wait(2000)
        SwitchInPlayer(PlayerPedId())
        NetworkResurrectLocalPlayer(Config.startPed.pos, true, false)
        TriggerEvent("hospital:client:Revive")
        TriggerEvent(Config.reloadSkinEvent)
        deathMatchZone:destroy()
        TriggerEvent('i-tdm:toggle-ambulance-job', true)
        TriggerServerEvent('i-tdm:server:remove-participant', currDmap, activeMatchId)
        currDmap = nil
        activeMatchId = nil
    else
        QBCore.Functions.Notify('you are not in a match', 'error', 2000)
    end
end)

RegisterNetEvent('i-tdm:client:show-kill-msg', function(killerName, victimName)
    pedId = PlayerId()
    local localPlayerName = GetPlayerName(pedId)
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
            maps[#maps + 1] = v.name
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

RegisterNUICallback('join-dm', function(data, cb)
    sendToDmatchMap(data.map, data.matchId, data.bucketId)
    activeMatchId = data.matchId
    currDmap = data.map
    cb(true)
end)

RegisterNUICallback('join-tdm', function(data, cb)
    --tdm join logic
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

    exports['qb-target']:AddBoxZone("startped", Config.startPed.targetZone, 1, 1, {
        name = "i-tdm=start",
        heading = Config.startPed.targetHeading,
        debugPoly = false,
        minZ = Config.startPed.minZ,
        maxZ = Config.startPed.maxZ,
    }, {
        options = {
            {
                type = "client",
                event = "i-tdm:client:open-menu",
                icon = "Fa fa-solid fa-gun",
                label = "Open TDM Menu",
            },
        },
        distance = 1.5
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

CreateThread(function()
    while true do
        if inDMatch then
            local ped = PlayerPedId()
            if IsEntityDead(ped) then
                local _, lastWeapon = GetCurrentPedWeapon(ped)
                Wait(2000)
                spawnToRandomPosDm(currDmap, lastWeapon)
                Wait(3000)
            end
            if inDMatch and not insideDmz then
                SetEntityHealth(ped, 0)
            end
        end
        Wait(0)
    end
end)

AddEventHandler('gameEventTriggered', function(event, data)
    if inDMatch then
        if event == "CEventNetworkEntityDamage" then
            local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
            if not IsPedAPlayer(victim) then
                return
            end
            if victimDied then
                local localPlayerPed = PlayerPedId()
                local victimPlayerId = NetworkGetPlayerIndexFromPed(victim)
                local attackerPlayerId = NetworkGetPlayerIndexFromPed(attacker)
                if victimPlayerId == PlayerId() and IsEntityDead(localPlayerPed) and IsEntityAPed(attacker) then
                    DMDeaths = DMDeaths + 1
                elseif attackerPlayerId == PlayerId() and IsEntityDead(victim) and IsEntityAPed(victim) then
                    TriggerServerEvent('i-tdm:server:send-kill-msg', GetPlayerName(attackerPlayerId),
                        GetPlayerName(victimPlayerId), currDmap,
                        activeMatchId)
                    DMKills = DMKills + 1
                    local _, lastWeapon = GetCurrentPedWeapon(ped)
                    setPedProperties(false, lastWeapon)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if inDMatch then
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
