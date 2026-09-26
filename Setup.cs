// Setup.exe - bootstrapper for the DELTARUNE Internal Menu release.
// Downloads UndertaleModTool CLI 0.9.2.0 (if needed, with SHA-256 check)
// and then runs Install.ps1 from the same folder.
// Compile with Build-Setup.ps1 (uses the .NET Framework csc.exe, no extra tools).
// Kept compatible with the C# 5 compiler: no string interpolation, no ?. operator.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Security.Cryptography;
using System.Text;

internal static class Setup
{
    private const string CliVersion = "0.9.2.0";
    private const string CliZipName = "UTMT_CLI_v0.9.2.0-Windows.zip";
    private const string CliDownloadUrl =
        "https://github.com/UnderminersTeam/UndertaleModTool/releases/download/0.9.2.0/" + CliZipName;
    // Official SHA-256 of the upstream asset (from the GitHub release API).
    private const string CliZipSha256 =
        "e7573e45d107be34f81f955c6e4afc3c7c8f2628e5a6f307a871e3825b3dfb40";
    private const long CliZipSize = 62585935L;

    private static int Main(string[] args)
    {
        // GitHub requires TLS 1.2; enable it explicitly for older defaults.
        try { ServicePointManager.SecurityProtocol |= (SecurityProtocolType)3072; }
        catch { }

        string gameFolder = null;
        string toolPath = null;
        string chaptersArg = null;
        bool noPause = false;

        for (int i = 0; i < args.Length; i++)
        {
            string a = args[i];
            if (a == "--help" || a == "-h" || a == "/?")
            {
                PrintHelp();
                return 0;
            }
            else if (a == "--no-pause")
            {
                noPause = true;
            }
            else if ((a == "--game" || a == "-g") && i + 1 < args.Length)
            {
                gameFolder = args[++i];
            }
            else if ((a == "--tool" || a == "-t") && i + 1 < args.Length)
            {
                toolPath = args[++i];
            }
            else if (a.StartsWith("--game="))
            {
                gameFolder = a.Substring("--game=".Length);
            }
            else if (a.StartsWith("--tool="))
            {
                toolPath = a.Substring("--tool=".Length);
            }
            else if (a.StartsWith("--chapters="))
            {
                chaptersArg = a.Substring("--chapters=".Length);
            }
            else if ((a == "--chapters" || a == "-c") && i + 1 < args.Length)
            {
                chaptersArg = args[++i];
            }
            else
            {
                Console.Error.WriteLine("Unknown argument: " + a);
                PrintHelp();
                Pause(noPause);
                return 1;
            }
        }

        try
        {
            string baseDir = Path.GetDirectoryName(
                System.Reflection.Assembly.GetExecutingAssembly().Location);

            string installScript = Path.Combine(baseDir, "Install.ps1");
            if (!File.Exists(installScript))
            {
                throw new Exception(
                    "Install.ps1 not found next to Setup.exe. " +
                    "Extract the full release ZIP so all files stay together.");
            }

            // Validate cheap inputs first so a typo never triggers a ~60 MB download.
            string chapters = NormalizeChapters(chaptersArg);
            string game = ResolveGameFolder(gameFolder);
            string cli = ResolveCli(baseDir, toolPath);

            RunInstaller(installScript, game, cli, chapters);

            Console.WriteLine();
            Console.WriteLine("Done. Start the game normally and press F1.");
            Pause(noPause);
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine();
            Console.Error.WriteLine("Setup failed: " + ex.Message);
            Pause(noPause);
            return 1;
        }
    }

