local isRadioActive = false
local unarmedHash = GetHashKey("WEAPON_UNARMED")
local playerHudVisible = false
local lastPlayerHudData = nil

function Clamp(value, minValue, maxValue)
  return math.max(minValue, math.min(maxValue, value))
end

function HasPlayerHudDataChanged(data)
  if not lastPlayerHudData then
    lastPlayerHudData = data
    return true
  end

  for key, value in pairs(data) do
    if lastPlayerHudData[key] ~= value then
      lastPlayerHudData = data
      return true
    end
  end

  return false
end

AddEventHandler("pma-voice:radioActive", function(active)
  isRadioActive = true == active
end)

CreateThread(function()
  while true do
    Wait(Config.Intervals.player)

    if KamilsemmHUD.IsVisible() then
      local playerId = PlayerId()
      local ped = PlayerPedId()
      local inVehicle = IsPedInAnyVehicle(ped, false)

      local stamina = 100
      local showStamina = false

      if not inVehicle then
        local sprintRemaining = Clamp(GetPlayerSprintStaminaRemaining(playerId), 0, 100)
        stamina = Clamp(math.floor(100.0 - sprintRemaining + 0.5), 0, 100)
        showStamina = IsPedRunning(ped) or IsPedSprinting(ped)
      end

      local maxHealth = GetEntityMaxHealth(ped) - 100
      local health = 0

      if maxHealth > 0 then
        health = math.floor((GetEntityHealth(ped) - 100) / maxHealth * 100)
      end

      health = Clamp(health, 0, 100)
      local armor = Clamp(GetPedArmour(ped), 0, 100)
      local hunger, thirst = KamilsemmFramework.GetNeeds()

      local isUnderwater = IsPedSwimmingUnderWater(ped)
      local oxygen = 100

      if isUnderwater then
        oxygen = Clamp(math.floor(GetPlayerUnderwaterTimeRemaining(playerId) * 10), 0, 100)
      end

      local voice = 2
      local proximity = LocalPlayer.state.proximity
      if proximity and proximity.index then
        voice = proximity.index
      end

      local weaponHash = GetSelectedPedWeapon(ped)
      local hasWeapon = weaponHash ~= unarmedHash and weaponHash ~= 0
      local ammoClip = 0
      local ammoTotal = 0

      if hasWeapon then
        local _, clipAmmo = GetAmmoInClip(ped, weaponHash)
        ammoClip = clipAmmo or 0
        ammoTotal = math.max(0, GetAmmoInPedWeapon(ped, weaponHash) - ammoClip)
      end

      local isAiming = false
      if Config.UseCustomCrosshair then
        isAiming = IsPlayerFreeAiming(playerId)
      end

      local hudData = {
        health = health,
        armor = armor,
        hunger = hunger,
        thirst = thirst,
        stamina = stamina,
        showStamina = showStamina,
        isUnderwater = isUnderwater,
        oxygen = oxygen,
        isTalking = NetworkIsPlayerTalking(playerId),
        isRadio = isRadioActive,
        voice = voice,
        isAiming = isAiming,
        hasWeapon = hasWeapon,
        ammoClip = ammoClip,
        ammoTotal = ammoTotal
      }

      if not playerHudVisible or HasPlayerHudDataChanged(hudData) then
        playerHudVisible = true
        SendNUIMessage({
          action = "updatePlayerHud",
          data = hudData
        })
      end
    else
      if playerHudVisible then
        playerHudVisible = false
        SendNUIMessage({
          action = "hidePlayerHud"
        })
      end
    end
  end
end)
