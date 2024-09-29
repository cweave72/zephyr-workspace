# Zephyr Workspace

## Prerequisite: Installing the Zephyr SDK

See https://docs.zephyrproject.org/latest/develop/getting_started/index.html

Note: replace `0.16.8` below with the latest version.
```bash
cd ~
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_linux-x86_64.tar.xz
```

Proceed with the install
```bash
cd ~
mkdir -p .local/opt
cp zephyr-sdk-0.16.8_linux-x86_64.tar.xz .local/opt/
cd .local/opt
tar xvf zephyr-sdk-0.16.8_linux-x86_64.tar.xz
cd zephyr-sdk-0.16.8
./setup

# Install udev rules (still in extracted zephyr-sdk-0.16.8 directory)
sudo cp sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d
sudo udevadm control --reload
```

## Getting Started

On a clean checkout, do the following:

1. `./init_workspace.sh`

## Workspace Structure

```
├── applications
│   └── ...
├── deps
│   ├── ...
│   └── zephyr
│       └── west.yml
├── manifest-repo
│   └── west.yml
├── init_venv.sh
├── init_workspace.sh
├── requirements.txt
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
  projects:
    - name: zephyr-applications
      remote: cweave72
      revision: main
      path: applications
    - name: zephyr
      remote: zephyrproject-rtos
      revision: v3.7.0
      import:
        path-prefix: deps
        name-allowlist:
          - cmsis
          - hal_espressif
          - hal_stm32
          - mcuboot
          - net-tools
          - littlefs
  self:
    path: manifest-repo
```

## Developing applications within the workspace

This workspace is the place where development is intending to take place.
However, this is a bit tricky since `west` manages external projects by creating
a `manifest-rev` branch for any imported project.

To work around this, switch the `applications` branch over to `main` (typically)
prior to making any changes.  Then, modify, commit and push as normal.  Just
remember that anytime you run `west update`, the branch will be reset to the
`manifest-rev` branch and you will need to switch back to the `main` branch.

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
