brew "deno"
brew "fastfetch"
brew "gh"
brew "git"
brew "nvm"
brew "remotemobprogramming/brew/mob"
brew "shellcheck"
brew "zsh-completions"

cask_args appdir: "~/Applications", require_sha: true

cask "adobe-creative-cloud", args: { appdir: "/Applications" }
cask "appcleaner"
cask "brave-browser"
cask "cheatsheet"
cask "docker", args: { appdir: "/Applications" }
cask "keepassxc"
cask "keka"
cask "lulu", args: { appdir: "/Applications" }
cask "macfuse", args: { appdir: "/Applications" }
cask "signal"
cask "spotify", args: { require_sha: false }
cask "veracrypt", args: { appdir: "/Applications" }
cask "visual-studio-code"
