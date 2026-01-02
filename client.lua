-- az_welcome_firstcar / client.lua
-- Requires ox_lib

local hasTriggeredMovementCheck = false
local hasShownThisSession = false

local function secondsToPretty(s)
    s = tonumber(s) or 0
    if s <= 0 then return "0s" end

    local hours = math.floor(s / 3600)
    local mins  = math.floor((s % 3600) / 60)
    local secs  = math.floor(s % 60)

    if hours > 0 then
        return string.format("%dh %dm", hours, mins)
    elseif mins > 0 then
        return string.format("%dm %ds", mins, secs)
    else
        return string.format("%ds", secs)
    end
end

local function tryShowWelcome()
    if hasShownThisSession then return end

    local shouldShow = lib.callback.await('az_welcome_firstcar:shouldShowWelcome', false)
    if not shouldShow then
        -- Don't permanently block this session just because server said no.
        -- (In "ShowEverySession" mode, server should return true anyway.)
        return
    end

    lib.alertDialog({
        header   = Config.Welcome.Header,
        content  = Config.Welcome.Content,
        centered = Config.Welcome.Centered,
        cancel   = false,
        size     = Config.Welcome.Size or 'md'
    })

    -- In ShowEverySession mode the server event is a no-op (good).
    TriggerServerEvent('az_welcome_firstcar:markWelcomeSeen')

    hasShownThisSession = true
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(250)
    end

    local ped = PlayerPedId()
    local startCoords = GetEntityCoords(ped)

    while true do
        Wait(250)

        if hasTriggeredMovementCheck then
            Wait(1000)
            goto continue
        end

        ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        local dist = #(coords - startCoords)
        if dist >= (Config.Welcome.MoveThreshold or 1.5) then
            hasTriggeredMovementCheck = true
            tryShowWelcome()
        end

        ::continue::
    end
end)

-- Random sedan selector
local function getRandomFirstCarModel()
    local list = Config.FirstCar.SedanModels or {}
    if #list == 0 then
        return "asea"
    end
    return list[math.random(1, #list)]
end

-- Plate format: 1ST-NN
local function makeFirstCarPlate()
    return string.format("1ST-%d%d", math.random(0, 9), math.random(0, 9))
end

-- /firstcar command
RegisterCommand('firstcar', function()
    local result = lib.callback.await('az_welcome_firstcar:claimFirstCar', false)

    if not result or not result.ok then
        local remaining = result and result.remaining or (Config.FirstCar.CooldownSeconds or 0)
        local msg = ("You already claimed your free car. Come back in **%s**."):format(secondsToPretty(remaining))

        lib.notify({
            title = "First Car",
            description = msg,
            type = "error"
        })

        if Config.FirstCar.ShowCooldownChatMessage then
            TriggerEvent('chat:addMessage', {
                args = { "^1First Car", msg }
            })
        end
        return
    end

    local chosenName = getRandomFirstCarModel()
    local model = joaat(chosenName)

    if not IsModelInCdimage(model) then
        lib.notify({
            title = "First Car",
            description = "Vehicle model is invalid in config.",
            type = "error"
        })
        return
    end

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Spawn slightly in front
    local forward = GetEntityForwardVector(ped)
    local spawn = coords + (forward * 3.0)

    local veh = CreateVehicle(model, spawn.x, spawn.y, spawn.z, heading, true, false)
    SetModelAsNoLongerNeeded(model)

    if veh and veh ~= 0 then
        SetVehicleOnGroundProperly(veh)

        -- Apply new plate format
        SetVehicleNumberPlateText(veh, makeFirstCarPlate())

        if Config.FirstCar.WarpIntoVehicle then
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end

        lib.notify({
            title = "First Car",
            description = ("Your free car **(%s)** has been delivered!\nRemember: **SHIFT + F** to park and save its spot."):format(chosenName),
            type = "success"
        })
    else
        lib.notify({
            title = "First Car",
            description = "Failed to spawn vehicle.",
            type = "error"
        })
    end
end, false)

TriggerEvent('chat:addSuggestion', '/firstcar', 'Claim your free starter car (1 per 24 hours).')
