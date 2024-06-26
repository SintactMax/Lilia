﻿function MODULE:PlayerButtonDown(client, button)
    if button == KEY_F2 and IsFirstTimePredicted() then
        local menu = DermaMenu()
        menu:AddOption("Change voice mode to Whispering range.", function()
            netstream.Start("ChangeSpeakMode", "Whispering")
            client:ChatNotify("You have changed your voice mode to Whispering!")
        end)

        menu:AddOption("Change voice mode to Talking range.", function()
            netstream.Start("ChangeSpeakMode", "Talking")
            client:ChatNotify("You have changed your voice mode to Talking!")
        end)

        menu:AddOption("Change voice mode to Yelling range.", function()
            netstream.Start("ChangeSpeakMode", "Yelling")
            client:ChatNotify("You have changed your voice mode to Yelling!")
        end)

        menu:Open()
        menu:MakePopup()
        menu:Center()
    end
end

function MODULE:LoadFonts(_)
    surface.CreateFont("3DVoiceDebug", {
        font = "Arial",
        size = 14,
        antialias = true,
        weight = 700,
        underline = true,
    })
end
