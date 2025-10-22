local GUI = {}
GUI.__index = GUI

function GUI:Initialize(core, utils)
    local self = setmetatable({}, GUI)
    self.Core = core
    self.Utils = utils
    self:LoadLibrary()
    self:CreateInterface()
    self:SetupEventHandlers()
    print("✅ GUI loaded")
    -- Keybinds: RightAlt toggles GUI, LeftAlt toggles aimbot
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightAlt then
            self.Window.Visible = not self.Window.Visible
        elseif i.KeyCode == Enum.KeyCode.LeftAlt then
            local v = not self.Library.Toggles.AimBotEnabled.Value
            self.Library.Toggles.AimBotEnabled:SetValue(v)
        end
    end)
    return self
end

function GUI:LoadLibrary()
    local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
    self.Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
    self.ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
    self.SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
    self.Window = self.Library:CreateWindow({
        Title = 'Blox Fruits Aimbot Hub',
        Center = true,
        AutoShow = true,
        TabPadding = 12,
        MenuFadeTime = 0.24
    })
    self.MainTab = self.Window:AddTab('⚡ Main')
    -- === MODERN THEME: red+black ===
    local theme = self.Library.Theme
    theme.AccentColor     = Color3.fromRGB(232, 58, 78)
    theme.MainColor       = Color3.fromRGB(22, 22, 28)
    theme.OutlineColor    = Color3.fromRGB(48, 0, 0)
    theme.FontColor       = Color3.fromRGB(250, 175, 195)
    theme.BackgroundColor = Color3.fromRGB(19, 18, 24)
    theme.TabBackground   = Color3.fromRGB(25, 0, 0)
    theme.DropdownBackground = Color3.fromRGB(40, 16, 19)
    theme.SectionBackground = Color3.fromRGB(35, 10, 14)
    self.ThemeManager.Theme = theme
end

function GUI:CreateInterface()
    local AimGroup = self.MainTab:AddLeftGroupbox('🎯 AIMBOT', {Spacing = 10, TitleCenter = true})
    AimGroup:AddToggle('AimBotEnabled', {
        Text = 'Enable Aimbot',
        Default = self.Core.Config.AimBot.Enabled,
        Tooltip = 'Press [LeftAlt] to toggle aimbot!',
        Keybind = Enum.KeyCode.LeftAlt
    })
    AimGroup:AddDropdown('AimBotMethod', {
        Values = {'Ray', 'FireServer'},
        Default = self.Core.Config.AimBot.Method,
        Multi = false,
        Text = 'Method',
        Tooltip = 'Select which aim method to use'
    })
    AimGroup:AddToggle('ShowFOV', {Text = 'Show FOV Circle', Default = self.Core.Config.AimBot.ShowFOV})
    AimGroup:AddToggle('CheckNPC', {Text = 'Target NPCs', Default = self.Core.Config.AimBot.CheckNPC})
    AimGroup:AddToggle('Gun', {Text = 'Gun Aimbot', Default = self.Core.Config.AimBot.Gun})
    AimGroup:AddSlider('FOVRadius', {Text = 'FOV Size', Default = self.Core.Config.AimBot.FOVRadius, Min = 50, Max = 700})

    local SoruGroup = self.MainTab:AddLeftGroupbox('✨ SORU')
    SoruGroup:AddToggle('SoruEnabled', {Text = 'Enhance Soru', Default = self.Core.Config.Soru.Enabled})

    local ESPGroup = self.MainTab:AddLeftGroupbox('👓 ESP Visuals')
    ESPGroup:AddToggle('ESPEnabled', {Text = 'Enable ESP', Default = self.Core.Config.ESP.Enabled})
    ESPGroup:AddToggle('ShowBoxes', {Text = 'Show Boxes', Default = self.Core.Config.ESP.ShowBoxes})
    ESPGroup:AddToggle('ShowNames', {Text = 'Show Names', Default = self.Core.Config.ESP.ShowName})
    ESPGroup:AddToggle('ShowHealth', {Text = 'Show Health', Default = self.Core.Config.ESP.ShowHealth})
    ESPGroup:AddToggle('ShowDistance', {Text = 'Show Distance', Default = self.Core.Config.ESP.ShowDistance})

    local ServerGroup = self.MainTab:AddRightGroupbox('🌐 SERVER TOOLS')
    ServerGroup:AddButton({Text = 'Copy Job ID', Func = function()
        if setclipboard then setclipboard(game.JobId) self.Library:Notify('Copied!', 2)
        else self.Library:Notify('Clipboard unsupported', 2) end
    end})
    ServerGroup:AddInput('JobIdInput', {Default='', Text='Job ID', Placeholder='Paste Job ID...'})
    ServerGroup:AddButton({Text='Join Job ID', Func = function()
        local jobId = self.Library.Options.JobIdInput.Value
        if jobId and jobId~='' then
            pcall(function()
                self.Core.Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, self.Core.LocalPlayer)
            end)
        end
    end})
    ServerGroup:AddButton({Text='Rejoin', Func=function()
        pcall(function()
            self.Core.Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, self.Core.LocalPlayer)
        end)
    end})

    local Settings = self.MainTab:AddRightGroupbox('⚙️ SETTINGS')
    Settings:AddToggle('AimAtCursor', {Text='Aim At Cursor', Default=self.Core.Config.AimBot.AimAtCursor})
    Settings:AddToggle('PredictionEnabled', {Text='Prediction', Default=self.Core.Config.AimBot.Prediction.Enabled})
    Settings:AddSlider('PredictionStrength', {Text='Prediction Strength', Default=self.Core.Config.AimBot.Prediction.Strength, Min=0, Max=0.5, Rounding=3})
    Settings:AddSlider('MaxDistance', {Text='Max Distance', Default=self.Core.Config.AimBot.Filtering.MaxDistance, Min=500, Max=10000, Suffix=' studs'})
    Settings:AddButton({
        Text = 'Destroy GUI',
        Func = function() self.Library:Unload() end,
        Tooltip = 'Remove GUI completely'
    })
