PICO8DATA - your PICO8-OS data drive
====================================
pico8os.txt    settings (keyboard layout, start mode, Wi-Fi, ...)
pico-8_*_raspi.zip   drop the PICO-8 Raspberry Pi zip here (or the unzipped
               "pico-8" folder) and boot: it is installed automatically.
carts/         your carts (.p8 / .p8.png) - PICO-8's root folder
pico8/         PICO-8 home: config.txt, saves (cdata), Splore downloads
screenshots/   screenshots and GIFs
logs/          pico8.log (crashes), kernel.log (under-voltage, SD errors...),
               bluetooth.log (pairing)

PICO-8 frozen? Ctrl+Alt+Backspace (keyboard) or hold SELECT+START for
3 seconds (gamepad) restarts it.

Bluetooth controller: put it in pairing mode within 60 s of power-on, or
press Ctrl+Alt+P on a keyboard. Custom button mappings: pico8/sdl_controllers.txt

This is the only partition you see on a PC. PICO8-OS also writes Bluetooth
pairings to a small hidden ext4 partition. The system itself is
read-only, so pulling the power cannot break it.
