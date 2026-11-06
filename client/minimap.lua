function ApplyMinimapPositions()
  local screenWidth, screenHeight = GetActiveScreenResolution()
  if screenWidth == 0 or screenHeight == 0 then
    return
  end

  local aspectRatio = screenWidth / screenHeight
  local safeZone = GetSafeZoneSize()
  local offsetX = screenWidth * ((1.0 - safeZone) / 2.0)
  local offsetY = screenHeight * ((1.0 - safeZone) / 2.0)

  local minimapX = 0.829
  local minimapY = 0.102
  local minimapWidth = 0.138
  local minimapHeight = 0.75 * minimapWidth * aspectRatio

  local posX = (minimapX * screenWidth - offsetX) / (screenWidth * safeZone)
  local posY = (minimapY * screenHeight - offsetY) / (screenHeight * safeZone)
  local width = minimapWidth / safeZone
  local height = minimapHeight / safeZone

  SetMinimapComponentPosition("minimap", "L", "T", posX, posY, width, height)
  SetMinimapComponentPosition("minimap_mask", "L", "T", posX, posY, width, height)
  SetMinimapComponentPosition("minimap_blur", "L", "T", posX, posY, width, height)
end

function RefreshBigmap()
  SetRadarBigmapEnabled(true, false)
  Wait(50)
  SetRadarBigmapEnabled(false, false)
end

function GetWaypointDirection(relativeAngle)
  if math.abs(relativeAngle) <= 30 then
    return "straight"
  elseif relativeAngle > 30 and relativeAngle <= 150 then
    return "right"
  elseif relativeAngle < -30 and relativeAngle >= -150 then
    return "left"
  end

  return "back"
end

CreateThread(function()
  Wait(1500)

  RequestStreamedTextureDict("circlemap", false)
  while not HasStreamedTextureDictLoaded("circlemap") do
    Wait(10)
  end

  SetMinimapClipType(1)
  AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")
  AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "circlemap", "radarmasklg")
  AddReplaceTexture("platform:/textures/graphics", "radarmasklg", "circlemap", "radarmasklg")

  ApplyMinimapPositions()

  local minimapScaleform = RequestScaleformMovie("minimap")
  while not HasScaleformMovieLoaded(minimapScaleform) do
    Wait(10)
  end

  RefreshBigmap()
  SetBlipAlpha(GetNorthRadarBlip(), 0)
  DisplayRadar(true)

  local lastWidth = 0
  local lastHeight = 0
  local lastSafeZone = 0
  local warningVisible = false

  while true do
    Wait(Config.Intervals.minimap)

    local screenWidth, screenHeight = GetActiveScreenResolution()
    local safeZone = GetSafeZoneSize()

    local shouldWarn = false
    if Config.ShowSafezoneWarning then
      shouldWarn = safeZone < Config.RequiredSafezone
    end

    if shouldWarn ~= warningVisible then
      warningVisible = shouldWarn
      SendNUIMessage({
        action = warningVisible and "showSafezoneWarning" or "hideSafezoneWarning"
      })
    end

    if screenWidth ~= lastWidth or screenHeight ~= lastHeight or safeZone ~= lastSafeZone then
      lastWidth = screenWidth
      lastHeight = screenHeight
      lastSafeZone = safeZone
      ApplyMinimapPositions()
      RefreshBigmap()
    end
  end
end)

CreateThread(function()
  local minimapScaleform = RequestScaleformMovie("minimap")
  while not HasScaleformMovieLoaded(minimapScaleform) do
    Wait(0)
  end

  local lastVisible = nil

  while true do
    Wait(0)

    HideHudComponentThisFrame(1)
    HideHudComponentThisFrame(2)
    HideHudComponentThisFrame(3)
    HideHudComponentThisFrame(4)
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    HideHudComponentThisFrame(21)
    HideHudComponentThisFrame(22)

    local isVisible = KamilsemmHUD.IsVisible()
    if isVisible ~= lastVisible then
      lastVisible = isVisible
      DisplayRadar(isVisible)
    end

    if isVisible then
      BeginScaleformMovieMethod(minimapScaleform, "SETUP_HEALTH_ARMOUR")
      ScaleformMovieMethodAddParamInt(3)
      EndScaleformMovieMethod()

      local waypointBlip = GetFirstBlipInfoId(8)
      if DoesBlipExist(waypointBlip) then
        BeginScaleformMovieMethod(minimapScaleform, "SET_SATNAV_DIRECTION")
        ScaleformMovieMethodAddParamInt(0)
        EndScaleformMovieMethod()

        BeginScaleformMovieMethod(minimapScaleform, "HIDE_SATNAV")
        EndScaleformMovieMethod()
      end
    end
  end
end)