end

function GUI:SetupEventHandlers()
    local Lib, Core = self.Library, self.Core
    Lib.Toggles.AimBotEnabled:OnChanged(function() Core.Config.AimBot.Enabled = Lib.Toggles.AimBotEnabled.Value end)
    Lib.Options.AimBotMethod:OnChanged(function() Core.Config.AimBot.Method = Lib.Options.AimBotMethod.Value end)
    Lib.Toggles.ShowFOV:OnChanged(function() Core.Config.AimBot.ShowFOV = Lib.Toggles.ShowFOV.Value end)
    Lib.Toggles.CheckNPC:OnChanged(function() Core.Config.AimBot.CheckNPC = Lib.Toggles.CheckNPC.Value end)
    Lib.Toggles.Gun:OnChanged(function() Core.Config.AimBot.Gun = Lib.Toggles.Gun.Value end)
    Lib.Toggles.SoruEnabled:OnChanged(function() Core.Config.Soru.Enabled = Lib.Toggles.SoruEnabled.Value end)
    Lib.Toggles.ESPEnabled:OnChanged(function() Core.Config.ESP.Enabled = Lib.Toggles.ESPEnabled.Value end)
    Lib.Toggles.ShowBoxes:OnChanged(function() Core.Config.ESP.ShowBoxes = Lib.Toggles.ShowBoxes.Value end)
    Lib.Toggles.ShowNames:OnChanged(function() Core.Config.ESP.ShowName = Lib.Toggles.ShowNames.Value end)
    Lib.Toggles.ShowHealth:OnChanged(function() Core.Config.ESP.ShowHealth = Lib.Toggles.ShowHealth.Value end)
    Lib.Toggles.ShowDistance:OnChanged(function() Core.Config.ESP.ShowDistance = Lib.Toggles.ShowDistance.Value end)
    Lib.Toggles.AimAtCursor:OnChanged(function() Core.Config.AimBot.AimAtCursor = Lib.Toggles.AimAtCursor.Value end)
    Lib.Toggles.PredictionEnabled:OnChanged(function() Core.Config.AimBot.Prediction.Enabled = Lib.Toggles.PredictionEnabled.Value end)
    Lib.Options.PredictionStrength:OnChanged(function() Core.Config.AimBot.Prediction.Strength = Lib.Options.PredictionStrength.Value end)
    Lib.Options.MaxDistance:OnChanged(function() Core.Config.AimBot.Filtering.MaxDistance = Lib.Options.MaxDistance.Value end)
    Lib.Options.FOVRadius:OnChanged(function() Core.Config.AimBot.FOVRadius = Lib.Options.FOVRadius.Value end)
end

function GUI:GetToggleValue(name) return self.Library.Toggles[name] and self.Library.Toggles[name].Value or false end
function GUI:GetOptionValue(name) return self.Library.Options[name] and self.Library.Options[name].Value or nil end

return GUI
