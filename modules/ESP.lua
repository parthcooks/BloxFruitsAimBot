-- ================================================================
--                      МОДУЛЬ ESP (ESP.lua)
-- ================================================================

local ESP = {}
ESP.__index = ESP

function ESP:Initialize(core, gui)
    local self = setmetatable({}, ESP)
    self.Core = core
    self.GUI = gui
    self.PlayerDrawings = {}
    
    self:StartESP()
    print("✅ ESP инициализирован")
    return self
end

function ESP:StartESP()
    self.Core.Services.RunService.RenderStepped:Connect(function()
        if not self.GUI:GetToggleValue('ESPEnabled') then
            self:HideAllESP()
            return
        end
        
        self:UpdateESP()
    end)
end

function ESP:UpdateESP()
    local myChar = self.Core.LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    for _, player in ipairs(self.Core.Services.Players:GetPlayers()) do
        if player ~= self.Core.LocalPlayer then
            self:DrawPlayerESP(player, myRoot)
        end
    end
end

function ESP:DrawPlayerESP(player, myRoot)
    local char = player.Character
    local humanoid, root, head = char and char:FindFirstChildOfClass("Humanoid"), 
        char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChild("Head")
    
    if humanoid and root and head and humanoid.Health > 0 then
        local distance = (myRoot.Position - root.Position).magnitude
        if distance <= self.Core.Config.ESP.MaxDistance then
            local screenPos, onScreen = self.Core.Services.Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                if not self.PlayerDrawings[player] then
                    self.PlayerDrawings[player] = {
                        Box = Drawing.new("Quad"),
                        Name = Drawing.new("Text"),
                        Info = Drawing.new("Text")
                    }
                end
                
                self:UpdatePlayerDrawings(player, screenPos, distance, humanoid, head)
                return
            end
        end
    end
    
    -- Скрываем ESP если игрок не подходит под условия
    if self.PlayerDrawings[player] then
        for _, drawing in pairs(self.PlayerDrawings[player]) do
            drawing.Visible = false
        end
    end
end

function ESP:UpdatePlayerDrawings(player, screenPos, distance, humanoid, head)
    local d = self.PlayerDrawings[player]
    local color = Color3.new(1, 0, 0) -- Красный по умолчанию
    
    -- Box
    if self.GUI:GetToggleValue('ShowBoxes') then
        local headY = self.Core.Services.Camera:WorldToViewportPoint(head.Position).Y
        local boxHeight = math.abs(headY - screenPos.Y) + 10
        local boxWidth = boxHeight / 2
        local boxPos = Vector2.new(screenPos.X - boxWidth / 2, headY - 5)
        
        d.Box.PointA = boxPos
        d.Box.PointB = boxPos + Vector2.new(boxWidth, 0)
        d.Box.PointC = boxPos + Vector2.new(boxWidth, boxHeight)
        d.Box.PointD = boxPos + Vector2.new(0, boxHeight)
        d.Box.Color = color
        d.Box.Visible = true
    else
        d.Box.Visible = false
    end
    
    -- Name
    if self.GUI:GetToggleValue('ShowNames') then
        d.Name.Text = player.Name
        d.Name.Color = color
        d.Name.Size = 16
        d.Name.Center = true
        d.Name.Outline = true
        d.Name.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
        d.Name.Visible = true
    else
        d.Name.Visible = false
    end
    
    -- Info
    d.Info.Text = string.format("[%dm] [%d%%]", distance, (humanoid.Health / humanoid.MaxHealth) * 100)
    d.Info.Color = Color3.new(1, 1, 1)
    d.Info.Size = 14
    d.Info.Center = true
    d.Info.Outline = true
    d.Info.Position = Vector2.new(screenPos.X, screenPos.Y + 20)
    d.Info.Visible = true
end

function ESP:HideAllESP()
    for _, drawings in pairs(self.PlayerDrawings) do
        for _, drawing in pairs(drawings) do
            drawing.Visible = false
        end
    end
end

return ESP
