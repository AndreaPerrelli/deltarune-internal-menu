# DELTARUNE Internal Mod Menu 1.2.0 — menu-only release

Windows installer for the internal F1 menu, with adapters for chapters 1–5. Only installed chapters are patched. This archive contains mod source and installation scripts, not game archives, translations, music, sprites or UndertaleModTool binaries.

## Requirements

Your own Windows DELTARUNE installation; Windows PowerShell 5.1; free space for an original backup and a newly compiled archive per chapter. Download and extract **UTMT_CLI_v0.9.2.0-Windows.zip** from the official UndertaleModTool release:
https://github.com/UnderminersTeam/UndertaleModTool/releases/tag/0.9.2.0
Keep all files from that tool ZIP together. Select UndertaleModCli.exe, not the graphical UndertaleModTool executable.

## Installation

1. Close DELTARUNE. Extract this entire mod ZIP to a writable folder.
2. If an older internal menu is already installed, restore its original backup first. Keep your preferred translation installed.
3. Run Install.cmd. Enter the game root containing DELTARUNE.exe, then the full path to UndertaleModCli.exe (without surrounding quotation marks).
4. Wait for the completion message, launch the game normally and press F1.

This is a script installer, not a replacement data.win or a Vortex drag-and-drop package. The game folder must be writable by your account. Do not interrupt archive replacement. Install your translation before the menu; translation installers that replace data.win will otherwise remove the menu.

The installer reads YOUR archive, decompiles only the code needed for its hooks, adds the menu and generates catalogs from YOUR assets. It verifies that the existing string table remains unchanged after saving and reloading the result. External language files and saves are not edited by installation. The menu interface is English; the game's existing language remains in place. Different translations or future game versions can alter code hooks and be incompatible: a missing required hook stops preparation before installation. This is not a claim of compatibility with every translation or game build.

## Controls and features

F1 opens/closes; arrows navigate and adjust; Enter selects; Esc returns; Page Up/Down moves through lists; S searches catalogs. Numeric editors accept typed values.

- TP lock/edit, god mode, one-hit kills, graze multiplier, game speed, encounter controls.
- Item/weapon/armor/key-item spawning, money editor, infinite consumables, party controls.
- Noclip, room warp, flag editor.
- Jukebox, sprite/tint changes, text speed, simulated strange/error events.

Catalogs contain assets present in each chapter, not content imported from other chapters. Noelle is unavailable in chapter 1. Warps, story flags, unusual parties and boss replays are experimental and may require normal story initialization. Back up saves before using these gameplay features: subsequent in-game saving can retain inventory/story changes. Fake corruption screens are visual effects; they do not corrupt save files. Toggles reset with the game session.

## Uninstallation and updates

Close the game, run Uninstall.cmd and enter the same game root. It restores each exact pre-installation archive from chapterN_windows/.internal-menu-release after checking hashes. Keep that directory: it holds your backups, installation state and build reports. Uninstallation does not undo changes you saved through gameplay.

If another mod or a game update changed data.win, restoration refuses to overwrite it. Do not force an old backup over a newer game version. Restore/reinstall the appropriate game/translation version before applying this menu again. Re-running the same installer on its unchanged installed output skips it safely. Build failures leave diagnostic logs in .internal-menu-release; those logs/backups are for local troubleshooting and are not part of the upload.

Optional PowerShell usage (run from the extracted mod directory):

    .\Install.ps1 -GameFolder 'D:\Games\DELTARUNE' -ToolPath 'D:\Tools\UTMT\UndertaleModCli.exe' -Chapters 1,2,3,4,5
    .\Uninstall.ps1 -GameFolder 'D:\Games\DELTARUNE'

## Validation scope

Installation, output reload, source-text preservation and exact restoration are checked against the five local chapter builds used to prepare this release. Arbitrary English releases, other translations and future updates have not all been playtested. The installer rejects unsupported required hooks rather than substituting code from the author's translated game.

Unofficial fan modification; not affiliated with DELTARUNE's creators. UndertaleModTool is a separate third-party dependency, distributed by its own authors under its own license.
