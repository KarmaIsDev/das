-- UI LIB
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("FastClick Framework", "Sentinel")

-- TABS
local MainTab = Window:NewTab("Main")
local SettingsTab = Window:NewTab("Settings")

-- SECTIONS
local ClickSection = MainTab:NewSection("System")
local ControlSection = SettingsTab:NewSection("Controls")

-- VARIABLES
local state = {
    enabled = false,
    speed = 0.1,
    key = Enum.KeyCode.F
}

-- KEY SYSTEM
local function bindKey(key, callback)
    game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == key then
            callback()
        end
    end)
end

-- TOGGLE SYSTEM
local function toggle()
    state.enabled = not state.enabled
    print("State:", state.enabled)
end

-- UI ELEMENTS
ClickSection:NewToggle("Enabled", "Toggle system state", function(v)
    state.enabled = v
    print("Enabled:", v)
end)

ClickSection:NewTextBox("Speed", "Set value", function(txt)
    local v = tonumber(txt)
    if v and v > 0 then
        state.speed = v
        print("Speed:", v)
    end
end)

-- KEYBIND TOGGLE SYSTEM
ControlSection:NewKeybind("Toggle System", "Bind to toggle state", state.key, function()
    toggle()
end)

-- CHANGE KEYBIND (simple version)
ControlSection:NewTextBox("Set Key (F, G, H...)", "Change toggle key", function(txt)
    local key = string.upper(txt)

    local success, enumKey = pcall(function()
        return Enum.KeyCode[key]
    end)

    if success and enumKey then
        state.key = enumKey
        print("Key changed to:", key)
    else
        warn("Invalid key")
    end
end)

-- UI TOGGLE
ControlSection:NewKeybind("Toggle UI", "Show/Hide", Enum.KeyCode.Insert, function()
    Library:ToggleUI()
end)

-- LOOP EXAMPLE (SAFE PLACEHOLDER SYSTEM)
task.spawn(function()
    while task.wait(0.2) do
        if state.enabled then
            -- place your legit logic here (cooldowns, UI updates, etc.)
        end
    end
end)
-- SETTINGS SECTION --
UI:NewKeybind("Toggle UI", "Sets the keybind to toggle UI", Enum.KeyCode.Insert, function()
    Library:ToggleUI()
end)
