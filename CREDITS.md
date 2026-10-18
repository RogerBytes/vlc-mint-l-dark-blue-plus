# Credits

## Skin

The Mint-L Dark Blue skin is a heavily reworked fork of **VLC Yaru Dark**:

- https://github.com/feschukov/vlc-yaru-dark (fork of https://gitlab.com/NovaQC/vlc-yaru-dark)
- Some media-control glyphs in Yaru Dark were themselves reused from
  VLC-Arc-Dark (https://github.com/varlesh/VLC-Arc-Dark) and VLC Deep Dark.

The original authors are not involved in this version — please do not
contact them about it.

Third-party assets:

- Window buttons (close / minimise / maximise): taken from the
  **Mint-L** theme, Blue variant — https://github.com/linuxmint/mint-l-theme (GPL-3.0)
- Colours: taken from Mint-L-Dark-Blue (`gtk-dark.css`).
- Fonts: **Ubuntu Bold** and **Ubuntu Mono** — Ubuntu Font Licence 1.0
  (see `skin/*/Icones/Ubuntu-font-licence.txt`).

The skin is licensed under GPL-3.0 (see `LICENSE`).

## Patch

`patch/vlc-3.0-skins2-cursor-and-tracks.patch` modifies VLC's skins2 module
(https://code.videolan.org/videolan/vlc). The cursor handling is a backport of
the implementation found in VLC's development branch (VLC 4). The patch is
distributed under VLC's license, GPL-2.0-or-later.
