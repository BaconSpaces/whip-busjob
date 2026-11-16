-- main.lua by Tnoxious https://github.com/Tnoxious -- WhipFX edition
-- Script changes are under GPLv3 License and not to be made for sale or locked in a paywall system
-- you are free to make any changes for your own server

local RESOURCE = GetCurrentResourceName()
local TAG = RESOURCE .. ':buses'

-- Who has a bus out: [source] = { line, vehicleId, session, charId }
local shifts = {}

local function rollPay(range)
    return math.random(range.min, range.max)
end

local function makePlate(line)
    local prefix = Lang:t(line.platePrefix):upper():sub(1, 4)
    return (prefix .. tostring(math.random(1000, 9999))):sub(1, 8)
end

local function stopCoords(lineKey, index)
    local stops = Config.Stops[lineKey]
    local stop = stops and stops[index]
    if not stop then return nil end
    return vector3(stop.x, stop.y, stop.z)
end

--- May this player work a shift? With Config.OpenToEveryone, anybody may; otherwise they
--- must be a hired driver who is clocked on.
local function mayWork(src)
    if Config.OpenToEveryone then return true end
    return exports.whip_core:IsPlayerClockedOn(src, Config.JobKey) == true
end

local function endShift(src, despawn)
    local shift = shifts[src]
    if not shift then return nil end
    shifts[src] = nil
    if despawn and shift.vehicleId then
        Whip.core:DespawnVehicle(shift.vehicleId)
    end
    return shift
end

-- Declarations -------------------------------------------------------------