    private static void PrintHelp()
    {
        Console.WriteLine("DELTARUNE Internal Menu - Setup");
        Console.WriteLine("Downloads UndertaleModTool CLI 0.9.2.0 if needed, then runs Install.ps1.");
        Console.WriteLine();
        Console.WriteLine("Usage:");
        Console.WriteLine("  Setup.exe [--game <folder>] [--tool <UndertaleModCli.exe>] [--chapters 1,2,3,4,5] [--no-pause]");
        Console.WriteLine();
        Console.WriteLine("If --game is omitted you will be asked for the DELTARUNE folder.");
        Console.WriteLine("If --tool is omitted, tools\\UTMT\\UndertaleModCli.exe next to Setup.exe is used");
        Console.WriteLine("(downloaded automatically on first run, ~60 MB).");
    }

    private static void Pause(bool noPause)
    {
        if (noPause)
        {
            return;
        }
        Console.WriteLine("Press ENTER to close...");
        Console.ReadLine();
    }

    private static string ResolveCli(string baseDir, string toolPath)
    {
        if (!string.IsNullOrEmpty(toolPath))
        {
            string full = Path.GetFullPath(toolPath.Trim().Trim('"'));
            ValidateCli(full);
            Console.WriteLine("Using tool: " + full);
            return full;
        }

        string dir = Path.Combine(baseDir, "tools", "UTMT");
        string cli = Path.Combine(dir, "UndertaleModCli.exe");
        if (File.Exists(cli))
        {
            try
            {
                ValidateCli(cli);
                Console.WriteLine("Using tool: " + cli);
                return cli;
            }
            catch (Exception ex)
            {
                Console.WriteLine("Existing tool is unusable (" + ex.Message + "); re-downloading.");
            }
        }

        Console.WriteLine("UndertaleModTool CLI " + CliVersion + " not found; downloading (~60 MB)...");
        Directory.CreateDirectory(dir);
        string zipPath = Path.Combine(
            Path.GetTempPath(), "deltarune-internal-menu-" + CliZipName);
        try
        {
            DownloadFile(CliDownloadUrl, zipPath);
            VerifyFile(zipPath);
            Console.WriteLine("Extracting to " + dir + " ...");
            // Fresh directory: remove leftovers from a previous failed attempt.
            foreach (string f in Directory.GetFiles(dir))
            {
                File.Delete(f);
            }
            ZipFile.ExtractToDirectory(zipPath, dir);
        }
        finally
        {
            try { if (File.Exists(zipPath)) File.Delete(zipPath); }
            catch { }
        }

        if (!File.Exists(cli))
        {
            throw new Exception("Downloaded archive did not contain UndertaleModCli.exe.");
        }
        ValidateCli(cli);
        Console.WriteLine("Using tool: " + cli);
        return cli;
    }

    private static void DownloadFile(string url, string destination)
    {
        using (WebClient client = new WebClient())
        {
            client.Headers.Add("User-Agent", "deltarune-internal-menu-setup");
            client.DownloadProgressChanged += delegate(object s, DownloadProgressChangedEventArgs e)
            {
                Console.Write("\rDownloading " + CliZipName + ": " + e.ProgressPercentage + "%");
            };
            client.DownloadFile(new Uri(url), destination);
        }
        Console.WriteLine();
    }

    private static void VerifyFile(string zipPath)
    {
        FileInfo info = new FileInfo(zipPath);
        if (info.Length != CliZipSize)
        {
            throw new Exception(
                "Downloaded file has unexpected size (" + info.Length +
                " bytes, expected " + CliZipSize + "). Retry with a stable connection.");
        }
        using (SHA256 sha = SHA256.Create())
        {
            using (FileStream stream = File.OpenRead(zipPath))
            {
                byte[] hash = sha.ComputeHash(stream);
                StringBuilder sb = new StringBuilder(hash.Length * 2);
                foreach (byte b in hash)
                {
                    sb.Append(b.ToString("x2"));
                }
                if (!string.Equals(sb.ToString(), CliZipSha256, StringComparison.OrdinalIgnoreCase))
                {
                    throw new Exception(
                        "Downloaded file failed the SHA-256 integrity check. " +
                        "Delete any partial download and retry.");
                }
            }
        }
        Console.WriteLine("Download verified (SHA-256 OK).");
    }

