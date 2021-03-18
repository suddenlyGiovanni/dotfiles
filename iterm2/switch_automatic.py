#!/usr/bin/env python3.7

import asyncio
import iterm2
# This script was created with the "basic" environment which does not support adding dependencies
# with pip.


async def changeTheme(connection,parts):
    theme_dark = "Night Owl"
    theme_light = "BlulocoLight"
    print(parts)

    if "dark" in parts:
        preset = await iterm2.ColorPreset.async_get(connection, theme_dark)
    else:
        preset = await iterm2.ColorPreset.async_get(connection, theme_light)

    # Update the list of all profiles and iterate over them.
    profiles=await iterm2.PartialProfile.async_query(connection)
    for partial in profiles:
        # Fetch the full profile and then set the color preset in it.
        profile = await partial.async_get_full_profile()
        await profile.async_set_color_preset(preset)


async def main(connection):
    # This is an example of using an asyncio context manager to register a custom control
    # sequence. You can send a custom control sequence by issuing this command in a
    # terminal session in iTerm2 while this script is running:
    #
    # printf "\033]1337;Custom=id=%s:%s\a" "shared-secret" "create-window"

    app = await iterm2.async_get_app(connection)
    window = app.current_window
    initial_theme = await app.async_get_theme()
    await changeTheme(connection,initial_theme)

    async with iterm2.VariableMonitor(connection, iterm2.VariableScopes.APP, "effectiveTheme", None) as mon:
        while True:
            # Block until theme changes
            theme = await mon.async_get()
            # Themes have space-delimited attributes, one of which will be light or dark.
            parts = theme.split(" ")

            await changeTheme(connection,parts)

# This instructs the script to run the "main" coroutine and to keep running even after it returns.
iterm2.run_forever(main)