Whip.register(function()
    Whip.core:EnsureJob(Config.JobKey, {
        name = Config.JobName,
        icon = 'bus',
        roles = Config.JobRoles,
    })

    -- The depot clerk of each line, as a WHIP NPC so every player sees the same one.
    local clerks = {}
    for key, line in pairs(Config.Lines) do
        local npcId, netId = Whip.core:SpawnNpc({
            model = line.clerk.model,
            coords = line.clerk.coords,
            behaviour = 'stand',
            conditions = { invincible = true, canMove = false, reacts = false },
        }, { tag = TAG })

        if npcId then
            clerks[key] = netId
            if line.clerk.scenario then
                Whip.core:SetNpcState(npcId, { anim = { scenario = line.clerk.scenario } })
            end
        else
            Whip.startProblem('could not spawn the %s depot clerk: %s', key, tostring(netId))
        end
    end
    -- The client puts its prompts on these.
    GlobalState[RESOURCE .. ':clerks'] = clerks

    -- Taking a bus out of the depot ----------------------------------------
    Whip.core:SecureCallback(RESOURCE .. ':takeVehicle', {
        rateLimit = 2000,
        params = {
            { 'line', 'enum', Config.LineKeys },
            { 'model', 'key', 32 },
        },
        near = {
            range = 12.0,
            at = function(_, _, lineKey)
                local line = Config.Lines[lineKey]
                return line and vector3(line.depot.x, line.depot.y, line.depot.z) or nil
            end,
            message = Lang:t('error.you_notworker'),
        },
    }, function(source, player, lineKey, model)
        local line = Config.Lines[lineKey]

        if not mayWork(source) then
            return false, Lang:t('error.not_on_duty')
        end
        if shifts[source] then
            return false, Lang:t('error.you_haveactive_job')
        end

        local allowed = false
        for _, v in ipairs(line.vehicles) do
            if v == model then allowed = true break end
        end
        if not allowed then
            exports.whip_core:RecordEventRejection(RESOURCE .. ':takeVehicle', source, 'Model is not on this line')
            return false, Lang:t('error.you_notworker')
        end

        local receipt, err = exports.whip_core:ChargePlayer(source, Config.BusHirePrice, {
            reason = line.label .. ' -- bus hire',
        })
        if not receipt then
            return false, err or Lang:t('error.you_have_zofunds', Config.BusHirePrice)
        end

        local vehicleId, why = exports.whip_core:SpawnTempVehicle(model, line.depot, {
            forSource = source,
            locked = false,
            keyInIgnition = true,
            plate = makePlate(line),
            idleDespawn = false,
            tag = TAG,
        })
        if not vehicleId then
            exports.whip_core:RefundPlayer(receipt)
            return false, why or Lang:t('error.parking_blocked')
        end

        if not exports.whip_core:IsSessionCurrent(source, player.session) then
            exports.whip_core:DespawnVehicle(vehicleId)
            exports.whip_core:RefundPlayer(receipt)
            return false
        end

        local vehicle = exports.whip_core:GetVehicle(vehicleId)
        shifts[source] = {
            line = lineKey,
            vehicleId = vehicleId,
            session = player.session,
            charId = player.charId,
        }

        exports.whip_core:NotifyPlayer(source, Lang:t('success.you_have_paid', Config.BusHirePrice), 'success')
        return vehicle and vehicle.netId or false
    end)

    -- A passenger got on or off at a stop ----------------------------------
    Whip.core:SecureEvent(RESOURCE .. ':stopPay', {
        rateLimit = 1500,
        params = {
            { 'line', 'enum', Config.LineKeys },
            { 'stop', 'id', 1, 512 },
        },
        near = {
            range = 25.0,
            at = function(_, _, lineKey, stop)
                return stopCoords(lineKey, stop)
            end,
            message = Lang:t('error.not_in_bus'),
        },
    }, function(source, player, lineKey, stop)
        local shift = shifts[source]
        if not shift or shift.line ~= lineKey then
            return false, Lang:t('error.no_bus_out')
        end
        if not mayWork(source) then
            return false, Lang:t('error.not_on_duty')
        end

        -- They must actually be in the bus they hired.
        local vehicleId = exports.whip_core:GetPlayerVehicle(source, { driver = true })
        if vehicleId ~= shift.vehicleId then
            return false, Lang:t('error.not_in_bus')
        end

        local amount = rollPay(Config[Config.Lines[lineKey].pay])
        local paid = exports.whip_core:PayPlayer(source, amount, {
            reason = Config.Lines[lineKey].label .. ' -- fare',
        })
        if not paid then return false end

        exports.whip_core:NotifyPlayer(source, Lang:t('success.server_npc_paid', amount), 'success')
    end)

    -- Bus brought back to the depot ----------------------------------------
    Whip.core:SecureEvent(RESOURCE .. ':finishShift', {
        rateLimit = 2000,
        params = {
            { 'line', 'enum', Config.LineKeys },
        },
        near = {
            range = 15.0,
            at = function(_, _, lineKey)
                local line = Config.Lines[lineKey]
                return line and vector3(line.depot.x, line.depot.y, line.depot.z) or nil
            end,
            message = Lang:t('error.you_notworker'),
        },
    }, function(source, player, lineKey)
        local shift = shifts[source]
        if not shift or shift.line ~= lineKey then
            return false, Lang:t('error.no_bus_out')
        end

        local vehicleId = exports.whip_core:GetPlayerVehicle(source, { driver = true })
        if vehicleId ~= shift.vehicleId then
            return false, Lang:t('error.not_in_bus')
        end

        endShift(source, true)

        local bonus = rollPay(Config.Bonus)
        if exports.whip_core:PayPlayer(source, bonus, { reason = Config.Lines[lineKey].label .. ' -- shift bonus' }) then
            exports.whip_core:NotifyPlayer(source, Lang:t('success.bonus_message', bonus), 'success')
        end
        TriggerClientEvent(RESOURCE .. ':client:shiftEnded', source, lineKey, false)
    end)

    -- The driver ditched the bus, or asked to stop with no pay -------------
    Whip.core:SecureEvent(RESOURCE .. ':cancelShift', {
        rateLimit = 1000,
        params = {
            { 'line', 'enum', Config.LineKeys },
        },
    }, function(source, player, lineKey)
        local shift = shifts[source]
        if not shift or shift.line ~= lineKey then return end
        endShift(source, true)
        TriggerClientEvent(RESOURCE .. ':client:shiftEnded', source, lineKey, true)
    end)
end)

-- Cleanup ------------------------------------------------------------------

AddEventHandler('playerDropped', function()
    endShift(source, true)
end)

AddEventHandler('whip_core:player:logout', function(data)
    if data and data.source then endShift(data.source, true) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE then return end
    for src in pairs(shifts) do
        endShift(src, true)
    end
end)

Whip.sayStarted()
