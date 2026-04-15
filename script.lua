-- UI LIB
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("FastClick Black UI", "Synapse")

-- TABS
local MainTab = Window:NewTab("Main")
local SettingsTab = Window:NewTab("Settings")

-- SECTIONS
local Main = MainTab:NewSection("System")
local Controls = SettingsTab:NewSection("Keybinds")

-- STATE
local enabled = false
local keybind = Enum.KeyCode.F

-- TOGGLE FUNCTION
local function toggle()
    enabled = not enabled
    print("State:", enabled)
end

-- KEY LISTENER
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == keybind then
        toggle()
    end
end)

-- UI TOGGLE
Main:NewToggle("Enabled", "Toggle state ON/OFF", function(v)
    enabled = v
end)

-- CHANGE KEYBIND
Controls:NewTextBox("Set Key (F, G, H...)", "Change toggle key", function(txt)
    local key = string.upper(txt)
    local success, enumKey = pcall(function()
        return Enum.KeyCode[key]
    end)

    if success and enumKey then
        keybind = enumKey
        print("Keybind set to:", key)
    else
        warn("Invalid key")
    end
end)

-- UI TOGGLE KEY
Controls:NewKeybind("Toggle UI", "Show/Hide UI", Enum.KeyCode.Insert, function()
    Library:ToggleUI()
end)
-- SETTINGS SECTION --
UI:NewKeybind("Toggle UI", "Sets the keybind to toggle UI", Enum.KeyCode.Insert, function()
    Library:ToggleUI()
end)
