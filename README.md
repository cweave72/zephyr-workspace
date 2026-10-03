# Zephyr Workspace

## Prerequisite: Installing the Zephyr SDK

See https://docs.zephyrproject.org/latest/develop/getting_started/index.html

Note: replace `0.17.0` below with the latest version.
```bash
cd ~
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/zephyr-sdk-0.17.0_linux-x86_64.tar.xz
```

Proceed with the install
```bash
cd ~
mkdir -p .local/opt
cp zephyr-sdk-0.17.0_linux-x86_64.tar.xz .local/opt/
cd .local/opt
tar xvf zephyr-sdk-0.17.0_linux-x86_64.tar.xz
cd zephyr-sdk-0.17.0
./setup

# Install udev rules (still in extracted zephyr-sdk-0.17.0 directory)
sudo cp sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d
sudo udevadm control --reload
```

## Getting Started

On a clean checkout, do the following:

1. `./init_workspace.sh --init`

This runs the following steps in order:

1. Create the build virtual environment and install `west` in it. The full
   environment cannot install yet, because it depends on the `python`
   repository, which `west update` clones.
2. `west init`, `west update`, and `west zephyr-export`.
3. Install the full build environment (`uv sync --all-groups`). This sources
   `workspace-env.sh` first, because the `python` packages build their protobuf
   bindings from `PROTO_BASE`.
4. Fetch the esp32 blobs. This step needs the full environment.