    private static void ValidateCli(string cli)
    {
        if (!File.Exists(cli))
        {
            throw new Exception("Tool not found: " + cli);
        }
        if (!string.Equals(Path.GetFileName(cli), "UndertaleModCli.exe", StringComparison.OrdinalIgnoreCase))
        {
            throw new Exception("Select UndertaleModCli.exe from the official Windows CLI release.");
        }
        ProcessStartInfo psi = new ProcessStartInfo();
        psi.FileName = cli;
        psi.Arguments = "--version";
        psi.UseShellExecute = false;
        psi.RedirectStandardOutput = true;
        psi.RedirectStandardError = true;
        psi.CreateNoWindow = true;
        string output;
        using (Process p = Process.Start(psi))
        {
            output = p.StandardOutput.ReadToEnd().Trim();
            p.WaitForExit(30000);
            if (p.ExitCode != 0)
            {
                throw new Exception("Could not run UndertaleModCli.exe --version.");
            }
        }
        if (!(output == CliVersion || output.StartsWith(CliVersion + "+")))
        {
            throw new Exception(
                "This release requires UndertaleModTool CLI " + CliVersion +
                " (found: " + output + ").");
        }
    }

    private static string ResolveGameFolder(string gameFolder)
    {
        string game = gameFolder;
        if (string.IsNullOrEmpty(game))
        {
            Console.Write("DELTARUNE folder (the one containing DELTARUNE.exe): ");
            game = Console.ReadLine();
        }
        if (string.IsNullOrEmpty(game))
        {
            throw new Exception("No game folder provided.");
        }
        game = Path.GetFullPath(game.Trim().Trim('"'));
        if (!File.Exists(Path.Combine(game, "DELTARUNE.exe")))
        {
            throw new Exception("Select the game root containing DELTARUNE.exe: " + game);
        }
        if (Process.GetProcessesByName("DELTARUNE").Length > 0)
        {
            throw new Exception("Close DELTARUNE before installing.");
        }
        return game;
    }

    private static string NormalizeChapters(string chaptersArg)
    {
        if (string.IsNullOrEmpty(chaptersArg))
        {
            return null;
        }
        List<int> seen = new List<int>();
        string[] parts = chaptersArg.Split(new char[] { ',', ';', ' ' }, StringSplitOptions.RemoveEmptyEntries);
        foreach (string part in parts)
        {
            int c;
            if (!int.TryParse(part.Trim(), out c) || c < 1 || c > 5)
            {
                throw new Exception("Chapters must be numbers between 1 and 5 (got: " + part + ").");
            }
            if (!seen.Contains(c))
            {
                seen.Add(c);
            }
        }
        if (seen.Count == 0)
        {
            return null;
        }
        seen.Sort();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < seen.Count; i++)
        {
            if (i > 0)
            {
                sb.Append(',');
            }
            sb.Append(seen[i]);
        }
        return sb.ToString();
    }

    private static void RunInstaller(string installScript, string game, string cli, string chapters)
    {
        StringBuilder args = new StringBuilder();
        args.Append("-NoProfile -ExecutionPolicy Bypass -File \"");
        args.Append(installScript);
        args.Append("\" -GameFolder \"");
        args.Append(game);
        args.Append("\" -ToolPath \"");
        args.Append(cli);
        args.Append("\"");
        if (!string.IsNullOrEmpty(chapters))
        {
            args.Append(" -Chapters ");
            args.Append(chapters);
        }

        Console.WriteLine("Starting installer...");
        ProcessStartInfo psi = new ProcessStartInfo();
        psi.FileName = "powershell.exe";
        psi.Arguments = args.ToString();
        psi.UseShellExecute = false;
        using (Process p = Process.Start(psi))
        {
            p.WaitForExit();
            if (p.ExitCode != 0)
            {
                throw new Exception("Install.ps1 exited with code " + p.ExitCode + ". See the error above.");
            }
        }
    }
}
