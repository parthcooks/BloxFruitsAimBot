-- ================================================================
--                     МОДУЛЬ SORU (Soru.lua)
-- ================================================================

local Soru = {}
Soru.__index = Soru

function Soru:Initialize(core, gui, utils)
    local self = setmetatable({}, Soru)
    self.Core = core
    self.GUI = gui
    self.Utils = utils
    
    self:LoadGameModules()
    self:StartSoruSystem()
    
    print("✅ Soru инициализирован")
    return self
end

function Soru:LoadGameModules()
    self.EffectService = require(self.Core.Services.ReplicatedStorage:WaitForChild("Effect"))
    self.UtilService = require(self.Core.Services.ReplicatedStorage.Util)
    self.MobileUI = require(self.Core.Services.ReplicatedStorage.Controllers.UI.MobileUIController)
    self.SoruEffect = self.EffectService.new("Shared.Soru")
    self.CommE = self.Core.Services.ReplicatedStorage.Remotes.CommE
end

function Soru:StartSoruSystem()
    self.SoruLoopActive = false
    
    -- Мониторим состояние переключателя
    task.spawn(function()
        local lastState = false
        while task.wait(0.1) do
            local currentState = self.Core.Config.Soru.Enabled
            if currentState ~= lastState then
                lastState = currentState
                if currentState then
                    print("[Soru] Enhanced Soru включен")
                    self:StartSoruLoop()
                else
                    print("[Soru] Enhanced Soru выключен, возврат к оригиналу")
                    self:StopSoruLoop()
                end
            end
        end
    end)
end

function Soru:StartSoruLoop()
    if self.SoruLoopActive then return end
    self.SoruLoopActive = true
    
    task.spawn(function()
        while self.SoruLoopActive do
            pcall(function()
                self.Core.Services.ContextAction:UnbindAction("BoundActionSoru")
                self.Core.Services.ContextAction:BindAction("BoundActionSoru", function(...) 
                    self:ModifiedSoruFunction(...) 
                end, false, Enum.KeyCode.R, Enum.KeyCode.ButtonR3)
            end)
            task.wait(0.1)
        end
    end)
end

function Soru:StopSoruLoop()
    self.SoruLoopActive = false
    pcall(function() 
        self.Core.Services.ContextAction:UnbindAction("BoundActionSoru") 
    end)
end

function Soru:ModifiedSoruFunction(actionName, inputState, inputObject)
    if inputState ~= Enum.UserInputState.Begin then return end
    
    local character = self.Core.LocalPlayer.Character
    if not character or not self.Core.Services.CollectionService:HasTag(character, "Soru") then return end
    
    -- Получаем параметры Soru
    local maxDistance, cooldown = 200, 15
    local isSkypieaEvolved = false
    
    if self.Core.LocalPlayer.Data.Race.Value == "Human" and self.Core.LocalPlayer.Data.Race:FindFirstChild("Evolved") then
        cooldown, maxDistance = 10, 350
    else
        isSkypieaEvolved = self.Core.LocalPlayer.Data.Race.Value == "Skypiea" and 
            (character:FindFirstChild("RaceTransformed") and character.RaceTransformed.Value)
        cooldown, maxDistance = 15, 200
    end
    
    local cooldownReduction = character:GetAttribute("FlashstepCooldown")
    if cooldownReduction and cooldownReduction > 0 then
        cooldown = cooldown * (1 - cooldownReduction)
    end
    
    -- Проверки состояния
    local humanoid, rootPart = character.Humanoid, character.HumanoidRootPart
    if humanoid.Health <= 0 or humanoid.Sit then return end
    if character.Busy.Value or character.Energy.Value < 10 then return end
    if character:FindFirstChild("Phoenix") or character:FindFirstChild("Dragon") or character:FindFirstChild("DisableMovement") then return end
    
    -- Проверка кулдауна
    local currentTime = tick()
    if currentTime - getgenv().SoruCooldownData.LastUse < cooldown then
        local charges = humanoid:GetAttribute("SoruCharges") or 0
        if charges > 0 then 
            humanoid:SetAttribute("SoruCharges", charges - 1) 
        else 
            return 
        end
    end
    
    -- Логика выбора цели или курсора
    local desiredPosition
    local target = self.Utils:GetClosestTarget(getgenv().FilteredTargets or {})
    
    if target and (target.Position - rootPart.Position).magnitude <= maxDistance then
        print("[Soru] Телепортируемся к цели:", target.Parent.Name)
        desiredPosition = target.Position
    else
        if target then 
            print("[Soru] Цель слишком далеко, используем курсор") 
        else 
            print("[Soru] Цель не найдена, используем курсор") 
        end
        
        local mouse = self.Core.LocalPlayer:GetMouse()
        if mouse and mouse.Hit then 
            desiredPosition = mouse.Hit.p 
        else 
            return 
        end
    end
    
    -- Ограничение дистанции
    if maxDistance < (desiredPosition - rootPart.Position).magnitude then
        if not isSkypieaEvolved then return end
        desiredPosition = (CFrame.new(rootPart.Position, desiredPosition) * CFrame.new(0, 0, -maxDistance)).Position
    end
    
    -- Выполнение телепорта
    local startCFrame = rootPart.CFrame
    local goalCFrame = (startCFrame - startCFrame.p + desiredPosition) + Vector3.new(0, rootPart.Size.Y * 1.5, 0)
    
    self.CommE:FireServer("Soru", startCFrame, goalCFrame, workspace:GetServerTimeNow(), math.random(1e9))
    
    getgenv().SoruCooldownData.LastUse = currentTime
    rootPart.CFrame = goalCFrame
    
    self.Core.Services.ReplicatedStorage.Events.PlaySkillCooldownAnimation:Fire("BoundActionSoru", "none", cooldown)
    
    -- Эффекты
    self.SoruEffect:play({ CFrame = startCFrame, Character = character, Mode = 1, player = self.Core.LocalPlayer })
    self.SoruEffect:play({ CFrame = goalCFrame, Character = character, Mode = 2, player = self.Core.LocalPlayer })
    self.UtilService.Anims:Get(character, "FlashStepRegular"):Play(0, nil, math.clamp((rootPart.Velocity * Vector3.new(1, 0, 1)).magnitude / 16, 1.1, 3.3))
end

return Soru
