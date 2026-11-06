KamilsemmHUD = {
  cinematic = false
}

function IsVisible()
  return not IsPauseMenuActive() and not KamilsemmHUD.cinematic
end

KamilsemmHUD.IsVisible = IsVisible

function SetCinematicMode(enabled)
  KamilsemmHUD.cinematic = true == enabled
  SendNUIMessage({
    action = "cinematicBars",
    state = KamilsemmHUD.cinematic
  })
end

RegisterNetEvent("hud:client:ToggleCinematic", function(enabled)
  SetCinematicMode(enabled)
end)

RegisterCommand(Config.Commands.cinematic, function()
  TriggerEvent("hud:client:ToggleCinematic", not KamilsemmHUD.cinematic)
end, false)
