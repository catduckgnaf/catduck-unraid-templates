# catduck's Unraid templates

A small, maintained collection of Community Applications templates for useful self-hosted apps on Unraid. Browse the catalog below, install the repository once, and choose the app you want from the Apps tab.

## Install from Community Applications

1. In Unraid, open **Apps** and then **Settings**.
2. Add `https://github.com/catduckgnaf/catduck-unraid-templates` under **Use DockerHub / Custom repositories** and apply.
3. Return to **Apps**, search for an app below, select it, and choose **Install**. Review its paths, ports, and app-specific notes before applying.

## Template catalog

- [Discord Repost History Bot](templates/discord-repost-history-bot.xml) — a Discord bot that saves message history so messages can be found and reposted later.
- [Inferzero](templates/inferzero.xml) — local inference server for Intel Arc GPUs. Standard GPU inference uses a compatible Intel driver in the host kernel; the experimental custom kernel is optional and adds PCI peer-to-peer (P2P) support. See [Inferzero setup and kernel safety](#inferzero).
- [Mealie](templates/mealie.xml) — self-hosted recipe manager and meal planner.
- [Pastey](templates/pastey.xml) — self-hosted paste service. This catduck build is based on upstream Cesura/pastey, which has had no release since 2022; the former community image `arcscloud/pastey` was removed from Docker Hub. It drops TensorFlow for a much smaller image, adds a default paste expiry and expiry picker, supports IPv6 whitelist ranges, and defaults to dark mode.
- [Print Handy](templates/print-handy.xml) — local-first chat-to-print assistant for supported 3D printers; see the [Print Handy setup guide](https://catduckgnaf.github.io/print-handy-docs/).
- [TeddyCloud](templates/teddycloud.xml) — alternative self-hosted server for Tonieboxes; see the [TeddyCloud guide](https://toniebox-reverse-engineering.github.io/docs/tools/teddycloud/).
- [ToDuck](templates/toduck.xml) — local-first task manager with web and Android clients.

## Inferzero

Inferzero is an Intel GPU inference server. Its Docker image is built from the version-controlled recipe in [`docker/inferzero/`](docker/inferzero/) and published to GHCR by this repository's **Publish Inferzero** workflow. The template uses `ghcr.io/catduckgnaf/inferzero:latest`; no local Uranium image is used. An operator can also build the same image from the checked-in Dockerfile and select a specific upstream Inferzero release with the build argument `INFERZERO_RELEASE`.

### Host kernel and optional PCI P2P

Inferzero's standard Intel GPU inference path uses the Intel driver supplied by a compatible Unraid host kernel; it does not require this repository's custom kernel. The separate experimental [Unraid P2P kernel v1.0.0 release](https://github.com/catduckgnaf/unraid-p2p-kernel/releases/tag/v1.0.0) provides optional PCI peer-to-peer (P2P) kernel variants for supported multi-GPU configurations. It is not required for ordinary inference, and installing it does not enable NVIDIA inference in Inferzero.

Before using either experimental kernel variant, read the versioned [installation and rollback instructions](https://github.com/catduckgnaf/unraid-p2p-kernel/blob/v1.0.0/INSTALL.md), [downloads and checksums](https://github.com/catduckgnaf/unraid-p2p-kernel/blob/v1.0.0/README.md#downloads), and [build provenance](https://github.com/catduckgnaf/unraid-p2p-kernel/blob/v1.0.0/BUILD.md). These builds target Unraid 7.4.0 / Linux 6.18.60. The release supplies kernel images and module archives, not a stock `bzroot` or complete boot image. Neither variant has been boot tested; the NVIDIA variant's open modules have not been tested on NVIDIA hardware and require matching 580.196.07 userspace, which is not supplied. Preserve the stock boot entry and recovery path, and follow the published rollback instructions if needed.

Kernel installation is a separate manual host operation. Docker, this template, and Community Applications must never download, install, replace, or modify the host kernel. Do not use a kernel that does not match the documented Unraid version.


### GPU, models, and storage

- This is Intel-only inference through Intel Level Zero and OpenCL. The device mapping exposes the selected `/dev/dri/renderD*` node. Choose the render node belonging to the Intel GPU and set the GPU count for the model. No NVIDIA inference backend is provided. NVIDIA support in a separately maintained custom Unraid kernel does not make Inferzero compatible with NVIDIA GPUs.
- The **Models** appdata mapping persists Hugging Face model downloads. Set **Model** to an Inferzero catalog key (the initial default is `4b`) or to a GGUF path available inside the container. Downloads can use several GB or more; ensure the appdata share has adequate space.
- **Inferzero cache** persists compiled GPU kernels and runtime state, avoiding repeated compilation. Back up the model and cache folders as appropriate.
- The container runs as root and may create root-owned files in mapped appdata folders. The web UI and OpenAI-compatible API have no built-in authentication. Keep the port on a trusted LAN or behind an authenticated reverse proxy; never expose it directly to the public internet.

## Support and contributions

Please [open an issue](https://github.com/catduckgnaf/catduck-unraid-templates/issues/new/choose) to request a template or report a problem. For a **bug report**, include the template/app name, Unraid version, steps to reproduce, and relevant logs with secrets, tokens, and personal information redacted. For a **template request**, include the app name and a link to its project or container image. Please do not post credentials or unredacted logs.

General support: [catduck templates support thread](https://forums.unraid.net/topic/138058-support-catduck-templates/).
