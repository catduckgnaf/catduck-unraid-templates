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
- [PS5Upload](templates/ps5upload.xml) — community template for the upstream PS5Upload web UI and engine; see [PS5Upload setup and security notes](#ps5upload). This repository template is not an upstream endorsement or an Unraid catalog approval.
- [Print Handy](templates/print-handy.xml) — local-first chat-to-print assistant for supported 3D printers; see the [Print Handy setup guide](https://catduckgnaf.github.io/print-handy-docs/).
- [TeddyCloud](templates/teddycloud.xml) — alternative self-hosted server for Tonieboxes; see the [TeddyCloud guide](https://toniebox-reverse-engineering.github.io/docs/tools/teddycloud/).
- [ToDuck](templates/toduck.xml) — local-first task manager with web and Android clients.

## PS5Upload

PS5Upload is an upstream project. This repository provides an independent Community Applications template that uses the upstream container image; it does not imply upstream endorsement. Adding this repository through Community Applications' custom repository setting is separate from applying for approval in Unraid's public template catalog. This repository template is not such an approval or listing.

### Setup and security

- The template uses host networking so the PS5Upload engine can serve its app traffic on port 19113. Open the Web UI at `http://<Unraid server address>:19113/` from a permitted device.
- The Web UI and API have no password and can perform sensitive file operations. The template defaults `PS5UPLOAD_ALLOW_IP` to loopback (`127.0.0.1`), so remote browsers are not allowed initially. To use it from another device, set **Allowed client IPs** to only the trusted client address or CIDR that needs access. Do not use `0.0.0.0/0`, forward the port, or expose the service to the internet.
- Persistent settings and identity data are stored in the appdata folder. Keep that folder and its contents; the container runs as UID 99 and GID 100 and needs write access there.
- Package folder mappings are optional and read-only in the container. Add only folders you intend the app to browse, then list their container paths in **Package browser roots** if needed.
- Leave **PS5 address** blank unless you choose to configure it. Review the upstream [project documentation](https://github.com/phantomptr/ps5upload) for current app behavior and compatibility. This template does not provide console setup or compatibility guidance.

## Inferzero

Inferzero is an Intel GPU inference server. Its Docker image is built from the version-controlled recipe in [`docker/inferzero/`](docker/inferzero/) and published to GHCR by this repository's **Publish Inferzero** workflow. The template follows `ghcr.io/catduckgnaf/inferzero:latest`; the corresponding dated tag identifies the upstream release (for example, `2026.11.27.04`). For repeatable installations, select a dated tag in Unraid rather than `latest`. The upstream release asset is SHA-256 checked during image build. The container includes FFmpeg for Linux image, audio and video decoding and Poppler utilities (`pdfinfo`, `pdftoppm`) for PDF workflows; their presence does not mean every model can interpret images.

### Host kernel and optional PCI P2P

Standard Intel GPU inference uses the Intel driver supplied by a compatible Unraid host kernel. No custom kernel is required for a single GPU or ordinary inference. The separate experimental [Unraid P2P kernel v1.0.0 release](https://github.com/catduckgnaf/unraid-p2p-kernel/releases/tag/v1.0.0) provides optional PCI peer-to-peer (P2P) kernel variants for supported multi-GPU configurations. It does not enable NVIDIA inference. Before considering it, read the versioned [installation and rollback instructions](https://github.com/catduckgnaf/unraid-p2p-kernel/blob/v1.0.0/INSTALL.md), [downloads and checksums](https://github.com/catduckgnaf/unraid-p2p-kernel/blob/v1.0.0/README.md#downloads), and [build provenance](https://github.com/catduckgnaf/unraid-p2p-kernel/blob/v1.0.0/BUILD.md). These builds target Unraid 7.4.0 / Linux 6.18.60; neither variant has been boot tested. The NVIDIA variant's open modules have not been tested on NVIDIA hardware and require matching 580.196.07 userspace, which is not supplied. Preserve the stock boot entry and recovery path. Kernel installation is a separate manual host operation: Docker, this template, and Community Applications must never install or modify the host kernel.

### GPU, models, storage, and network

- In Unraid, map each Intel GPU by adding its render device to the container. The template's first GPU default is `/dev/dri/renderD128`; select the actual matching `/dev/dri/renderD*` device on your host. Node numbers can change after reboot or hardware changes, so identify devices from the host instead of assuming the example number is universal. For a single-GPU model, keep **GPU count** at `1`. For one model split across two GPUs, map both devices and set **GPU count** to `2`; the value alone does not discover or map a GPU. This flag is tensor parallel by default. Upstream also documents `--split layer` and unequal `--tensor-split` values, but layer splitting is capacity-oriented and does not speed up a single request. Check current [upstream multi-GPU guidance](https://github.com/rizagp/inferzero/blob/main/docs/multi-gpu.md) for model support and limitations.
- Example only, not universal: Uranium has two Intel Arc Pro B50s. The verified split setup used both GPUs with `--gpus 2`; device node assignments are specific to that host and must not be copied blindly. On this host, P2P was unavailable on the running stock kernel; tensor-parallel transfers went through host memory. Splitting can therefore be slower than one GPU for some models. A tested alternative on dual-card hosts is one independent Inferzero container/model per GPU, each with its own mapped device, appdata home, and host port (for example 8095 and 8096); this avoids splitting one model but requires an extra container configuration.
- **Models** maps host `/mnt/user/appdata/inferzero/models` to `/root/.cache/huggingface` and persists Hugging Face downloads, GGUF files, and associated model assets. Set **Model** to an upstream catalog key or a GGUF path visible in the container. Some gated repositories require an authorized Hugging Face token; do not put tokens in public template values. Compatible vision models use their matching `mmproj` projector file alongside the model assets; consult upstream model instructions and confirm the selected model reports vision support. A split model does not support image encoders in upstream release `2026.11.27.04`; the tested split B50 setup reported `vision:false`. Use a supported unsplit vision model for image input. FFmpeg/Poppler provide decoding and PDF page extraction, not a vision encoder or OCR model by themselves.
- **Inferzero cache** maps host `/mnt/user/appdata/inferzero/cache` to `/root/.inferzero` and persists compiled kernels/runtime state. Ensure the appdata share has enough capacity for multi-GB model and expert-cache files. The container runs as root and may create root-owned files in mapped folders; preserve permissions accordingly when managing them from Unraid.
- The container listens on port `8090` (template WebUI/API mapping). For an additional instance, give it a distinct host port while keeping container port 8090. The UI and OpenAI-compatible API have no built-in authentication. Keep them on a trusted LAN or behind an authenticated reverse proxy; never expose the service directly to the public internet.
- The container's `SERVER_ARGS` field passes additional supported `serverz` flags, for example `--ctx 32768` or, for a supported split model, `--split layer`. `MODEL` selects the model and `GPUS` sets the number of GPUs. The entrypoint starts `zero-launcher.sh` with the chosen model, host, port and GPU count; consult the [upstream usage guide](https://github.com/rizagp/inferzero/blob/main/USAGE.md) for current model names and options. Keep defaults at one GPU unless deliberately configuring a supported split.


## Support and contributions

Please [open an issue](https://github.com/catduckgnaf/catduck-unraid-templates/issues/new/choose) to request a template or report a problem. For a **bug report**, include the template/app name, Unraid version, steps to reproduce, and relevant logs with secrets, tokens, and personal information redacted. For a **template request**, include the app name and a link to its project or container image. Please do not post credentials or unredacted logs.

General support: [catduck templates support thread](https://forums.unraid.net/topic/138058-support-catduck-templates/).
