local currentPursuit = nil
local pursuitBlip = nil
local captureTimer = 0.0
local rewardBalance = 0

local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function clearBlip()
    if pursuitBlip and DoesBlipExist(pursuitBlip) then
        RemoveBlip(pursuitBlip)
    end
    pursuitBlip = nil
end

local function createRacerBlip(racerServerId)
    clearBlip()

    local racerPlayer = GetPlayerFromServerId(racerServerId)
    if racerPlayer == -1 then return end

    local racerPed = GetPlayerPed(racerPlayer)
    pursuitBlip = AddBlipForEntity(racerPed)

    SetBlipSprite(pursuitBlip, Config.BlipSprite)
    SetBlipColour(pursuitBlip, Config.BlipColor)
    SetBlipScale(pursuitBlip, Config.BlipScale)
    SetBlipAsShortRange(pursuitBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Racer poursuivi')
    EndTextCommandSetBlipName(pursuitBlip)
end

RegisterCommand(Config.StartPursuitCommand, function(_, args)
    if currentPursuit then
        notify('~r~Une poursuite est déjà active.')
        return
    end

    local targetServerId = tonumber(args[1])
    if not targetServerId then
        notify('~y~Usage: /' .. Config.StartPursuitCommand .. ' [serverId du racer]')
        return
    end

    TriggerServerEvent('hp:server:startPursuit', targetServerId)
end)

RegisterCommand(Config.StopPursuitCommand, function()
    if not currentPursuit then
        notify('~y~Aucune poursuite active.')
        return
    end
    TriggerServerEvent('hp:server:stopPursuit', currentPursuit.id)
end)

RegisterNetEvent('hp:client:pursuitStarted', function(pursuitId, racerServerId, endsAt)
    currentPursuit = {
        id = pursuitId,
        racerServerId = racerServerId,
        endsAt = endsAt,
        role = 'police'
    }

    createRacerBlip(racerServerId)
    notify('~b~Poursuite lancée !')
end)

RegisterNetEvent('hp:client:youArePursued', function(pursuitId, policeServerId, endsAt)
    currentPursuit = {
        id = pursuitId,
        policeServerId = policeServerId,
        endsAt = endsAt,
        role = 'racer'
    }

    notify('~r~Tu es poursuivi ! Sème les flics !')
end)

RegisterNetEvent('hp:client:pursuitEnded', function(pursuitId, captured, reason)
    if not currentPursuit or currentPursuit.id ~= pursuitId then
        return
    end

    clearBlip()
    captureTimer = 0.0

    if captured then
        notify('~g~Poursuite terminée: ' .. reason)
    else
        notify('~y~Poursuite terminée: ' .. reason)
    end

    currentPursuit = nil
end)

RegisterNetEvent('hp:client:reward', function(amount)
    rewardBalance = rewardBalance + amount
    notify(('~g~Récompense +$%s | Total session: $%s'):format(amount, rewardBalance))
end)

CreateThread(function()
    while true do
        Wait(250)

        if not currentPursuit then
            goto continue
        end

        local now = os.time()
        local remaining = math.max(0, currentPursuit.endsAt - now)

        if currentPursuit.role == 'police' then
            local mePed = PlayerPedId()
            local meVeh = GetVehiclePedIsIn(mePed, false)

            local racerPlayer = GetPlayerFromServerId(currentPursuit.racerServerId)
            if racerPlayer == -1 then
                TriggerServerEvent('hp:server:stopPursuit', currentPursuit.id)
                goto continue
            end

            local racerPed = GetPlayerPed(racerPlayer)
            local racerVeh = GetVehiclePedIsIn(racerPed, false)
            local racerPos = GetEntityCoords(racerPed)
            local mePos = GetEntityCoords(mePed)
            local distance = #(mePos - racerPos)

            local racerSpeed = 0.0
            if racerVeh ~= 0 then
                racerSpeed = GetEntitySpeed(racerVeh)
            else
                racerSpeed = GetEntitySpeed(racerPed)
            end

            if distance <= Config.MaxCaptureDistance and racerSpeed <= Config.CaptureSpeedThreshold then
                captureTimer = captureTimer + 0.25
            else
                captureTimer = 0.0
            end

            if captureTimer >= Config.CaptureHoldTime then
                TriggerServerEvent('hp:server:requestCaptureCheck', currentPursuit.id, true)
                captureTimer = 0.0
            elseif remaining <= 0 then
                TriggerServerEvent('hp:server:requestCaptureCheck', currentPursuit.id, false)
            end

            local pct = math.floor((captureTimer / Config.CaptureHoldTime) * 100)
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName((
                '~b~Poursuite: ~w~%ss  ~b~Distance: ~w~%sm  ~b~Arrestation: ~w~%s%%'
            ):format(remaining, math.floor(distance), pct))
            EndTextCommandDisplayHelp(0, false, false, 1)
        else
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(('~r~Fuis ! ~w~Temps restant: %ss'):format(remaining))
            EndTextCommandDisplayHelp(0, false, false, 1)

            if remaining <= 0 then
                TriggerServerEvent('hp:server:stopPursuit', currentPursuit.id)
            end
        end

        ::continue::
    end
end)
