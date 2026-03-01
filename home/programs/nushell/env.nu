$env.EDITOR = "hx"
$env.PATH = ($env.PATH | split row (char esep) | prepend /home/ddudson/.apps | append /usr/bin/env)

# API keys from 1Password (fetched once per shell session)
$env.PIXELLAB_API_KEY = (try { op read "op://Private/PixelLab/credential" } catch { "" })
