# Cross-Platform Notes

Gale-Framework targets Unix-like developer environments. Linux is the simplest path, WSL2 is the preferred Windows path, and macOS generally works with a few package and path differences.

## Linux

Linux usually needs the least adaptation:

- paths live under `/home/<user>/...`;
- `tmux`, `git`, `bash`, and `node` are available from the system package manager or language toolchain installers;
- `/proc` is available for process inspection;
- `pm2` can be installed through npm and managed as a user process.

Useful checks:

```bash
uname -a
command -v tmux git node npm
cat /proc/version
```

## WSL2

WSL2 behaves like Linux for most shell tasks, but Windows interop can affect paths and clipboard behavior.

Recommended conventions:

- keep repositories under the Linux filesystem, for example `/home/<user>/src/...`, not under `/mnt/c/...`;
- run `tmux` inside WSL2, not from a Windows terminal multiplexer layer;
- install Node, Git, and pm2 inside WSL2;
- use Windows clipboard bridges only at the edge of the workflow.

Detect WSL2 with:

```bash
grep -qi microsoft /proc/version && echo "WSL detected"
```

Path examples:

```text
Linux/WSL2: /home/<user>/projects/YourProject
Windows mount: /mnt/c/Users/<user>/Projects/YourProject
```

Prefer the Linux/WSL2 path for active worktrees because file watching, permissions, and symlinks are more reliable there.

## macOS

macOS requires a few package differences:

- install `tmux`, `git`, and Node with Homebrew or another package manager;
- `/proc` is not available by default;
- process inspection commands differ from Linux;
- clipboard commands use `pbcopy` and `pbpaste`.

Useful checks:

```bash
uname -a
command -v tmux git node npm
sw_vers
```

When scripts need platform detection, prefer a small shell function:

```bash
case "$(uname -s)" in
  Linux)
    if [ -r /proc/version ] && grep -qi microsoft /proc/version; then
      platform="wsl2"
    else
      platform="linux"
    fi
    ;;
  Darwin)
    platform="macos"
    ;;
  *)
    platform="unknown"
    ;;
esac
```

## tmux

`tmux` is the common session layer. Keep these expectations consistent:

- pane and window names should be descriptive;
- automation should use the orchestration CLI rather than raw pane control when possible;
- long-running workers should be easy to identify from their title, command, and working directory.

## pm2

`pm2` works on Linux, WSL2, and macOS, but service boot behavior differs by platform. For development machines, prefer user-level pm2 processes and explicit `pm2 resurrect` setup only after the process file is stable.

## Clipboard

Clipboard commands are platform-specific:

| Platform | Read | Write |
| --- | --- | --- |
| Linux | `xclip -o` or `wl-paste` | `xclip -selection clipboard` or `wl-copy` |
| WSL2 | `powershell.exe Get-Clipboard` | `clip.exe` |
| macOS | `pbpaste` | `pbcopy` |

Keep clipboard integration optional. Core automation should not require clipboard access.
