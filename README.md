# DELTARUNE Internal Menu

In-game F1 sandbox menu for DELTARUNE (chapters 1–5), installed by patching **your own** game archives. Menu-only source distribution: no `data.win`, assets, translations or third-party binaries are included.

- Full instructions: [README_EN.md](README_EN.md) · [LEGGIMI_IT.md](LEGGIMI_IT.md)
- Changes: [CHANGELOG.md](CHANGELOG.md)
- Nexus page text: [NEXUS_DESCRIPTION.txt](NEXUS_DESCRIPTION.txt)
- File hashes: [SHA256SUMS.txt](SHA256SUMS.txt)

## Quick start

1. Close DELTARUNE. Extract this repo to a writable folder.
2. Download `UTMT_CLI_v0.9.2.0-Windows.zip` from the [official UndertaleModTool release](https://github.com/UnderminersTeam/UndertaleModTool/releases/tag/0.9.2.0) and extract it.
3. Run `Install.cmd`, enter the game root containing `DELTARUNE.exe` and the full path to `UndertaleModCli.exe`.
4. Launch the game and press **F1**.

PowerShell alternative (run from this directory):

```powershell
.\Install.ps1 -GameFolder 'D:\Games\DELTARUNE' -ToolPath 'D:\Tools\UTMT\UndertaleModCli.exe' -Chapters 1,2,3,4,5
```

To remove: run `Uninstall.cmd` / `.\Uninstall.ps1 -GameFolder '...'`. Keep each chapter's `.internal-menu-release/` folder (backups + install state).

## Layout

```text
Install.cmd / Install.ps1       # installer (wraps UndertaleModCli)
Uninstall.cmd / Uninstall.ps1   # exact restore from verified backups
payload/Patch.csx               # patch script run against your data.win
payload/Verify.csx              # output verification script
payload/menu-chN.gml            # chapter menu sources
payload/compat-chN.gml          # chapter adapters
```

Unofficial fan modification; not affiliated with DELTARUNE's creators. UndertaleModTool is a separate third-party dependency under its own license.

## License

MIT — see [LICENSE](LICENSE).
