# TOOLS.md

This file is managed by Nix. A plugin report is appended below.

## Spotify (bigscreen only)

Two CLI tools are available on bigscreen for Spotify control.

### playerctl — playback control via MPRIS

```sh
playerctl play
playerctl pause
playerctl play-pause
playerctl next
playerctl previous
playerctl status          # playing / paused / stopped
playerctl metadata        # current track info
```

### spotify-player — search and queue specific tracks

```sh
# Search and play
spotify-player playback start track --name "Song Name" --artists "Artist"
spotify-player playback start album --name "Album Name"
spotify-player playback start playlist --name "Playlist Name"

# Playback control (alternative to playerctl)
spotify-player playback play-pause
spotify-player playback next
spotify-player playback previous
spotify-player playback volume 80   # 0-100

# Search (returns results without playing)
spotify-player search tracks "query"
spotify-player search albums "query"
spotify-player search artists "query"
```

When asked to play something on bigscreen, prefer `spotify-player playback start` to search and play by name, and `playerctl` for simple play/pause/skip commands.
