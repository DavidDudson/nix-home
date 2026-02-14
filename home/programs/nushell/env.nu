$env.EDITOR = "hx"
$env.PATH = ($env.PATH | split row (char esep) | prepend /home/ddudson/.apps | append /usr/bin/env)
