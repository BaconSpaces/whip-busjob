-- busjob.lua by Tnoxious https://github.com/Tnoxious -- WhipFX edition
-- Script changes are under GPLv3 License and not to be made for sale or locked in a paywall system
-- you are free to make any changes for your own server
--
-- One controller drives every line in Config.Lines, so the City Bus and the Dashound
-- share the same code and a new line needs nothing but config.

local RESOURCE = GetCurrentResourceName()
local MARKER_COLOUR = { r = 174, g = 219, b = 242, a = 222 }

-- Runtime state per line key
local lines = {}

-- The components the work clothing covers: { componentId, config key }
local COMPONENTS = {
    { 3, 'arms' },
    { 4, 'pants' },
    { 6, 'boots' },
    { 8, 'shirt' },
    { 9, 'vest' },
    { 10, 'badge' },
    { 11, 'torso' },
}

local function notify(text, kind)
    exports.whip_core:Notify(text, kind or 'info')
end

--- What a prompt asks of the player. With Config.OpenToEveryone there is no job to ask for,
--- so only `extra` is required (the server checks the same way: see mayWork).
local function workRequire(extra)
    local req, any = {}, false
    for k, v in pairs(extra or {}) do req[k] = v; any = true end
    if not Config.OpenToEveryone then
        req.job = Config.JobKey
        req.onDuty = true
        any = true
    end
    return any and req or nil
end

local function isFreemode(ped)
    local model = GetEntityModel(ped)
    return model == GetHashKey('mp_m_freemode_01') or model == GetHashKey('mp_f_freemode_01')
end

local function isFemale(ped)
    return GetEntityModel(ped) == GetHashKey('mp_f_freemode_01')
end

--- Puts the line's work clothing on, remembering what was worn.
local function applyWorkClothing(state, line)
    if not Config.WorkClothing or state.outfit then return end

    local ped = PlayerPedId()
    if not isFreemode(ped) then return end

    local clothing = isFemale(ped) and line.clothing.female or line.clothing.male
    local saved = { components = {}, hat = { drawable = GetPedPropIndex(ped, 0), texture = GetPedPropTextureIndex(ped, 0) } }

    for _, entry in ipairs(COMPONENTS) do
        local id, key = entry[1], entry[2]
        saved.components[id] = {
            drawable = GetPedDrawableVariation(ped, id),
            texture = GetPedTextureVariation(ped, id),
            palette = GetPedPaletteVariation(ped, id),
        }
        if clothing[key] then
            SetPedComponentVariation(ped, id, clothing[key], 0, 0)
        end
    end

    if clothing.hat and clothing.hat >= 0 then
        SetPedPropIndex(ped, 0, clothing.hat, 0, true)
    else
        ClearPedProp(ped, 0)
    end

    state.outfit = saved
end

--- Puts back exactly what they were wearing before the shift.
local function resetWorkClothing(state)
    local saved = state.outfit
    if not saved then return end
    state.outfit = nil

    local ped = PlayerPedId()
    if not isFreemode(ped) then return end

    for id, was in pairs(saved.components) do
        SetPedComponentVariation(ped, id, was.drawable, was.texture, was.palette)
    end
    if saved.hat.drawable and saved.hat.drawable >= 0 then
        SetPedPropIndex(ped, 0, saved.hat.drawable, saved.hat.texture, true)
    else
        ClearPedProp(ped, 0)
    end
end

-- Stops --------------------------------------------------------------------

local function stopCount(lineKey)
    return #Config.Stops[lineKey]
end

local function stopAt(lineKey, index)
    return Config.Stops[lineKey][index]
end

local function nextStop(state)
    local max = stopCount(state.key)
    if Config.RandomStops then
        state.route = math.random(1, max)
    elseif state.route < max then
        state.route = state.route + 1
    else
        state.route = 1
    end
end

-- Blips --------------------------------------------------------------------

local function clearBlip(handle)
    if handle and DoesBlipExist(handle) then RemoveBlip(handle) end
    return nil
end

local function routeBlip(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipColour(blip, 3)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 3)
    return blip
end

local function updateDepotBlip(state, line)
    local employed = Config.OpenToEveryone
    if not employed then
        for _, job in pairs(exports.whip_core:GetPlayerJobs() or {}) do
            if job.key == Config.JobKey then employed = true break end
        end
    end

    if employed and not state.depotBlip then
        local blip = AddBlipForCoord(line.depot.x, line.depot.y, line.depot.z)
        SetBlipSprite(blip, line.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, line.blip.scale)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, line.blip.colour)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Lang:t(line.depotName))
        EndTextCommandSetBlipName(blip)
        state.depotBlip = blip
    elseif not employed then
        state.depotBlip = clearBlip(state.depotBlip)
    end
