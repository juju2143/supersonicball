function love.conf(t)
    t.title = "Supersonic Ball" -- The title of the window the game is in (string)
    t.author = "juju2143"       -- The author of the game (string)
    t.url = "http://julosoft.net/supersonicball/" -- The website of the game (string)
    t.identity = nil            -- The name of the save directory (string)
    t.console = false           -- Attach a console (boolean, Windows only)
    t.version = "0.9.0"
    t.release = false           -- Enable release mode (boolean)

    t.window.width = 640        -- The window width (number)
    t.window.height = 480       -- The window height (number)
    t.window.fullscreen = false -- Enable fullscreen (boolean)
    t.window.vsync = true       -- Enable vertical sync (boolean)
    t.window.fsaa = 0           -- The number of FSAA-buffers (number)
    t.window.borderless = false        -- Remove all border visuals from the window (boolean)
    t.window.resizable = true         -- Let the window be user-resizable (boolean)
    t.window.minwidth = 1              -- Minimum window width if the window is resizable (number)
    t.window.minheight = 1             -- Minimum window height if the window is resizable (number)
    t.window.fullscreentype = "desktop" -- Standard fullscreen or desktop fullscreen mode (string)
    t.window.display = 1               -- Index of the monitor to show the window in (number)

    t.modules.joystick = true   -- Enable the joystick module (boolean)
    t.modules.audio = true      -- Enable the audio module (boolean)
    t.modules.keyboard = true   -- Enable the keyboard module (boolean)
    t.modules.event = true      -- Enable the event module (boolean)
    t.modules.image = true      -- Enable the image module (boolean)
    t.modules.graphics = true   -- Enable the graphics module (boolean)
    t.modules.timer = true      -- Enable the timer module (boolean)
    t.modules.mouse = false     -- Enable the mouse module (boolean)
    t.modules.sound = true      -- Enable the sound module (boolean)
    t.modules.physics = true    -- Enable the physics module (boolean)
end
