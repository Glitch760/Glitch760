local activePursuits = {}
local interceptorScores = {}

local function isInterceptor(src)
    -- Base simple: remplace par vérification ESX/QBCore si besoin.
    -- Exemple ESX: xPlayer.job.name == Config.InterceptorJobName
    -- Exemple QBCore: Player.PlayerData.job.name == Config.InterceptorJobName
    return true
end

local function makePursuitId(policeSrc, racerSrc)
    return ("%s:%s:%s"):format(policeSrc, racerSrc, os.time())
end

RegisterNetEvent('hp:server:startPursuit', function(targetServerId)
    local policeSrc = source
    local racerSrc = tonumber(targetServerId)

    if not racerSrc or not GetPlayerName(racerSrc) then
        TriggerClientEvent('chat:addMessage', policeSrc, {
            args = { '^1SYSTEM', 'Cible invalide.' }
        })
        return
    end

    if not isInterceptor(policeSrc) then
        TriggerClientEvent('chat:addMessage', policeSrc, {
            args = { '^1SYSTEM', 'Tu n\'es pas interceptor.' }
        })
        return
    end

    local pursuitId = makePursuitId(policeSrc, racerSrc)
    local endsAt = os.time() + Config.PursuitDuration

    activePursuits[pursuitId] = {
        id = pursuitId,
        police = policeSrc,
        racer = racerSrc,
        endsAt = endsAt,
        captured = false,
        startedAt = os.time()
    }

    TriggerClientEvent('hp:client:pursuitStarted', policeSrc, pursuitId, racerSrc, endsAt)
    TriggerClientEvent('hp:client:youArePursued', racerSrc, pursuitId, policeSrc, endsAt)
end)

RegisterNetEvent('hp:server:requestCaptureCheck', function(pursuitId, isValid)
    local policeSrc = source
    local pursuit = activePursuits[pursuitId]

    if not pursuit or pursuit.police ~= policeSrc or pursuit.captured then
        return
    end

    if os.time() > pursuit.endsAt then
        TriggerClientEvent('hp:client:pursuitEnded', pursuit.police, pursuitId, false, 'Temps écoulé')
        TriggerClientEvent('hp:client:pursuitEnded', pursuit.racer, pursuitId, false, 'Tu as survécu à la poursuite')
        activePursuits[pursuitId] = nil
        return
    end

    if isValid then
        pursuit.captured = true

        interceptorScores[policeSrc] = (interceptorScores[policeSrc] or 0) + 1

        -- Récompense basique; remplace par ton économie serveur
        TriggerClientEvent('hp:client:reward', policeSrc, Config.RewardPerCapture)

        TriggerClientEvent('hp:client:pursuitEnded', pursuit.police, pursuitId, true, 'Racer arrêté')
        TriggerClientEvent('hp:client:pursuitEnded', pursuit.racer, pursuitId, true, 'Tu as été arrêté')
        activePursuits[pursuitId] = nil
    end
end)

RegisterNetEvent('hp:server:stopPursuit', function(pursuitId)
    local src = source
    local pursuit = activePursuits[pursuitId]
    if not pursuit then return end

    if pursuit.police ~= src and pursuit.racer ~= src then
        return
    end

    TriggerClientEvent('hp:client:pursuitEnded', pursuit.police, pursuitId, false, 'Poursuite annulée')
    TriggerClientEvent('hp:client:pursuitEnded', pursuit.racer, pursuitId, false, 'Poursuite annulée')
    activePursuits[pursuitId] = nil
end)

RegisterCommand(Config.ScoreboardCommand, function(src)
    local score = interceptorScores[src] or 0
    TriggerClientEvent('chat:addMessage', src, {
        args = { '^2INTERCEPTOR', ('Captures: %s'):format(score) }
    })
end, false)

AddEventHandler('playerDropped', function()
    local src = source

    for pursuitId, pursuit in pairs(activePursuits) do
        if pursuit.police == src or pursuit.racer == src then
            local other = pursuit.police == src and pursuit.racer or pursuit.police
            if GetPlayerName(other) then
                TriggerClientEvent('hp:client:pursuitEnded', other, pursuitId, false, 'Poursuite terminée (déconnexion)')
            end
            activePursuits[pursuitId] = nil
        end
    end
end)
