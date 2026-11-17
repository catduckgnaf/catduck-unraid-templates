# catduck's Unraid templates

Community Application templates maintained by catduck.

## Add this repository to Unraid

1. Open the Unraid Apps tab.
2. Open the settings icon and select **Settings**.
3. Add this repository URL to **Use DockerHub / Custom repositories**:
   `https://github.com/catduckgnaf/catduck-unraid-templates`
4. Apply the settings, then search for the application in Apps.

Support: [catduck templates support thread](https://forums.unraid.net/topic/138058-support-catduck-templates/).

## Templates

- **Pastey** — a self-hosted paste service. This catduck build is based on upstream Cesura/pastey, which has had no release since 2022; the former community image `arcscloud/pastey` was removed from Docker Hub. It drops TensorFlow for a much smaller image, adds a default paste expiry and expiry picker, supports IPv6 whitelist ranges, and defaults to dark mode.