After `--init`, the repositories are on their `manifest-rev` branches. Run
`./init_workspace.sh --main` before you make changes. Refer to
[Developing applications within the workspace](#developing-applications-within-the-workspace).

`init_workspace.sh` supplies these options:

| Option          | Task                                                                                                                         |
|-----------------|------------------------------------------------------------------------------------------------------------------------------|
| `--init`        | Initialize a clean checkout.                                                                                                 |
| `--venv`        | Delete the build virtual environment and create it again. Run it after `--init` only; it needs the `python` repository.      |
| `-m`, `--main`  | Switch the workspace repositories to the `main` branch.                                                                      |
| `-r`, `--reset` | Delete the build virtual environment, the west metadata, and the generated files. Does not delete `deps/` or any repository. |
| `--reset-deps`  | Delete `deps/`. west clones the external code again.                                                                         |
| `-h`, `--help`  | Show the options.                                                                                                            |

`--reset` and `--reset-deps` report the uncommitted changes and the unpushed
commits of each workspace repository before they delete anything.

`main_repos.sh` holds the list of workspace repositories. `--main` and the
reset report read that list. Add a repository there when the manifest gains
one.

### Workspace environment variables

`workspace-env.sh` exports the variables that the build scripts and the host
tools need. `PROTO_BASE` gives the location of the `.proto` files.
`WORKSPACE_BASE` gives the workspace root.

`common.mk` sources `workspace-env.sh` and `init_venv.sh`. Thus an application
build needs no manual step. Source the file yourself only when you use the
host tools directly:

```bash
source workspace-env.sh
```

## Workspace Structure

`west` manages each directory below. The four `cweave72` repositories hold the
code of this project. `deps` holds the external code.

```
├── applications            Firmware applications (repo: zephyr-applications)
├── common                  Shared device code (repo: zephyr-common)
│   ├── boards              Out-of-tree board definitions
│   ├── drivers
│   ├── modules             Device modules (ProtoRpc, TraceModule, ...)
│   ├── scripts             Make and CMake build scripts
│   ├── templates           Copier template for app_gen
│   └── tools
├── proto                   Protobuf definitions (repo: zephyr-proto)
├── python                  Host tools and CLIs (repo: zephyr-python)
├── deps                    External code. west clones it.
│   ├── bootloader          mcuboot
│   ├── modules             Zephyr HAL and library modules
│   ├── optional
│   │   └── nanopb
│   ├── tools               net-tools
│   └── zephyr              The Zephyr RTOS
├── manifest-repo
│   └── west.yml            The workspace manifest
├── common.mk               Shared make rules for applications
├── init_venv.sh            Creates and activates the build venv
├── init_workspace.sh       Initializes a clean checkout
├── main_repos.sh           The list of workspace repositories
├── pyproject.toml          Build environment dependencies
└── workspace-env.sh        Sets WORKSPACE_BASE, PROTO_BASE, and other variables
```

Workspace manifest:

`manifest-repo/west.yml`
```yaml
manifest:
  remotes:
    - name: zephyrproject-rtos
      url-base: https://github.com/zephyrproject-rtos
    - name: cweave72
      url-base: https://github.com/cweave72
    - name: nanopb
      url-base: https://github.com/nanopb
  projects:
    - name: zephyr-applications
      remote: cweave72
      revision: main
      path: applications
    - name: zephyr-common
      remote: cweave72
      revision: main
      path: common
    - name: zephyr-proto
      remote: cweave72
      revision: main
      path: proto
    - name: zephyr-python
      remote: cweave72
      revision: main
      path: python
    - name: nanopb
      remote: nanopb
      revision: nanopb-0.4.9
      path: deps/optional/nanopb
    - name: zephyr
      remote: zephyrproject-rtos
      revision: v4.0.0
      import:
        path-prefix: deps
        name-allowlist:
          - cmsis
          - hal_espressif
          - hal_rpi_pico
          - hal_stm32
          - mbedtls
          - mcuboot
          - net-tools
          - littlefs
  self:
    path: manifest-repo
```

## Building an application

Run `make` from the directory of the application. Each application includes
`common.mk`, which supplies the targets. `common.mk` also sources the
workspace environment and activates the build virtual environment, thus no
manual step comes first.

```bash
cd applications/<app_name>
make BOARD=<board> build
make flash
make mon
```

`make flash mon` flashes the board and then starts the serial monitor.

| Target        | Task                                                        |
|---------------|-------------------------------------------------------------|
| `build`       | Run a west build. Add `PRISTINE=y` for a clean build.       |
| `flash`       | Program the board.                                          |
| `mon`         | Run the serial monitor.                                     |
| `debug`       | Program the board, then start gdb. Needs a debug probe.     |
| `attach`      | Attach gdb to a running target. Does not program the board. |
| `debugserver` | Start a gdb server on port 3333.                            |
| `reset`       | Restart the image on the target.                            |
| `menuconfig`  | Run the menuconfig utility.                                 |
| `appboards`   | List the boards that this application supports.             |
| `boards`      | List the boards that Zephyr supports.                       |
| `clean`       | Delete the build directory.                                 |

Run `make help` in an application directory for the full list and for more
examples.

## Developing applications within the workspace

This workspace is the place where development is intending to take place.
However, this is a bit tricky since `west` manages external projects by creating
a `manifest-rev` branch for any imported project.

This applies to all four `cweave72` repositories: `applications`, `common`,
`proto`, and `python`. Each one gets a `manifest-rev` branch.

Switch the repositories to `main` before you make any changes:

```bash
./init_workspace.sh --main
```

This fetches all four repositories and checks out `main` in each one. Then
modify, commit, and push as normal.

`west update` resets each repository to its `manifest-rev` branch. Thus you
must run `./init_workspace.sh --main` again after each update.

### If changes have already been made in the `manifest-rev` branch:

Sometimes, you forget.  The following is a procedure for syncing local changes
within the `manifest-rev` to another branch (i.e. `main`).

Within the local app directory:
```bash
git status                     # should show you are on the manifest-rev branch
git stash                      # Stash local changes we want to push to main.
git checkout <target-branch>   # Switch to the desired branch (e.g. main)
git stash pop                  # Apply stashed changes to target-branch
git commit -m "..."            # Commit to target-branch
git push                       # Push changes to remote (note: git push origin
                               #    main causes some error. git push works)
```

Back at the workspace top:
`west update`

You will see a message:
```
=== updating zephyr-applications (applications):
--- zephyr-applications: fetching, need revision main
From https://github.com/cweave72/zephyr-applications
 * branch            main       -> FETCH_HEAD
HEAD is now at 3a19916 Added README.md.
WARNING: left behind zephyr-applications branch "main"; to switch back to it (fast forward):
  git -C applications checkout main
```

## Upgrading Zephyr version

Use this procedure to move to a newer version of the Zephyr code base.

1. Change the `zephyr` revision in the workspace manifest. Change only this
   entry. The other projects do not change.

`manifest-repo/west.yml`
```yaml
    - name: zephyr
      remote: zephyrproject-rtos
      revision: v4.1.0                    # --> Was v4.0.0
      import:
        path-prefix: deps
        name-allowlist:
          - cmsis
          - hal_espressif
          - hal_rpi_pico
          - hal_stm32
          - mbedtls
          - mcuboot
          - net-tools
          - littlefs
```

2. Run `west update` at the top of the workspace.

```
. init_venv.sh
west update
```

3. (esp32 only) Fetch the esp32 blobs again.
```
west blobs fetch hal_espressif
```

## Managing the Python Environment

The python virtual environment is managed by the `uv` tool.  All dependencies
for development, the Zephyr build environment, and the host tools (the
`zephyr-python` path dependency) are incorporated into the `pyproject.toml`
file.

Initially, zephyr python dependencies were added to the pyproject.toml file
by the following command:
```bash
uv add --group zephyr -r deps/zephyr/scripts/requirements.txt
```

The environment may be refreshed by:
```bash
source workspace-env.sh     # PROTO_BASE is needed to build the host tools
uv venv
uv sync --all-groups
```

Alternatively, run `./init_workspace.sh --venv`, which does this for you.

Python dependencies can be added by:
`uv add <dep>`

Local Python dependencies (editable) are added by:
`uv add -e /path/to/local/package`

## Host tools (`python`)

The `python` directory is a separate repository, `zephyr-python`. It contains
the host tools for the workspace. The tools send RPC commands to a device,
generate code from `.proto` files, generate new applications, and read device
trace data.

### Virtual environments

The workspace `.venv` contains `west`, the Zephyr dependencies, and the host
tools (`app_gen`, `fsapi-cli`, `trace-tool`, and others). It is the only
environment that you need in the workspace. The build activates it, and
`init_venv.sh` at the workspace root activates it for you.

`python/.venv` is for standalone use of the `python` repository, which operates
without this workspace. Refer to `python/README.md`.

### Setup

The workspace `.venv` installs the tool packages. `./init_workspace.sh --init`
does this. Source the workspace environment and activate the environment to
use the tools:

```bash
source workspace-env.sh
source init_venv.sh
```

### Generated protobuf bindings

Some tool packages do not contain their Python protobuf bindings. They
generate the bindings at install time, and `PROTO_BASE` gives the location of
the `.proto` files. Thus you must source the workspace environment before you
install the packages.

A plain `uv sync` does not generate the bindings again. To generate them again
in the workspace `.venv`, reinstall the packages with `PROTO_BASE` set:

```bash
source workspace-env.sh
uv sync --all-groups --reinstall
```

`python/rebuild_venv.sh` does the same for `python/.venv`.

Refer to `python/README.md` for the tool list and for more information. That
repository also operates alone, without this workspace.
