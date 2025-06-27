-- ================================================================
--                    МОДУЛЬ УТИЛИТ (Utils.lua)
-- ================================================================

local Utils = {}
Utils.__index = Utils

function Utils:Initialize(core)
    local self = setmetatable({}, Utils)
    self.Core = core
    
    print("✅ Utils инициализирован")
    return self
end

-- Функция поиска ближайшей цели
function Utils:GetClosestTarget(targetsList)
    local closestTargetPart, minDistance = nil, self.Core.Config.AimBot.FOVRadius
    
    for _, character in ipairs(targetsList) do
        local targetPart = character:FindFirstChild(self.Core.Config.AimBot.TargetPart)
        local humanoid = character:FindFirstChild("Humanoid")
        
        if targetPart and humanoid and humanoid.Health > 0 then
            local screenPos, onScreen = self.Core.Services.Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local distance = (getgenv().MousePosition - Vector2.new(screenPos.X, screenPos.Y)).magnitude
                if distance < minDistance then
                    minDistance, closestTargetPart = distance, targetPart
                end
            end
        end
    end
    
    return closestTargetPart
end

-- Функция предикта позиции
function Utils:GetPredictedPosition(targetPart)
    local finalPosition = targetPart.Position
    
    if self.Core.Config.AimBot.Prediction.Enabled and self.Core.Config.AimBot.Prediction.Strength > 0 then
        if targetPart.Velocity and typeof(targetPart.Velocity) == "Vector3" then
            finalPosition = finalPosition + (targetPart.Velocity * self.Core.Config.AimBot.Prediction.Strength)
        end
    end
    
    return finalPosition
end

-- Функция для Ray метода
function Utils:GetDirection(origin, targetPart)
    local finalPosition = self:GetPredictedPosition(targetPart)
    return (finalPosition - origin).Unit * 1000
end

-- Валидация аргументов для хуков
function Utils:ValidateArguments(args, rayMethod)
    if #args < rayMethod.ArgCountRequired then return false end
    
    local matches = 0
    for pos, argument in ipairs(args) do
        if typeof(argument) == rayMethod.Args[pos] then
            matches = matches + 1
        end
    end
    
    return matches >= rayMethod.ArgCountRequired
end

return Utils
