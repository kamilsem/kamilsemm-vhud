local frameworkAliases = {
  qb = "qbcore",
  ["qb-core"] = "qbcore",
  qbcore = "qbcore",
  esx = "esx",
  es_extended = "esx",
  qbox = "qbox",
  qbx = "qbox",
  qbx_core = "qbox"
}

local configuredFramework = string.lower(tostring(Config.Framework or "qbcore"))
local frameworkName = frameworkAliases[configuredFramework] or configuredFramework

local playerNeeds = {
  hunger = 100,
  thirst = 100
}

local qbCoreObject = nil

KamilsemmFramework = {
  Name = frameworkName,
  Resource = Config.FrameworkResources[frameworkName]
}

function NormalizeNeed(value)
  value = tonumber(value)
  if not value then
    return nil
  end

  if value > 100 then
    value = value / 10000
  end

  return math.max(0, math.min(100, value))
end

function SetNeeds(hunger, thirst)
  hunger = NormalizeNeed(hunger)
  thirst = NormalizeNeed(thirst)

  if hunger then
    playerNeeds.hunger = hunger
  end

  if thirst then
    playerNeeds.thirst = thirst
  end
end

function ApplyNeedsFromMetadata(metadata)
  if type(metadata) ~= "table" then
    return
  end

  SetNeeds(metadata.hunger, metadata.thirst)
end

function GetNeeds()
  return playerNeeds.hunger, playerNeeds.thirst
end

KamilsemmFramework.GetNeeds = GetNeeds

function GetSeatbeltResource()
  local seatbeltResources = Config.SeatbeltResources or {}
  return seatbeltResources[frameworkName]
end

KamilsemmFramework.GetSeatbeltResource = GetSeatbeltResource

RegisterNetEvent("hud:client:UpdateNeeds", function(hunger, thirst)
  SetNeeds(hunger, thirst)
end)

RegisterNetEvent("Kamilsemm-vhud:client:setNeeds", function(hunger, thirst)
  SetNeeds(hunger, thirst)
end)

function RefreshQBCoreNeeds()
  local resourceName = KamilsemmFramework.Resource
  if not resourceName or GetResourceState(resourceName) ~= "started" then
    return
  end

  if not qbCoreObject then
    local ok, coreObject = pcall(function()
      return exports[resourceName]:GetCoreObject({ "Functions" })
    end)

    if ok then
      qbCoreObject = coreObject
    end
  end

  if qbCoreObject and qbCoreObject.Functions then
    local playerData = qbCoreObject.Functions.GetPlayerData()
    local metadata = playerData and playerData.metadata
    ApplyNeedsFromMetadata(metadata)
  end
end

function RequestQboxNeeds()
  TriggerServerEvent("Kamilsemm-vhud:server:requestNeeds")
end

function GetStatusPercent(status)
  if type(status) ~= "table" then
    return nil
  end

  if status.percent ~= nil then
    return status.percent
  end

  if type(status.getPercent) == "function" then
    local ok, percent = pcall(status.getPercent)
    if ok then
      return percent
    end
  end

  return status.val or status.value
end

function RefreshESXNeeds()
  if GetResourceState("esx_status") ~= "started" then
    return
  end

  TriggerEvent("esx_status:getStatus", "hunger", function(status)
    SetNeeds(GetStatusPercent(status), nil)
  end)

  TriggerEvent("esx_status:getStatus", "thirst", function(status)
    SetNeeds(nil, GetStatusPercent(status))
  end)
end

if frameworkName == "qbcore" then
  RegisterNetEvent("QBCore:Client:OnPlayerLoaded", RefreshQBCoreNeeds)

  RegisterNetEvent("QBCore:Player:SetPlayerData", function(playerData)
    local metadata = playerData and playerData.metadata
    ApplyNeedsFromMetadata(metadata)
  end)
elseif frameworkName == "qbox" then
  AddEventHandler("QBCore:Client:OnPlayerLoaded", RequestQboxNeeds)

  RegisterNetEvent("qbx_core:client:onSetMetaData", function(key, _oldValue, newValue)
    if key == "hunger" then
      SetNeeds(newValue, nil)
    elseif key == "thirst" then
      SetNeeds(nil, newValue)
    end
  end)

  RegisterNetEvent("qbx_core:client:playerLoggedOut", function()
    SetNeeds(100, 100)
  end)
elseif frameworkName == "esx" then
  RegisterNetEvent("esx_status:onTick", function(statuses)
    local hunger
    local thirst

    for _, status in pairs(statuses or {}) do
      if status.name == "hunger" then
        hunger = GetStatusPercent(status)
      elseif status.name == "thirst" then
        thirst = GetStatusPercent(status)
      end
    end

    SetNeeds(hunger, thirst)
  end)
end

CreateThread(function()
  Wait(1000)

  while true do
    if frameworkName == "qbcore" then
      RefreshQBCoreNeeds()
    elseif frameworkName == "qbox" then
      RequestQboxNeeds()
    elseif frameworkName == "esx" then
      RefreshESXNeeds()
    end

    Wait(Config.NeedsRefreshInterval or 5000)
  end
end)
