# About
 This NES cartridge clears the consoles RAM to match the FCEUX/Bizhawk emulators default RAM pattern.

 The main use for this is console verifying TASes for NES games with uninitialized RAM.

 This was showcased in the TASBlock GDQx 2023, where this cartridge was used.

# Compiling the ROM
 Simply drag the RAMClear.asm file over nesasm.exe, or run "nesasm.exe RAMClear.asm" in a command prompt.

# Using this ROM for console verification

 Burn the ROM onto a cartridge. As a brief warning, I've had inconsistent results with the Everdrive N8 Pro clearing the stack.

 Place the cartridge in the console and turn the power on. This will set the console's RAM to match the emulator powerup state.

 While leaving the power on, remove the cartridge.

 Place the cartridge you wish to console verify a TAS of in the console.

 At this point, pressing the console's reset button will start the game with the cleared RAM pattern.

![RAMClear](https://github.com/100thCoin/NESRamClear/assets/23084831/d581e267-018e-46cc-ab40-b26dd1213219)
