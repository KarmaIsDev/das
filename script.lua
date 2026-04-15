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
local ClickSection = AutoTab:NewSection("Type de clic")
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
local securityEnabled = true
local clickBackendName = "Unknown"
local warnedNoClickBackend = false
local clickModes = {
    left = true,
    right = false,
    middle = false,
}

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
    if not securityEnabled then
        return true
    end

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
    local clickList = {}
    if clickModes.left then
        table.insert(clickList, "L")
    end
    if clickModes.right then
        table.insert(clickList, "R")
    end
    if clickModes.middle then
        table.insert(clickList, "M")
    end
    local clickText = #clickList > 0 and table.concat(clickList, "+") or "NONE"

    currentStatusLabel = string.format(
        "Etat: %s | Bind: %s | Clicks: %s | Security: %s | Backend: %s",
        autoClicking and "ON" or "OFF",
        inputToName(),
        clickText,
        isUnlocked and "UNLOCKED" or "LOCKED",
        clickBackendName
    )
    print(currentStatusLabel)
end

local function isBindInput(inputObject)
    if bindConfig.inputType == Enum.UserInputType.Keyboard then
        return inputObject.KeyCode == bindConfig.keyCode
    end
    return inputObject.UserInputType == bindConfig.mouseButton
end

local function normalizeKeyText(text)
    local s = tostring(text or "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("\r", ""):gsub("\n", "")
    return s
end

local function pressReleaseVirtual(buttonIndex)
    local mousePosition = UserInputService:GetMouseLocation()
    VirtualInputManager:SendMouseButtonEvent(mousePosition.X, mousePosition.Y, buttonIndex, true, game, 0)
    task.wait()
    VirtualInputManager:SendMouseButtonEvent(mousePosition.X, mousePosition.Y, buttonIndex, false, game, 0)
end

local function performSingleClick(buttonName)
    if buttonName == "left" then
        if type(mouse1click) == "function" then
            clickBackendName = "mouse1click"
            mouse1click()
            return true
        end
        if type(mouse1press) == "function" and type(mouse1release) == "function" then
            clickBackendName = "mouse1press/release"
            mouse1press()
            task.wait()
            mouse1release()
            return true
        end
        if VirtualInputManager then
            clickBackendName = "VirtualInputManager"
            pressReleaseVirtual(0)
            return true
        end
    elseif buttonName == "right" then
        if type(mouse2click) == "function" then
            clickBackendName = "mouse2click"
            mouse2click()
            return true
        end
        if type(mouse2press) == "function" and type(mouse2release) == "function" then
            clickBackendName = "mouse2press/release"
            mouse2press()
            task.wait()
            mouse2release()
            return true
        end
        if VirtualInputManager then
            clickBackendName = "VirtualInputManager"
            pressReleaseVirtual(1)
            return true
        end
    elseif buttonName == "middle" then
        if type(mouse3click) == "function" then
            clickBackendName = "mouse3click"
            mouse3click()
            return true
        end
        if VirtualInputManager then
            clickBackendName = "VirtualInputManager"
            pressReleaseVirtual(2)
            return true
        end
    end

    return false
end

local function performClickSet()
    local clickedAny = false
    if clickModes.left then
        clickedAny = performSingleClick("left") or clickedAny
    end
    if clickModes.right then
        clickedAny = performSingleClick("right") or clickedAny
    end
    if clickModes.middle then
        clickedAny = performSingleClick("middle") or clickedAny
    end
    return clickedAny
end

MainSection:NewLabel("GUI refait avec binds clavier + souris")
MainSection:NewLabel("Statut en temps reel dans la console")
MainSection:NewLabel("Important: unlock la key dans l'onglet Security")

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

ClickSection:NewLabel("Tu peux activer plusieurs clics en meme temps")
ClickSection:NewToggle("Clic gauche", "Active le clic gauche auto", function(state)
    if not requireUnlock() then
        return
    end
    clickModes.left = state
    updateStatus()
end)

ClickSection:NewToggle("Clic droit", "Active le clic droit auto", function(state)
    if not requireUnlock() then
        return
    end
    clickModes.right = state
    updateStatus()
end)

ClickSection:NewToggle("Clic milieu", "Active le clic milieu auto", function(state)
    if not requireUnlock() then
        return
    end
    clickModes.middle = state
    updateStatus()
end)

ClickSection:NewButton("Preset: Gauche + Droit", "Active clic gauche et droit en meme temps", function()
    if not requireUnlock() then
        return
    end
    clickModes.left = true
    clickModes.right = true
    clickModes.middle = false
    print("Preset applique: Left + Right")
    updateStatus()
end)

ClickSection:NewButton("Preset: Tous", "Active clic gauche, droit et milieu", function()
    if not requireUnlock() then
        return
    end
    clickModes.left = true
    clickModes.right = true
    clickModes.middle = true
    print("Preset applique: Left + Right + Middle")
    updateStatus()
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

BindSection:NewButton("Afficher bind actuel", "Affiche le bind actuel dans la console", function()
    print("Bind actuel: " .. inputToName())
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
SecuritySection:NewLabel("Tu peux desactiver la securite si besoin de debug")
SecuritySection:NewToggle("Activer securite", "ON = key obligatoire", function(state)
    securityEnabled = state
    if not securityEnabled then
        isUnlocked = true
        print("Securite desactivee: script debloque.")
    else
        isUnlocked = false
        autoClicking = false
        print("Securite activee: valide la key.")
    end
    updateStatus()
end)

SecuritySection:NewTextBox("Entrer ta key", "Colle ta key secrete ici", function(value)
    pendingKeyInput = normalizeKeyText(value)
end)

SecuritySection:NewButton("Valider la key", "Debloque les fonctions du script", function()
    local candidate = normalizeKeyText(pendingKeyInput)
    if verifySecretKey(candidate) then
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
            local didClick = performClickSet()
            if not didClick and not warnedNoClickBackend then
                warnedNoClickBackend = true
                warn("Aucun backend de clic disponible pour les boutons choisis.")
            end
            task.wait(clickDelay)
        else
            task.wait(0.05)
        end
    end
end)

print("FastClick Rework charge pour " .. Player.Name)
print("Etat securite: LOCKED (valide ta key dans l'onglet Security)")
updateStatus()
