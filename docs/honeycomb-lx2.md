# HoneyComb LX2

Notes for the [HoneyComb LX2](https://www.solid-run.com/arm-servers-networking-platforms/honeycomb-servers-workstation).

These notes assume you're using a [UEFI image](https://solidrun.atlassian.net/wiki/spaces/developer/pages/197494288/HoneyComb+LX2+ClearFog+CX+LX2+Quick+Start+Guide#Build-From-Source%3A).

# PCIe passthrough

If the SPF network interfaces are not working and the kernel console is getting spammed by `arm-smmu arm-smmu.1.auto: Unhandled context fault`, then you may need to bypass the IOMMU. This can done by adding `iommu.passthrough=1` to the Kernel commandline.

On Ubuntu, the easiest way is to add the following to `/etc/default/grub.d/iommu-passthrough`:

```bash
GRUB_CMDLINE_LINUX="${GRUB_CMDLINE_LINUX} iommu.passthrough=1"
```

# Automatically add SFP interfaces

Add the following to `/etc/udev/rules.d/fsl_mc_bus.rules`:

```
ACTION=="add", SUBSYSTEM=="fsl-mc", ENV{DEVTYPE}=="fsl_mc_bus_dpmac", KERNEL=="dpmac.9", RUN+="/usr/bin/flock /usr/bin/ls-addni -c '(PATH=/usr/bin:/usr/local/bin /usr/local/bin/ls-addni %k)'"
```
