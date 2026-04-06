Config = {}

-- Commandes
Config.StartPursuitCommand = 'pursuit'
Config.StopPursuitCommand = 'stoppursuit'

-- Job autorisé pour l'interceptor (adapte selon ton framework)
Config.InterceptorJobName = 'interceptor'

-- Poursuite
Config.PursuitDuration = 180              -- secondes max
Config.CaptureSpeedThreshold = 2.0        -- m/s (~7.2 km/h)
Config.CaptureHoldTime = 8                -- secondes immobile pour être arrêté
Config.MaxCaptureDistance = 15.0          -- distance max entre flic et racer pour l'arrestation
Config.BlipSprite = 225
Config.BlipColor = 1
Config.BlipScale = 0.9

-- Score / récompense
Config.RewardPerCapture = 1500
Config.ScoreboardCommand = 'interceptorscore'
