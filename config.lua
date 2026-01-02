Config = {}

-- Welcome popup
Config.Welcome = {
    -- Show only once ever per player (saved server-side via KVP)
    PersistOncePerPlayer = true,
    ShowEverySession = true,
    -- How far they must move before the popup triggers
    MoveThreshold = 1.5,

    Header = "Welcome to the Server",
    Content = [[
**Quick Start Guide**

- Use **/firstcar** to claim your first vehicle.
- **You only get 1 free car every 24 hours.**
- To save your vehicle's parking spot:
  **Press SHIFT + F** while parked.

If your car isn't where you left it, make sure you parked it properly.
Enjoy your stay!
]],
    Centered = true,
    Size = "md",
}

-- First car system
Config.FirstCar = {
    -- 24 hours
    CooldownSeconds = 24 * 60 * 60,

    -- Random sedan pool (~10)
    SedanModels = {
        "asea",
        "asterope",
        "emporer",
        "fugitive",
        "glendale",
        "ingot",
        "intruder",
        "premier",
        "primo",
        "regina",
    },

    -- Put the player into the driver seat after spawn
    WarpIntoVehicle = true,

    -- If true, also show the cooldown remaining nicely in chat
    ShowCooldownChatMessage = true,
}
