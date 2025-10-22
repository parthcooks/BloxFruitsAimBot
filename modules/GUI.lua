-- ================================================================
--                           GUI MODULE
-- ================================================================
local GUI = {}
GUI.__index = GUI

function GUI:Initialize(core, utils)
    local self = setmetatable({}, GUI)
    self.Core = core
    self.Utils = utils
    self:LoadLibrary()
    self:CreateInterface()
    self:SetupEventHandlers()
    print("✅ GUI инициализирован")
    -- Hotkeys for GUI show/hide and aimbot toggle
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightAlt then
            self.Window.Visible = not self.Window.Visible
        elseif input.KeyCode == Enum.KeyCode.LeftAlt then
            local v = not self.Library.Toggles.AimBotEnabled.Value
            self.Library.Toggles.AimBotEnabled:SetValue(v)
        end
    end)
    return self
end

function GUI:LoadLibrary()
    -- Load LinoriaLib and dependencies
    local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
    self.Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
    self.ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
    self.SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

    self.Window = self.Library:CreateWindow({
        Title = 'Blox Fruits AimBot Hub',
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2
    })
    self.ThemeManager:SetTheme('Discord')
    self.MainTab = self.Window:AddTab('Main')
end

function GUI:CreateInterface()
    -- === AIM GROUP ===
    local AimGroup = self.MainTab:AddLeftGroupbox('Aim Bot', {Spacing = 8})
    AimGroup:AddToggle('AimBotEnabled', {
        Text = 'Enable Aim Bot',
        Default = self.Core.Config.AimBot.Enabled,
        Tooltip = 'Toggle silent aim functionality',
        Keybind = Enum.KeyCode.LeftAlt
    })
    AimGroup:AddDropdown('AimBotMethod', {
        Values = {'Ray', 'FireServer'},
        Default = self.Core.Config.AimBot.Method,
        Multi = false,
        Text = 'Aim Bot Method',
        Tooltip = 'Select which aim bot method to use.'
    })
    AimGroup:AddToggle('ShowFOV', {
        Text = 'Show FOV Circle',
        Default = self.Core.Config.AimBot.ShowFOV,
        Tooltip = 'Display FOV circle on screen'
    })
    AimGroup:AddToggle('CheckNPC', {
        Text = 'Target NPCs',
        Default = self.Core.Config.AimBot.CheckNPC,
        Tooltip = 'Include NPCs as possible aimbot targets'
    })
    AimGroup:AddToggle('Gun', {
        Text = 'Gun Aimbot',
        Default = self.Core.Config.AimBot.Gun,
        Tooltip = 'Enable aimbot for guns'
    })
    AimGroup:AddSlider('FOVRadius', {
        Text = 'FOV Size',
        Default = self.Core.Config.AimBot.FOVRadius,
        Min = 50, Max = 700, Rounding = 0,
        Tooltip = 'Adjust FOV circle radius'
    })

    -- === SORU ENHANCEMENT ===
    local SoruGroup = self.MainTab:AddLeftGroupbox('Soru Enhancement')
    SoruGroup:AddToggle('SoruEnabled', {
        Text = 'Enhanced Soru',
        Default = self.Core.Config.Soru.Enabled,
        Tooltip = 'Enable aimbot-enhanced Soru teleportation'
    })

    -- === ESP GROUP ===
    local ESPGroup = self.MainTab:AddLeftGroupbox('ESP System', {Spacing = 8})
    ESPGroup:AddToggle('ESPEnabled', {
        Text = 'Enable ESP',
        Default = self.Core.Config.ESP.Enabled,
        Tooltip = 'Toggle ESP visuals'
    })
    ESPGroup:AddToggle('ShowBoxes', {
        Text = 'Show Boxes',
        Default = self.Core.Config.ESP.ShowBoxes,
        Tooltip = 'Show player and NPC hitboxes'
    })
    ESPGroup:AddToggle('ShowNames', {
        Text = 'Show Names',
        Default = self.Core.Config.ESP.ShowName,
        Tooltip = 'Show target names'
    })
    ESPGroup:AddToggle('ShowHealth', {
        Text = 'Show Health',
        Default = self.Core.Config.ESP.ShowHealth,
        Tooltip = 'Show health bars'
    })
    ESPGroup:AddToggle('ShowDistance', {
        Text = 'Show Distance',
        Default = self.Core.Config.ESP.ShowDistance,
        Tooltip = 'Show distance to targets'
    })

    -- === SERVER TOOLS ===
    local ServerGroup = self.MainTab:AddRightGroupbox('Server Tools')
    ServerGroup:AddButton({
        Text = 'Copy Job ID',
        Func = function()
            if setclipboard then
                setclipboard(game.JobId)
                self.Library:Notify('Job ID copied to clipboard!', 3)
            else
                self.Library:Notify('Clipboard not supported', 3)
            end
        end,
        Tooltip = 'Copy current server Job ID'
    })
    ServerGroup:AddInput('JobIdInput', {
        Default = '',
        Numeric = false,
        Text = 'Job ID',
        Tooltip = 'Paste or type Job ID to join a server',
        Placeholder = 'Paste Job ID here...'
    })
    ServerGroup:AddButton({
        Text = 'Join by Job ID',
        Func = function()
            local jobId = self.Library.Options.JobIdInput.Value
            if jobId and jobId ~= '' then
                pcall(function()
                    self.Core.Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, self.Core.LocalPlayer)
                end)
            end
        end,
        Tooltip = 'Join a server by Job ID'
    })
    ServerGroup:AddButton({
        Text = 'Rejoin Server',
        Func = function()
            pcall(function()
                self.Core.Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, self.Core.LocalPlayer)
            end)
        end,
        Tooltip = 'Rejoin current server'
    })

    -- === SETTINGS GROUP ===
    local SettingsGroup = self.MainTab:AddRightGroupbox('Settings')
    SettingsGroup:AddToggle('AimAtCursor', {
        Text = 'Aim At Cursor',
        Default = self.Core.Config.AimBot.AimAtCursor,
        Tooltip = 'Target closest to cursor instead of center'
    })
    SettingsGroup:AddToggle('PredictionEnabled', {
        Text = 'Prediction',
        Default = self.Core.Config.AimBot.Prediction.Enabled,
        Tooltip = 'Predict target movement'
    })
    SettingsGroup:AddSlider('PredictionStrength', {
        Text = 'Prediction Strength',
        Default = self.Core.Config.AimBot.Prediction.Strength,
        Min = 0, Max = 0.5, Rounding = 3,
        Tooltip = 'Increase to predict more'
    })
    SettingsGroup:AddSlider('MaxDistance', {
        Text = 'Max Distance',
        Default = self.Core.Config.AimBot.Filtering.MaxDistance,
        Min = 500, Max = 10000, Rounding = 0,
        Suffix = ' studs',
        Tooltip = 'Maximum aimbot targeting distance'
    })
    SettingsGroup:AddButton({
        Text = 'Destroy GUI',
        Func = function()
            self.Library:Unload()
        end,
        Tooltip = 'Closes the GUI completely'
    })
