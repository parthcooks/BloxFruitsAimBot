-- ================================================================
--                    МОДУЛЬ AIMBOT (AimBot.lua)
-- ================================================================

local AimBot = {}
AimBot.__index = AimBot

function AimBot:Initialize(core, gui, utils)
    local self = setmetatable({}, AimBot)
    self.Core = core
    self.GUI = gui
    self.Utils = utils
    
    self:CreateFOVCircle()
    self:SetupAimBotHooks()
    self:SetupGunHook()
    self:StartFOVLoop()
    
    print("✅ AimBot инициализирован")
    return self
end

function AimBot:CreateFOVCircle()
    self.FOVCircle = Drawing.new("Circle")
    self.FOVCircle.Thickness = 1
    self.FOVCircle.NumSides = 100
    self.FOVCircle.Radius = self.Core.Config.AimBot.FOVRadius
    self.FOVCircle.Color = Color3.fromRGB(54, 57, 241)
    self.FOVCircle.Filled = false
    self.FOVCircle.Visible = self.Core.Config.AimBot.ShowFOV
    self.FOVCircle.ZIndex = 2
end

function AimBot:StartFOVLoop()
    task.spawn(function()
        while task.wait() do
            pcall(function()
                if self.Core.Config.AimBot.ShowFOV then
                    self.FOVCircle.Position = self.Core.Services.UserInput:GetMouseLocation()
                    self.FOVCircle.Radius = self.Core.Config.AimBot.FOVRadius
                    self.FOVCircle.Visible = true
                else
                    self.FOVCircle.Visible = false
                end
            end)
        end
    end)
end

function AimBot:SetupAimBotHooks()
    local ExpectedArguments = {
        FindPartOnRayWithIgnoreList = {
            ArgCountRequired = 3,
            Args = {"Instance", "Ray", "table", "boolean", "boolean"}
        }
    }
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
        if not self.Core.Config.AimBot.Enabled then return oldNamecall(...) end
        
        local targetsToSearch = getgenv().FilteredTargets or {}
        local target = self.Utils:GetClosestTarget(targetsToSearch)
        
        if target then
            local predictedPos = self.Utils:GetPredictedPosition(target)
            local method = getnamecallmethod()
            local arguments = {...}
            local selfArg = arguments[1]
            
            -- === RAY METHOD ===
            if self.Core.Config.AimBot.Method == "Ray" then
                if method == "FindPartOnRayWithIgnoreList" and selfArg == workspace and not checkcaller() then
                    if self.Utils:ValidateArguments(arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                        local originalRay = arguments[2]
                        
                        if originalRay.Direction.magnitude > self.Core.Config.AimBot.MinRayLength then
                            arguments[2] = Ray.new(originalRay.Origin, self.Utils:GetDirection(originalRay.Origin, target))
                            return oldNamecall(table.unpack(arguments))
                        end
                    end
                end
            end
            
            -- === FIRESERVER METHOD ===
            if self.Core.Config.AimBot.Method == "FireServer" then
                local secondArg = arguments[2]
                if method == "FireServer" and tostring(selfArg) == "RemoteEvent" and typeof(secondArg) == "Vector3" and not checkcaller() then
                    arguments[2] = predictedPos
                    return oldNamecall(table.unpack(arguments))
                end
            end
        end
        
        return oldNamecall(...)
    end))
end

function AimBot:SetupGunHook()
    local gunHook
    gunHook = hookmetamethod(game, "__namecall", newcclosure(function(...)
        if not self.Core.Config.AimBot.Gun then return gunHook(...) end
        
        local targetsToSearch = getgenv().FilteredTargets or {}
        local target = self.Utils:GetClosestTarget(targetsToSearch)
        
        if target then
            local predictedPos = self.Utils:GetPredictedPosition(target)
            local method = getnamecallmethod()
            local arguments = {...}
            local selfArg = arguments[1]
            
            if method == "FireServer" and tostring(selfArg) == "RemoteEvent" and arguments[2] == "TAP" and not checkcaller() then
                arguments[3] = predictedPos
                return gunHook(table.unpack(arguments))
            end
        end
        
        return gunHook(...)
    end))
end

return AimBot