CreateThread(function()
  local lastDetailsUpdate = 0
  local lastHeading = nil
  local lastStreet = nil
  local lastZone = nil
  local lastDistanceText = nil
  local lastDirection = nil
  local waypointVisible = false
  local compassWasVisible = false

  while true do
    local isVisible = KamilsemmHUD.IsVisible()

    if isVisible then
      compassWasVisible = true

      local heading = 360.0 - GetGameplayCamRot(2).z
      if heading < 0.0 then
        heading = heading + 360.0
      end
      if heading >= 360.0 then
        heading = heading - 360.0
      end

      local headingDelta
      if lastHeading then
        headingDelta = math.abs(((heading - lastHeading) + 540.0) % 360.0 - 180.0)
      else
        headingDelta = 360.0
      end

      if headingDelta >= 0.05 then
        lastHeading = heading
        SendNUIMessage({
          action = "updateCompassHeading",
          heading = heading
        })
      end

      local now = GetGameTimer()
      if now - lastDetailsUpdate >= Config.Intervals.compassDetails then
        lastDetailsUpdate = now

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = string.upper(GetStreetNameFromHashKey(streetHash) or "")

        local zoneName = GetNameOfZone(coords.x, coords.y, coords.z)
        local zone = GetLabelText(zoneName)
        if not zone or zone == "" or zone == "NULL" then
          zone = zoneName
        end
        zone = string.upper(zone)

        if street ~= lastStreet or zone ~= lastZone then
          lastStreet = street
          lastZone = zone
          SendNUIMessage({
            action = "updateCompassDetails",
            street = street,
            zone = zone
          })
        end

        local waypointBlip = GetFirstBlipInfoId(8)
        if DoesBlipExist(waypointBlip) then
          local waypointCoords = GetBlipInfoIdCoord(waypointBlip)
          local deltaX = waypointCoords.x - coords.x
          local deltaY = waypointCoords.y - coords.y
          local deltaZ = waypointCoords.z - coords.z
          local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)

          local bearing = math.deg(math.atan2(deltaX, deltaY))
          if bearing < 0 then
            bearing = bearing + 360
          end

          local relativeAngle = bearing - heading
          if relativeAngle > 180 then
            relativeAngle = relativeAngle - 360
          end
          if relativeAngle < -180 then
            relativeAngle = relativeAngle + 360
          end

          local direction = GetWaypointDirection(relativeAngle)
          local distanceText = string.format("%.2f mi", distance * 6.21371E-4)

          if not waypointVisible or distanceText ~= lastDistanceText or direction ~= lastDirection then
            waypointVisible = true
            lastDistanceText = distanceText
            lastDirection = direction
            SendNUIMessage({
              action = "updateWaypoint",
              distance = distanceText,
              direction = direction
            })
          end
        elseif waypointVisible then
          waypointVisible = false
          lastDistanceText = nil
          lastDirection = nil
          SendNUIMessage({
            action = "hideWaypoint"
          })
        end
      end
    elseif compassWasVisible then
      compassWasVisible = false
      lastHeading = nil
      lastStreet = nil
      lastZone = nil
      SendNUIMessage({
        action = "hideCompass"
      })

      if waypointVisible then
        waypointVisible = false
        lastDistanceText = nil
        lastDirection = nil
        SendNUIMessage({
          action = "hideWaypoint"
        })
      end
    end

    local waitTime
    if isVisible then
      waitTime = Config.Intervals.compassHeading or Config.Intervals.compassDetails
    else
      waitTime = Config.Intervals.compassDetails
    end

    Wait(waitTime)
  end
end)

AddEventHandler("onClientResourceStop", function(resourceName)
  if resourceName ~= GetCurrentResourceName() then
    return
  end

  RemoveReplaceTexture("platform:/textures/graphics", "radarmasksm")
  RemoveReplaceTexture("platform:/textures/graphics", "radarmask1g")
  RemoveReplaceTexture("platform:/textures/graphics", "radarmasklg")
  SetMinimapClipType(0)
  DisplayRadar(true)
end)
