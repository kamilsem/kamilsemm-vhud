local seatbeltOn = false
local wasInVehicle = false
local seatbeltResource = KamilsemmFramework.GetSeatbeltResource()
local vehicleHudVisible = false
local lastVehicleHudData = nil

function IsVehicleLocked(vehicle)
  if GetVehicleDoorLockStatus(vehicle) > 1 then
    return true
  end

  return GetVehicleDoorsLockedForPlayer(vehicle, PlayerId())
end

function HasVehicleHudDataChanged(data)
  if not lastVehicleHudData then
    lastVehicleHudData = data
    return true
  end

  for key, value in pairs(data) do
    if lastVehicleHudData[key] ~= value then
      lastVehicleHudData = data
      return true
    end
  end

  return false
end

function SetSeatbeltState(enabled)
  seatbeltOn = true == enabled
  LocalPlayer.state:set("seatbelt", seatbeltOn, true)
end

function SyncSeatbeltFromResource()
  local stateSeatbelt = LocalPlayer.state.seatbelt
  if stateSeatbelt ~= nil then
    seatbeltOn = true == stateSeatbelt
  end

  if not seatbeltResource then
    return
  end

  if GetResourceState(seatbeltResource) ~= "started" then
    return
  end

  local seatbeltOk, hasSeatbelt = pcall(function()
    return exports[seatbeltResource]:HasSeatbeltOn()
  end)

  local harnessOk, hasHarness = pcall(function()
    return exports[seatbeltResource]:HasHarness()
  end)

  SetSeatbeltState((seatbeltOk and true == hasSeatbelt) or (harnessOk and true == hasHarness))
end

function FormatGear(speed, gear)
  if speed == 0 and gear == 0 then
    return "N"
  elseif gear == 0 then
    return "R"
  end

  return gear
end

RegisterNetEvent("seatbelt:client:ToggleSeatbelt", function()
  SyncSeatbeltFromResource()
end)

AddEventHandler("onClientResourceStart", function(resourceName)
  if resourceName ~= GetCurrentResourceName() and resourceName ~= seatbeltResource then
    return
  end

  CreateThread(function()
    Wait(250)
    SyncSeatbeltFromResource()
  end)
end)

AddEventHandler("onClientResourceStop", function(resourceName)
  if seatbeltResource and resourceName == seatbeltResource then
    SetSeatbeltState(false)
  end
end)

CreateThread(function()
  while true do
    local waitTime = Config.Intervals.vehicleIdle
    local ped = PlayerPedId()
    local inVehicle = IsPedInAnyVehicle(ped, false)

    if inVehicle then
      if KamilsemmHUD.IsVisible() then
        waitTime = Config.Intervals.vehicle

        if not wasInVehicle then
          SyncSeatbeltFromResource()
        end

        wasInVehicle = true
        local vehicle = GetVehiclePedIsIn(ped, false)

        local stateSeatbelt = LocalPlayer.state.seatbelt
        if stateSeatbelt ~= nil then
          seatbeltOn = true == stateSeatbelt
        end

        local speed = math.floor(GetEntitySpeed(vehicle) * Config.SpeedMultiplier)
        local gear = FormatGear(speed, GetVehicleCurrentGear(vehicle))
        local _, lightsOn, highbeamsOn = GetVehicleLightsState(vehicle)

        local hudData = {
          action = "updateVehicleHud",
          speed = speed,
          speedUnit = Config.SpeedUnit,
          maxSpeed = Config.MaxSpeed or 240,
          gear = gear,
          fuel = math.floor(GetVehicleFuelLevel(vehicle) * 10.0 + 0.5) / 10.0,
          lights = lightsOn == 1 or highbeamsOn == 1,
          seatbelt = seatbeltOn,
          locked = IsVehicleLocked(vehicle),
          engine = math.floor(GetVehicleEngineHealth(vehicle) + 0.5)
        }

        if not vehicleHudVisible or HasVehicleHudDataChanged(hudData) then
          vehicleHudVisible = true
          SendNUIMessage(hudData)
        end
      end
    else
      if wasInVehicle then
        wasInVehicle = false
        SetSeatbeltState(false)
      end

      if vehicleHudVisible then
        vehicleHudVisible = false
        lastVehicleHudData = nil
        SendNUIMessage({
          action = "hideVehicleHud"
        })
      end
    end

    Wait(waitTime)
  end
end)
