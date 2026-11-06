local frameworkAliases = {
  qbox = "qbox",
  qbx = "qbox",
  qbx_core = "qbox"
}

local configuredFramework = string.lower(tostring(Config.Framework or "qbcore"))
local resolvedFramework = frameworkAliases[configuredFramework]

if resolvedFramework ~= "qbox" then
  return
end

local qboxResource = Config.FrameworkResources.qbox or "qbx_core"

RegisterNetEvent("Kamilsemm-vhud:server:requestNeeds", function()
  local playerSource = source

  if GetResourceState(qboxResource) ~= "started" then
    return
  end

  local hungerOk, hunger = pcall(function()
    return exports[qboxResource]:GetMetadata(playerSource, "hunger")
  end)

  local thirstOk, thirst = pcall(function()
    return exports[qboxResource]:GetMetadata(playerSource, "thirst")
  end)

  local hungerValue = hunger
  if not hungerOk or not hunger then
    hungerValue = 100
  end

  local thirstValue = thirst
  if not thirstOk or not thirst then
    thirstValue = 100
  end

  TriggerClientEvent("Kamilsemm-vhud:client:setNeeds", playerSource, hungerValue, thirstValue)
end)