end

-- Passengers ---------------------------------------------------------------

local function spawnPassenger(state, stop)
    local gender = math.random(1, #Config.NpcSkins)
    local skins = Config.NpcSkins[gender]
    local model = Whip.core:LoadModel(skins[math.random(1, #skins)])
    if not model then return nil end

    local ped = CreatePed(3, model, stop.x, stop.y, stop.z - 0.98, stop.w, false, true)
    SetModelAsNoLongerNeeded(model)
    PlaceObjectOnGroundProperly(ped)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    return ped
end

local function releasePassenger(ped)
    if not ped or not DoesEntityExist(ped) then return end
    SetEntityAsMissionEntity(ped, false, true)
    SetEntityAsNoLongerNeeded(ped)
    SetTimeout(60000, function()
        if DoesEntityExist(ped) then DeletePed(ped) end
    end)
end

local function clearPassenger(state)
    if state.passenger and DoesEntityExist(state.passenger) then
        DeletePed(state.passenger)
    end
    state.passenger = nil
end

-- Prompts ------------------------------------------------------------------

local function removeAction(state, slot)
    if state.actions[slot] then
        exports.whip_core:RemoveAction(state.actions[slot])
        state.actions[slot] = nil
    end
end

local function jobVehicle(state)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return nil end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= state.vehicle or GetPedInVehicleSeat(veh, -1) ~= ped then return nil end
    return veh
end

local offerStop, offerDelivery

--- The pick-up prompt at the current stop.
function offerStop(state, line)
    removeAction(state, 'stop')
    clearPassenger(state)
    state.target = stopAt(state.key, state.route)

    state.passenger = spawnPassenger(state, state.target)
    state.stopBlip = clearBlip(state.stopBlip)
    state.stopBlip = routeBlip(state.target)
    notify(Lang:t('info.goto_busstop'))

    local stop = state.target
    local index = state.route
    state.actions.stop = exports.whip_core:AddAction({
        id = RESOURCE .. ':pickup:' .. state.key,
        at = { coords = vector3(stop.x, stop.y, stop.z) },
        label = Lang:t('info.pickup_text'),
        icon = 'bus',
        reach = 6.0,
        focusMode = 'near',
        require = workRequire({ vehicle = 'in' }),
        canInteract = function()
            return state.active and not state.carrying and jobVehicle(state) ~= nil
        end,
        onSelect = function()
            local veh = jobVehicle(state)
            if not veh then return notify(Lang:t('error.not_in_bus'), 'error') end

            local seat
            for i = GetVehicleMaxNumberOfPassengers(veh) - 1, 0, -1 do
                if IsVehicleSeatFree(veh, i) then seat = i break end
            end
            if not seat then
                return notify(Lang:t('error.bus_full'), 'error')
            end

            if state.passenger and DoesEntityExist(state.passenger) then
                ClearPedTasksImmediately(state.passenger)
                FreezeEntityPosition(state.passenger, false)
                TaskEnterVehicle(state.passenger, veh, -1, seat, 1.0, 0)
            end

            state.carrying = true
            state.stopBlip = clearBlip(state.stopBlip)
            removeAction(state, 'stop')

            TriggerServerEvent(RESOURCE .. ':stopPay', state.key, index)
            notify(Lang:t('info.drive_passanger'))

            nextStop(state)
            offerDelivery(state, line)
        end,
    })
end

--- The drop-off prompt at the next stop along.
function offerDelivery(state, line)
    removeAction(state, 'stop')
    state.target = stopAt(state.key, state.route)
    state.stopBlip = clearBlip(state.stopBlip)
    state.stopBlip = routeBlip(state.target)

    local stop = state.target
    local index = state.route
    state.actions.stop = exports.whip_core:AddAction({
        id = RESOURCE .. ':dropoff:' .. state.key,
        at = { coords = vector3(stop.x, stop.y, stop.z) },
        label = Lang:t('info.dropoff_text'),
        icon = 'bus',
        reach = 6.0,
        focusMode = 'near',
        require = workRequire({ vehicle = 'in' }),
        canInteract = function()
            return state.active and state.carrying and jobVehicle(state) ~= nil
        end,
        onSelect = function()
            local veh = jobVehicle(state)
            if not veh then return notify(Lang:t('error.not_in_bus'), 'error') end

            local ped = state.passenger
            if ped and DoesEntityExist(ped) then
                TaskLeaveVehicle(ped, veh, 0)
                TaskGoStraightToCoord(ped, stop.x, stop.y, stop.z, 1.0, -1, stop.w, 0.0)
                releasePassenger(ped)
            end
            state.passenger = nil
            state.carrying = false
            state.stopBlip = clearBlip(state.stopBlip)
            removeAction(state, 'stop')

            notify(Lang:t('success.dropped_off'), 'success')
            if Config.NpcPaysAllStops then
                TriggerServerEvent(RESOURCE .. ':stopPay', state.key, index)
            end

            nextStop(state)
            offerStop(state, line)
        end,
    })
end

-- Shifts -------------------------------------------------------------------

local function stopShift(state, silent)
    removeAction(state, 'stop')
    state.stopBlip = clearBlip(state.stopBlip)
    clearPassenger(state)
    state.active = false
    state.carrying = false
    state.vehicle = nil
    state.target = nil
    resetWorkClothing(state)
    if not silent then
        notify(Lang:t('success.bus_youparked'), 'success')
    end
end

local function anotherLineBusy(key)
    for other, state in pairs(lines) do
        if other ~= key and state.active then return true end
    end
    return false
end

local function takeBus(state, line, model)
    if state.active then
        return notify(Lang:t('error.one_bus_active'), 'error')
    end
    if anotherLineBusy(state.key) then
        return notify(Lang:t('error.two_jobs_alert'), 'error')
    end
    -- whip_core checks the spawn spot itself and answers why when it is blocked.
    local netId, why = exports.whip_core:Callback(RESOURCE .. ':takeVehicle', state.key, model)
    if not netId then
        return notify(why or Lang:t('error.you_notworker'), 'error')
    end

    local timeout = GetGameTimer() + 10000
    while not NetworkDoesNetworkIdExist(netId) and GetGameTimer() < timeout do
        Wait(50)
    end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(veh) then
        TriggerServerEvent(RESOURCE .. ':cancelShift', state.key)
        return notify(Lang:t('error.parking_blocked'), 'error')
    end

    state.active = true
    state.carrying = false
    state.vehicle = veh
    state.route = 1

    applyWorkClothing(state, line)
    SetVehicleEngineOn(veh, true, true, false)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)

    offerStop(state, line)
end

-- Setup --------------------------------------------------------------------

local function clerkOptions(state, line)
    local options = {}

    if not Config.OpenToEveryone then
        options[#options + 1] = {
            id = 'clockon',
            label = Lang:t('info.clock_on'),
            icon = 'clock',
            require = { job = Config.JobKey },
            canInteract = function() return not exports.whip_core:IsPlayerClockedOn(Config.JobKey) end,
            onSelect = function(ctx)
                local ok, why = exports.whip_core:ClockOn(Config.JobKey)
                if not ok then return ctx.refuse(why) end
                notify(Lang:t('success.clocked_on'), 'success')
            end,
        }
    end

    for _, model in ipairs(line.vehicles) do
        local display = GetLabelText(GetDisplayNameFromVehicleModel(GetHashKey(model)))
        options[#options + 1] = {
            id = 'take:' .. model,
            label = Lang:t('info.take_bus', (display ~= 'NULL' and display ~= '') and display or model),
            icon = 'bus',
            require = workRequire(),
            canInteract = function() return not state.active end,
            onSelect = function()
                takeBus(state, line, model)
            end,
        }
    end

    if not Config.OpenToEveryone then
        options[#options + 1] = {
            id = 'clockoff',
            label = Lang:t('info.clock_off'),
            icon = 'clock',
            require = workRequire(),
            canInteract = function() return not state.active end,
            onSelect = function()
                exports.whip_core:ClockOff(Config.JobKey)
                notify(Lang:t('success.clocked_off'), 'success')
            end,
        }
    end

    return options
end

Whip.register(function()
    for key, line in pairs(Config.Lines) do
        local state = lines[key] or {
            key = key,
            route = 1,
            active = false,
            carrying = false,
            actions = {},
        }
        lines[key] = state

        updateDepotBlip(state, line)

        -- The depot clerk: clock on or off and sign a bus out. The server publishes its
        -- netId in GlobalState, which may land after we register, so wait for it.
        CreateThread(function()
            local deadline = GetGameTimer() + 60000
            local netId
            repeat
                local clerks = GlobalState[RESOURCE .. ':clerks']
                netId = clerks and clerks[key]
                if not netId then Wait(500) end
            until netId or GetGameTimer() > deadline

            if not netId then return end
            removeAction(state, 'clerk')
            state.actions.clerk = exports.whip_core:AddAction({
                id = RESOURCE .. ':clerk:' .. key,
                at = { netId = netId, offset = vector3(0.0, 0.0, 0.4) },
                label = line.label,
                icon = 'bus',
                options = clerkOptions(state, line),
            })
        end)

        -- Parking the bus up at the depot ends the shift and pays the bonus.
        removeAction(state, 'depot')
        state.actions.depot = exports.whip_core:AddAction({
            id = RESOURCE .. ':depot:' .. key,
            at = { coords = vector3(line.depot.x, line.depot.y, line.depot.z) },
            label = Lang:t('info.bus_stop_work'),
            icon = 'bus',
            reach = 8.0,
            focusMode = 'near',
            require = workRequire({ vehicle = 'in' }),
            canInteract = function()
                return state.active and jobVehicle(state) ~= nil
            end,
            onSelect = function()
                if state.carrying then
                    return notify(Lang:t('error.drop_off_passengers'), 'error')
                end
                TriggerServerEvent(RESOURCE .. ':finishShift', state.key)
            end,
        })
    end
end)

-- The depot blips follow the player's job
AddEventHandler('whip_core:player:loaded', function()
    for key, state in pairs(lines) do
        updateDepotBlip(state, Config.Lines[key])
    end
end)

AddEventHandler('whip_core:job:listChanged', function()
    for key, state in pairs(lines) do
        updateDepotBlip(state, Config.Lines[key])
    end
end)

RegisterNetEvent(RESOURCE .. ':client:shiftEnded', function(key, cancelled)
    local state = lines[key]
    if not state then return end
    stopShift(state, cancelled)

    if not cancelled then return end
    notify(Lang:t('error.killed_job'), 'error')

    if Config.TelePlayer then
        Wait(1000)
        local ped = PlayerPedId()
        DoScreenFadeOut(200)
        Wait(300)
        SetEntityCoords(ped, Config.TelePlayerTo.x, Config.TelePlayerTo.y, Config.TelePlayerTo.z, false, false, false, false)
        SetEntityHeading(ped, Config.TelePlayerTo.w)
        Wait(1200)
        DoScreenFadeIn(200)
    end
end)

-- Watchdog: a driver who walks away from the job bus loses the shift
CreateThread(function()
    while true do
        Wait(1000)
        for key, state in pairs(lines) do
            if state.active then
                if jobVehicle(state) then
                    state.awayFor = 0
                else
                    state.awayFor = (state.awayFor or 0) + 1
                    if state.awayFor >= 20 then
                        state.awayFor = 0
                        TriggerServerEvent(RESOURCE .. ':cancelShift', key)
                    end
                end
            end
        end
    end
end)

-- Markers on the active stop (and on every stop while laying out new ones)
CreateThread(function()
    while true do
        local sleep = 500
        for key, state in pairs(lines) do
            if state.active and state.target then
                local ped = PlayerPedId()
                local target = state.target
                if #(GetEntityCoords(ped) - vector3(target.x, target.y, target.z)) < 50.0 then
                    sleep = 0
                    DrawMarker(1, target.x, target.y, target.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        4.0, 4.0, 1.0, MARKER_COLOUR.r, MARKER_COLOUR.g, MARKER_COLOUR.b, MARKER_COLOUR.a,
                        false, false, 2, false, nil, nil, false)
                end
            end

            if Config.DebugZones then
                sleep = 0
                local coords = GetEntityCoords(PlayerPedId())
                for _, stop in ipairs(Config.Stops[key]) do
                    if #(coords - vector3(stop.x, stop.y, stop.z)) < 100.0 then
                        DrawMarker(1, stop.x, stop.y, stop.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            4.0, 4.0, 1.0, 255, 80, 80, 120, false, false, 2, false, nil, nil, false)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE then return end
    for _, state in pairs(lines) do
        state.depotBlip = clearBlip(state.depotBlip)
        state.stopBlip = clearBlip(state.stopBlip)
        clearPassenger(state)
        resetWorkClothing(state)
    end
end)
