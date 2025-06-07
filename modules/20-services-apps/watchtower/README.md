# Watchtower Module

This module deploys a Watchtower container which automatically updates your running Docker containers when new images become available.

## Features

- Automatic updates for Docker containers
- Configurable update schedule
- Optional cleanup of old images
- Notification support via shoutrrr
- Container monitoring options

## Input Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| container_name | Name for the Watchtower container | string | "watchtower" |
| image_tag | The tag for the Watchtower container image | string | "latest" |
| restart_policy | Restart policy for the container | string | "unless-stopped" |
| timezone | Timezone for the container | string | "Etc/UTC" |
| cleanup | Remove old images after updating | bool | true |
| poll_interval | Poll interval (in seconds) for checking updates | number | 86400 |
| include_stopped | Include stopped containers when checking for updates | bool | false |
| revive_stopped | Restart stopped containers after updating | bool | false |
| rolling_restart | Restart containers one by one instead of all at once | bool | true |
| notification_url | URL for sending update notifications via shoutrrr | string | "" |
| enable_notifications | Enable shoutrrr notifications | bool | false |
| additional_env_vars | Additional environment variables for Watchtower | map(string) | {} |
| additional_volumes | Additional volumes to mount in the container | list(object) | [] |
| labels | Labels to set on the container | map(string) | {} |
| ports | Ports to expose (rarely needed for Watchtower) | list(object) | [] |
| monitoring | Enable monitoring for the container | bool | true |

## Outputs

| Name | Description |
|------|-------------|
| container_name | Name of the created Watchtower container |
| container_id | ID of the created Watchtower container |
| image_id | ID of the Watchtower image used |

## Notes

- Watchtower needs access to the Docker socket to monitor and update containers
- For security-conscious environments, consider limiting which containers Watchtower can update
- See the [Watchtower documentation](https://containrrr.dev/watchtower/) for more advanced configuration options
