# Flashing & Debugging — Outside the Container

In this lab the firmware is **built inside Docker** but **flashed and debugged outside it**.
The reason is simple: a container does not have access to the ST-LINK USB device, and the
ST-LINK drivers are installed on the host. So the build environment is containerised; the
hardware connection stays on the host — exactly as in Lab 2.

```text
   ┌─────────────── Docker container ───────────────┐
   │  arm-none-eabi-gcc + make  →  output/lab2.elf   │   build here
   └───────────────────────┬─────────────────────────┘
                           │  (bind mount: file appears on host)
                           ▼
   ┌─────────────────────── Host ────────────────────┐
   │  OpenOCD + ST-LINK  →  NUCLEO-F412ZG             │   flash/debug here
   └──────────────────────────────────────────────────┘
```

---

## Flashing

Once `output/lab2.elf` exists on the host (after `bash scripts/docker-build.sh`):

```bash
bash scripts/flash.sh
```

This runs **host** OpenOCD — not the container. For the ST-LINK to be reachable from WSL,
attach it with `usbipd` first (or flash from Windows). See
[../docs/wsl_docker_setup.md §5](../docs/wsl_docker_setup.md#5-flashing-the-board-from-wsl-usb-passthrough).

---

## Debugging with VS Code (F5)

Debugging is unchanged from Lab 2 and also runs on the host:

1. Build the firmware in the container (`bash scripts/docker-build.sh`).
2. Make sure the ST-LINK is reachable from where VS Code runs OpenOCD.
3. Press **F5** — Cortex-Debug launches host OpenOCD + `arm-none-eabi-gdb`, loads
   `output/lab2.elf`, and halts at `main()`.

The `.vscode/launch.json`, `debug/openocd-connect.cfg`, and `debug/STM32F412.svd` are the
same files you used in Lab 2, carried forward so the debug experience is identical.

| Key           | Action                          |
| ------------- | ------------------------------- |
| **F5**        | Continue to next breakpoint     |
| **F10**       | Step over                       |
| **F11**       | Step into                       |
| **Shift+F11** | Step out                        |
| **Shift+F5**  | Stop debug session              |

---

## Troubleshooting

| Symptom                    | Likely cause                          | Fix                                                            |
| -------------------------- | ------------------------------------- | ------------------------------------------------------------- |
| `output/lab2.elf` missing  | Build not run, or ran without a mount | `bash scripts/docker-build.sh` (check the `-v` mount)         |
| `No ST-LINK device found`  | USB not passed through to WSL         | `usbipd attach --wsl --busid <id>`; see wsl_docker_setup.md    |
| `spawn openocd ENOENT`     | OpenOCD not in PATH on the host       | Install OpenOCD on the host (WSL: `sudo apt install openocd`)  |
| `Examination failed`       | MCU asleep / HardFault                | `debug/openocd-connect.cfg` forces a reset; replug if it persists |
