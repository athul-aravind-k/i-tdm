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



--hoping tha this shit works and moving onn :(
local function getRandomLocation(variable)
    return variable[math.random(1, #variable)]
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
    print(map)
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

local function spawnToRandomPosDm(map)
    ped = PlayerPedId()
    local selectedMap = Config.DM_maps[map]
    local spawnPoints = selectedMap.spawnpoints
    local spawnPoint = spawnPoints[math.random(1, #spawnPoints)]
    local heading = GetEntityHeading(ped)
    NetworkResurrectLocalPlayer(spawnPoint.x, spawnPoint.y, spawnPoint.z + 0.5, heading, true, false)
    SetPedArmour(ped, 100)
    GiveWeaponToPed(ped, 0xAF113F99, 200, false, false)
    GiveWeaponToPed(ped, 0xFAD1F1C9, 200, false, true)
    SetEntityCoords(ped, spawnPoint)
end

local function startDeathMatch(map)
    inDMatch = true
    InMatch = true
    currDmap = map
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, 0xAF113F99, 200, false, false)
    GiveWeaponToPed(ped, 0xFAD1F1C9, 200, false, true)
    SetPedArmour(ped, 100)
    SetEntityHealth(ped, 200)
    TriggerEvent('i-tdm:toggle-ambulance-job', false)
    createDeathMatchZone(map)
    local selectedMap = Config.DM_maps[map]
    local spawnPoints = selectedMap.spawnpoints
    local spawnPoint = spawnPoints[math.random(0, #spawnPoints)]
    SwitchOutPlayer(PlayerPedId(), 0, 1)
    Citizen.Wait(2000)
    SetEntityCoords(ped, spawnPoint)
    Citizen.Wait(2000)
    SwitchInPlayer(PlayerPedId())
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
        local ped = PlayerPedId()
        SwitchOutPlayer(ped, 0, 1)
        Citizen.Wait(2000)
        NetworkResurrectLocalPlayer(Config.startPed.pos, true, false)
        SetEntityCoords(ped, Config.startPed.pos)
        RemoveWeaponFromPed(ped, 0xAF113F99)
        RemoveWeaponFromPed(ped, 0xFAD1F1C9)
        Citizen.Wait(2000)
        SwitchInPlayer(PlayerPedId())
        inDMatch = false
        InMatch = false
        deathMatchZone:destroy()
        TriggerEvent('i-tdm:toggle-ambulance-job', true)
    else
        QBCore.Functions.Notify('you are not in a match', 'error', 2000)
    end
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
    local payload = {}
    local maps = {}
    if data.isTdm then
        for _, v in pairs(Config.TDM_maps) do
            maps[#maps + 1] = v.name
        end
    else
        for _, v in pairs(Config.DM_maps) do
            maps[#maps + 1] = v.name
        end
    end
    payload.maps = maps
    cb(payload)
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
        end
        Wait(1)
    end
end)

CreateThread(function()
    while true do
        if inDMatch then
            local ped = PlayerPedId()
            -- SetPedSuffersCriticalHits(ped) test this
            if IsEntityDead(ped) then
                Wait(5000)
                SetEntityHealth(ped, 200)
                spawnToRandomPosDm(currDmap)
            end
        end
        Wait(0)
    end
end)

-- AddEventHandler('CEventNetworkEntityDamage', function(attacker, weaponHash, damageAmt, boneIndex, entity)
--     -- Handle the event here

--     if boneIndex == 8 then
--         print("Headshot!")
--     else
--         print("Not a headshot.")
--     end
-- end)

AddEventHandler('gameEventTriggered', function(event, data)
    if inDMatch then
        if event == "CEventNetworkEntityDamage" then
            local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
            if not IsEntityAPed(victim) then return end
            if victimDied and NetworkGetPlayerIndexFromPed(victim) == PlayerId() and IsEntityDead(PlayerPedId()) then
                local playerid = NetworkGetPlayerIndexFromPed(victim)
                local playerName = GetPlayerName(playerid)
                local killerId = NetworkGetPlayerIndexFromPed(attacker)
                local killerName = GetPlayerName(killerId)
                local weaponLabel = QBCore.Shared.Weapons[weapon].label or 'Unknown'
                local weaponName = QBCore.Shared.Weapons[weapon].name or 'Unknown'
                print(killerName .. ' killed ' .. playerName .. ' with ' .. weaponLabel)
                print(' (' .. json.encode(data) .. ')')
            end
        end
    end
end)



exports('getTDMstatus', function() return InMatch end)
