-- ================================================================
--                      БАЗОВЫЙ МОДУЛЬ (Core.lua)
-- ================================================================

local Core = {}
Core.__index = Core

function Core:Initialize()
    local self = setmetatable({}, Core)
    
    -- === СЕРВИСЫ ===
    self.Services = {
        Players = game:GetService("Players"),
        Camera = workspace.CurrentCamera,
        UserInput = game:GetService("UserInputService"),
        RunService = game:GetService("RunService"),
        TeleportService = game:GetService("TeleportService"),
        ContextAction = game:GetService("ContextActionService"),
        CollectionService = game:GetService("CollectionService"),
        ReplicatedStorage = game:GetService("ReplicatedStorage")
    }
    
    self.LocalPlayer = self.Services.Players.LocalPlayer
    
    -- Скрываем курсор
    self.Services.UserInput.MouseIconEnabled = false
    
    -- === КОНФИГУРАЦИЯ (из оригинального скрипта) ===
    self.Config = {
        AimBot = {
            MinRayLength = 500,
            TargetPart = "HumanoidRootPart",
            FOVRadius = 400,
            Enabled = true,
            ShowFOV = true,
            CheckNPC = false,
            Method = "Ray",
            Prediction = {
                Enabled = true,
                Strength = 0.214
            },
            Filtering = {
                Enabled = true,
                MaxDistance = 3000
            },
            AimAtCursor = true,
            Gun = true
        },
        Soru = {
            Enabled = true
        },
        ESP = {
            Enabled = true,
            ShowName = true,
            ShowDistance = true,
            ShowHealth = true,
            ShowBoxes = true,
            TextOutline = true,
            MaxDistance = 2500,
            TextSize = 16
        }
    }
    
    -- === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
    getgenv().AimBot = self.Config.AimBot
    getgenv().MousePosition = Vector2.new(0, 0)
    getgenv().FilteredTargets = {}
    getgenv().Dodging = false
    getgenv().mobileSoru = false
    getgenv().SoruCooldownData = { LastAfter = 0, LastUse = 0 }
    
    print("✅ Core инициализирован")
    return self
end

function Core:StartMainLoops()
    -- Основной цикл обновления позиции мыши и целей
    task.spawn(function()
        while task.wait() do
            pcall(function()
                -- Обновляем позицию мыши
                if self.Config.AimBot.AimAtCursor then
                    getgenv().MousePosition = self.Services.UserInput:GetMouseLocation()
                else
                    getgenv().MousePosition = Vector2.new(
                        self.Services.Camera.ViewportSize.X / 2, 
                        self.Services.Camera.ViewportSize.Y / 2
                    )
                end
                
                -- Обновляем список отфильтрованных целей
                self:UpdateFilteredTargets()
            end)
        end
    end)
end

function Core:UpdateFilteredTargets()
    local newFilteredTargets = {}
    local myRoot = self.LocalPlayer.Character and self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if myRoot and self.Config.AimBot.Filtering.Enabled then
        local potentialTargets = {}
        
        -- Добавляем игроков
        for _, player in ipairs(self.Services.Players:GetPlayers()) do
            if player ~= self.LocalPlayer and player.Character then
                table.insert(potentialTargets, player.Character)
            end
        end
        
        -- Добавляем NPC если включено
        if self.Config.AimBot.CheckNPC then
            local EnemiesFolder = workspace:FindFirstChild("Enemies")
            if EnemiesFolder then
                for _, npc in ipairs(EnemiesFolder:GetChildren()) do
                    if npc:IsA("Model") then
                        table.insert(potentialTargets, npc)
                    end
                end
            end
        end
        
        -- Фильтруем по дистанции
        for _, character in ipairs(potentialTargets) do
            local targetPart = character:FindFirstChild(self.Config.AimBot.TargetPart)
            if targetPart then
                local distance = (myRoot.Position - targetPart.Position).magnitude
                if distance <= self.Config.AimBot.Filtering.MaxDistance then
                    table.insert(newFilteredTargets, character)
                end
            end
        end
    end
    
    getgenv().FilteredTargets = newFilteredTargets
end

return Core
