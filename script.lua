local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("FastClick Rework", "DarkTheme")

local Player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local AutoTab = Window:NewTab("AutoClicker")
local BindsTab = Window:NewTab("Binds")
local UiTab = Window:NewTab("UI")
local SecurityTab = Window:NewTab("Security")

local MainSection = AutoTab:NewSection("Controle")
local AdvancedSection = AutoTab:NewSection("Options")
local BindSection = BindsTab:NewSection("Raccourci autoclicker")
local UiSection = UiTab:NewSection("Interface")
local SecuritySection = SecurityTab:NewSection("Verrouillage")

local autoClicking = false
local clickDelay = 0.08
local holdToClick = false
local isHoldingBind = false

local bindConfig = {
    inputType = Enum.UserInputType.Keyboard,
    keyCode = Enum.KeyCode.F,
    mouseButton = Enum.UserInputType.MouseButton1,
}

local waitingForBind = false
local currentStatusLabel = "Etat: OFF | Bind: F"
local pendingKeyInput = ""
local isUnlocked = false

-- Key obfusquee (jamais en clair dans le script)
local keySeed = 73
local obfuscatedKeyBytes = {
    27, 99, 44, 8, 13, 80, 59, 184, 169, 249, 206, 175, 137, 231,
    221, 218, 161, 171, 129, 187, 176, 154, 181, 195, 200, 205, 48,
}

local function verifySecretKey(input)
    if type(input) ~= "string" or #input ~= #obfuscatedKeyBytes then
        return false
    end

    for i = 1, #obfuscatedKeyBytes do
        local charCode = string.byte(input, i)
        local salt = (keySeed + ((i * 7) % 251)) % 256
        if bit32.bxor(charCode, salt) ~= obfuscatedKeyBytes[i] then
            return false
        end
    end

    return true
end

local function requireUnlock()
    if not isUnlocked then
        warn("Script verrouille. Va dans l'onglet Security et valide ta key.")
        return false
    end
    return true
end

local function inputToName()
    if bindConfig.inputType == Enum.UserInputType.Keyboard then
        return bindConfig.keyCode.Name
    end
    if bindConfig.mouseButton == Enum.UserInputType.MouseButton1 then
        return "MouseButton1"
    elseif bindConfig.mouseButton == Enum.UserInputType.MouseButton2 then
        return "MouseButton2"
    elseif bindConfig.mouseButton == Enum.UserInputType.MouseButton3 then
        return "MouseButton3"
    end
    return "Unknown"
end

local function updateStatus()
    currentStatusLabel = string.format("Etat: %s | Bind: %s", autoClicking and "ON" or "OFF", inputToName())
    print(currentStatusLabel)
end

local function isBindInput(inputObject)
    if bindConfig.inputType == Enum.UserInputType.Keyboard then
        return inputObject.KeyCode == bindConfig.keyCode
    end
    return inputObject.UserInputType == bindConfig.mouseButton
end

MainSection:NewLabel("GUI refait avec binds clavier + souris")
MainSection:NewLabel("Statut en temps reel dans la console")

MainSection:NewToggle("Activer AutoClicker", "Active ou desactive le click auto", function(state)
    if not requireUnlock() then
        autoClicking = false
        updateStatus()
        return
    end
    autoClicking = state
    updateStatus()
end)

AdvancedSection:NewToggle("Mode Hold", "ON = click seulement tant que la touche bind est maintenue", function(state)
    if not requireUnlock() then
        return
    end
    holdToClick = state
    isHoldingBind = false
    if state then
        autoClicking = false
    end
    updateStatus()
end)

AdvancedSection:NewTextBox("Delay entre clics (sec)", "Ex: 0.05, 0.1, 0.2", function(value)
    if not requireUnlock() then
        return
    end
    local parsed = tonumber(value)
    if parsed and parsed > 0 then
        clickDelay = parsed
        print("Nouveau delay: " .. tostring(clickDelay) .. "s")
    else
        warn("Valeur invalide. Entrez un nombre > 0")
    end
end)

BindSection:NewButton("Definir bind (clavier ou souris)", "Clique puis appuie sur une touche clavier ou souris", function()
    if not requireUnlock() then
        return
    end
    if waitingForBind then
        return
    end

    waitingForBind = true
    print("En attente du nouveau bind... (clavier ou souris)")
end)

BindSection:NewButton("Reset bind par defaut (F)", "Remet F en bind", function()
    if not requireUnlock() then
        return
    end
    bindConfig.inputType = Enum.UserInputType.Keyboard
    bindConfig.keyCode = Enum.KeyCode.F
    bindConfig.mouseButton = Enum.UserInputType.MouseButton1
    updateStatus()
end)

BindSection:NewLabel("Bind actuel: configurable (clavier/souris)")
BindSection:NewLabel("Le bouton ci-dessus ecoute le prochain input")

UiSection:NewKeybind("Afficher/Cacher GUI", "Bind pour toggle l'interface", Enum.KeyCode.Insert, function()
    Library:ToggleUI()
end)

UiSection:NewButton("Copier statut dans la console", "Affiche le statut actuel", function()
    print(currentStatusLabel)
end)

SecuritySection:NewLabel("Le script est bloque tant que la key n'est pas validee")
SecuritySection:NewTextBox("Entrer ta key", "Colle ta key secrete ici", function(value)
    pendingKeyInput = tostring(value or "")
end)

SecuritySection:NewButton("Valider la key", "Debloque les fonctions du script", function()
    if verifySecretKey(pendingKeyInput) then
        isUnlocked = true
        print("Key validee. Script debloque.")
    else
        isUnlocked = false
        autoClicking = false
        warn("Key invalide.")
    end
    updateStatus()
end)

SecuritySection:NewButton("Relock", "Reverrouille le script", function()
    isUnlocked = false
    autoClicking = false
    print("Script reverrouille.")
    updateStatus()
end)

UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
    if gameProcessed then
        return
    end

    if waitingForBind then
        if inputObject.UserInputType == Enum.UserInputType.Keyboard and inputObject.KeyCode ~= Enum.KeyCode.Unknown then
            bindConfig.inputType = Enum.UserInputType.Keyboard
            bindConfig.keyCode = inputObject.KeyCode
            waitingForBind = false
            print("Bind clavier defini sur: " .. inputToName())
            updateStatus()
            return
        end

        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.MouseButton2
            or inputObject.UserInputType == Enum.UserInputType.MouseButton3 then
            bindConfig.inputType = inputObject.UserInputType
            bindConfig.mouseButton = inputObject.UserInputType
            waitingForBind = false
            print("Bind souris defini sur: " .. inputToName())
            updateStatus()
            return
        end
    end

    if isBindInput(inputObject) and isUnlocked then
        if holdToClick then
            isHoldingBind = true
            autoClicking = true
        else
            autoClicking = not autoClicking
        end
        updateStatus()
    end
end)

UserInputService.InputEnded:Connect(function(inputObject)
    if holdToClick and isBindInput(inputObject) and isUnlocked then
        isHoldingBind = false
        autoClicking = false
        updateStatus()
    end
end)

task.spawn(function()
    while true do
        if autoClicking and isUnlocked then
            local mousePosition = UserInputService:GetMouseLocation()
            VirtualInputManager:SendMouseButtonEvent(mousePosition.X, mousePosition.Y, 0, true, game, 0)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(mousePosition.X, mousePosition.Y, 0, false, game, 0)
            task.wait(clickDelay)
        else
            task.wait(0.05)
        end
    end
end)

print("FastClick Rework charge pour " .. Player.Name)
print("Etat securite: LOCKED (valide ta key dans l'onglet Security)")
updateStatus()