end

function GUI:SetupEventHandlers()
    -- AimBot event handlers
    self.Library.Toggles.AimBotEnabled:OnChanged(function()
        self.Core.Config.AimBot.Enabled = self.Library.Toggles.AimBotEnabled.Value
    end)
    self.Library.Options.AimBotMethod:OnChanged(function()
        self.Core.Config.AimBot.Method = self.Library.Options.AimBotMethod.Value
    end)
    self.Library.Toggles.ShowFOV:OnChanged(function()
        self.Core.Config.AimBot.ShowFOV = self.Library.Toggles.ShowFOV.Value
    end)
    self.Library.Toggles.CheckNPC:OnChanged(function()
        self.Core.Config.AimBot.CheckNPC = self.Library.Toggles.CheckNPC.Value
    end)
    self.Library.Toggles.Gun:OnChanged(function()
        self.Core.Config.AimBot.Gun = self.Library.Toggles.Gun.Value
    end)

    -- Soru event handlers
    self.Library.Toggles.SoruEnabled:OnChanged(function()
        self.Core.Config.Soru.Enabled = self.Library.Toggles.SoruEnabled.Value
    end)

    -- ESP event handlers
    self.Library.Toggles.ESPEnabled:OnChanged(function()
        self.Core.Config.ESP.Enabled = self.Library.Toggles.ESPEnabled.Value
    end)
    self.Library.Toggles.ShowBoxes:OnChanged(function()
        self.Core.Config.ESP.ShowBoxes = self.Library.Toggles.ShowBoxes.Value
    end)
    self.Library.Toggles.ShowNames:OnChanged(function()
        self.Core.Config.ESP.ShowName = self.Library.Toggles.ShowNames.Value
    end)
    self.Library.Toggles.ShowHealth:OnChanged(function()
        self.Core.Config.ESP.ShowHealth = self.Library.Toggles.ShowHealth.Value
    end)
    self.Library.Toggles.ShowDistance:OnChanged(function()
        self.Core.Config.ESP.ShowDistance = self.Library.Toggles.ShowDistance.Value
    end)
    -- Settings event handlers
    self.Library.Toggles.AimAtCursor:OnChanged(function()
        self.Core.Config.AimBot.AimAtCursor = self.Library.Toggles.AimAtCursor.Value
    end)
    self.Library.Toggles.PredictionEnabled:OnChanged(function()
        self.Core.Config.AimBot.Prediction.Enabled = self.Library.Toggles.PredictionEnabled.Value
    end)
    self.Library.Options.PredictionStrength:OnChanged(function()
        self.Core.Config.AimBot.Prediction.Strength = self.Library.Options.PredictionStrength.Value
    end)
    self.Library.Options.MaxDistance:OnChanged(function()
        self.Core.Config.AimBot.Filtering.MaxDistance = self.Library.Options.MaxDistance.Value
    end)
    self.Library.Options.FOVRadius:OnChanged(function()
        self.Core.Config.AimBot.FOVRadius = self.Library.Options.FOVRadius.Value
    end)
end

function GUI:GetToggleValue(name)
    return self.Library.Toggles[name] and self.Library.Toggles[name].Value or false
end

function GUI:GetOptionValue(name)
    return self.Library.Options[name] and self.Library.Options[name].Value or nil
end

return GUI
