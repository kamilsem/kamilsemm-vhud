Config = {}

-- Supported values: 'qbcore', 'esx', 'qbox'
Config.Framework = 'qbcore'

Config.FrameworkResources = {
    qbcore = 'qb-core',
    esx = 'es_extended',
    qbox = 'qbx_core'
}

-- Seatbelt is optional outside QBCore. Statebag-based seatbelt scripts work
-- automatically; set a resource name here only when it exposes
-- HasSeatbeltOn()/HasHarness() like qb-smallresources.
Config.SeatbeltResources = {
    qbcore = 'qb-smallresources',
    esx = false,
    qbox = false
}

Config.NeedsRefreshInterval = 5000

-- Commands registered by Kamilsemm-vhud.
Config.Commands = {
    cinematic = 'cinematic'
}

-- Client update intervals in milliseconds.
-- These values are read directly by the runtime loops. Lower values update more
-- frequently but use more client CPU time. The defaults below are tuned to keep
-- the HUD responsive without sending unnecessary NUI messages.
Config.Intervals = {
    player = 200,          -- Health, armour, needs, voice, stamina and weapon data.
    vehicle = 50,          -- Vehicle data while the player is inside a vehicle.
    vehicleIdle = 250,     -- Vehicle presence check while outside a vehicle.
    compassHeading = 25,   -- Camera heading target; NUI interpolation keeps it smooth.
    compassDetails = 250,  -- Street, zone and custom waypoint distance/direction.
    minimap = 1000         -- Resolution, safezone and minimap position checks.
}

-- Vehicle speed display. The default multiplier converts GTA metres/second to MPH.
-- Use 3.6 and 'KM/H' if you want metric speed instead.
Config.SpeedMultiplier = 2.236936
Config.SpeedUnit = 'MPH'
Config.MaxSpeed = 160 -- Speed at which the outer speed arc reaches 100%.

-- Warn players when their GTA safezone is too small for the HUD layout.
Config.ShowSafezoneWarning = true
Config.RequiredSafezone = 0.99

-- Display the custom aiming crosshair handled by the player HUD.
Config.UseCustomCrosshair = true
