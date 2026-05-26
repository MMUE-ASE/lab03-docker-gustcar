# WSL2 + Docker Setup (Lab PC)

On the lab PCs, **Docker runs inside WSL2** (Windows Subsystem for Linux), not directly on
Windows. You must open this project through VS Code's **WSL connection** so the integrated
terminal runs inside WSL where the `docker` command exists.

> If you run `docker` from a normal Windows PowerShell/Git Bash terminal and get
> `command not found`, you are in the wrong place — you opened the folder on Windows
> instead of in WSL. Follow Step 2 below.

---

## Table of Contents

- [1. Verify WSL2 and Docker are present](#1-verify-wsl2-and-docker-are-present)
- [2. Open the project in VS Code (WSL)](#2-open-the-project-in-vs-code-wsl)
- [3. Where to keep the repository](#3-where-to-keep-the-repository)
- [4. Smoke-test Docker](#4-smoke-test-docker)
- [5. Flashing the board from WSL (USB passthrough)](#5-flashing-the-board-from-wsl-usb-passthrough)
- [6. Troubleshooting](#6-troubleshooting)

---

## 1. Verify WSL2 and Docker are present

Open **Windows PowerShell** and confirm WSL is running at version 2:

```powershell
wsl --list --verbose      # the VERSION column must read 2 for your distro
```

Then open the WSL shell and run the following **one-time setup** steps:

```bash
wsl                                        # drops you into the Linux shell

# (a) Confirm Docker is installed
docker --version                           # e.g. Docker version 27.x

# (b) Add your user to the docker group so you never need sudo for docker commands.
#     Log out of WSL and reopen it after this — the group takes effect on next login.
sudo usermod -aG docker $USER
exit
```

Reopen WSL, then **each session** start the Docker daemon:

```bash
sudo service docker start                  # starts the daemon in the background
```

> **Avoid typing this every session:** enable systemd so the daemon starts automatically.
> Add the following to `/etc/wsl.conf` (create it if it does not exist), then run
> `wsl --shutdown` from PowerShell and reopen WSL:
>
> ```ini
> [boot]
> systemd=true
> ```
>
> After that, Docker starts automatically with WSL and you never need
> `sudo service docker start` again.

Finally, verify Docker works end-to-end:

```bash
docker run hello-world    # should print the "Hello from Docker!" welcome message
```

(On the lab PCs Docker is pre-installed — you are only doing the one-time group setup and
confirming the daemon starts correctly.)

---

## 2. Open the project in VS Code (WSL)

The goal: the bottom-left corner of VS Code should show **`WSL: <distro>`**.

1. Install the **WSL** extension (`ms-vscode-remote.remote-wsl`) — it is in this lab's
   recommended extensions, so VS Code will offer it on first open.
2. Open the WSL shell, `cd` into your cloned repo, and launch VS Code from there:

   ```bash
   cd ~/path/to/your-lab3-repo
   code .
   ```

   The first `code .` from WSL installs a small VS Code server inside WSL automatically.
3. Confirm the green/blue indicator in the bottom-left reads **`WSL: Ubuntu`** (or your
   distro name). The integrated terminal (`` Ctrl+` ``) now runs inside WSL — `docker`
   works here.

---

## 3. Where to keep the repository

Clone the repo **inside the WSL filesystem** (e.g. under your Linux home `~/`), not under
`/mnt/c/...`. Docker bind mounts and Git are dramatically faster on the native WSL
filesystem; building from `/mnt/c` can be many times slower.

```bash
# Good — native WSL filesystem
cd ~ && git clone <your-repo-url>

# Avoid — Windows drive mounted into WSL (slow for Docker/Git)
cd /mnt/c/Users/you/ && git clone <your-repo-url>
```

---

## 4. Smoke-test Docker

From the repo root inside WSL:

```bash
docker run --rm hello-world      # prints the Docker welcome message
docker images                    # lists images you have pulled/built
```

You are now ready to start [Phase 1](../README.md#phase-1--docker-basics) of the lab.

---

## 5. Flashing the board from WSL (USB passthrough)

**The build runs in the container; flashing does not.** A container cannot see the ST-LINK
USB device, so you flash from *outside* the container. With WSL there are two supported
paths — pick whichever your lab PC is set up for:

### Option A — Attach the ST-LINK to WSL with `usbipd` (recommended in WSL)

`usbipd-win` shares a Windows USB device into WSL. In an **Administrator PowerShell**:

```powershell
usbipd list                       # find the ST-LINK; note its BUSID (e.g. 2-4)
usbipd bind   --busid 2-4         # one-time: mark it shareable
usbipd attach --wsl --busid 2-4   # attach it to WSL (repeat after each replug)
```

Then, inside WSL, confirm and flash:

```bash
lsusb                             # ST-LINK should now appear
sudo apt install -y openocd       # if not already present
bash scripts/flash.sh             # uses host OpenOCD against output/lab2.elf
```

### Option B — Flash from Windows

Leave the ST-LINK on Windows and run OpenOCD there (the same setup you used in Lab 2),
pointing at the ELF the container produced. Your WSL files are reachable from Windows at
`\\wsl$\<distro>\home\<you>\...`.

> Either way, the **debug/flash step is identical to Lab 2** — Docker only changed *how the
> firmware is built*, not how it is loaded onto the board. See
> [../debug/README.md](../debug/README.md).

---

## 6. Troubleshooting

| Symptom                                   | Likely cause / fix                                                        |
| ----------------------------------------- | ------------------------------------------------------------------------- |
| `docker: command not found`               | Terminal is on Windows, not WSL. Reopen with `WSL:` shown bottom-left.    |
| `Cannot connect to the Docker daemon`     | Docker service not started in WSL. `sudo service docker start`, retry.    |
| `permission denied … /var/run/docker.sock`| Your user is not in the `docker` group. `sudo usermod -aG docker $USER`, then reopen the shell. |
| Build extremely slow                      | Repo lives on `/mnt/c`. Move it to the WSL home (`~`). See Section 3.     |
| `lsusb` does not show the ST-LINK         | Re-run `usbipd attach --wsl --busid <id>` after replugging the board.     |
