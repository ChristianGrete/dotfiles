__prompt_command() {
  local out state br sign

  # Separator: empty line before prompt (except on the very first one).
  local sep="${__prompt_sep:-}"
  __prompt_sep=$'\n'

  # Compute display path for length check (replicates \w behavior).
  local display_pwd="${PWD/#$HOME/\~}"

  # Non-printing sequences must be wrapped in \[ \] for bash.
  local c_reset='\[\033[0m\]'
  local c_dim='\[\033[2m\]'
    local c_dim_bold='\[\033[2;1m\]'

  # Git segment (optional).
  local git_line=""
  out="$(prompt_git 2> '/dev/null')" || out=""
  if [[ -n "$out" ]]; then
    local IFS=$'\t'
    read -r state br <<< "$out"

    local c_green='\[\033[32m\]'
    local c_orange='\[\033[33m\]'
    local c_red='\[\033[31m\]'
    local c_bold='\[\033[1m\]'

    case "$state" in
      0) git_line="${c_dim}└── ${c_dim_bold}${br}${c_reset}" ;;
      1) git_line="${c_dim}└── ${c_reset}${c_green}${c_bold}${br}${c_reset}" ;;
      2) git_line="${c_dim}└── ${c_reset}${c_orange}${c_bold}${br}${c_reset}" ;;
      3) git_line="${c_dim}└── ${c_reset}${c_red}${c_bold}${br}${c_reset}" ;;
    esac
  fi

  # Prompt character.
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    sign="#"
  else
    sign="$"
  fi

  # Short paths (single char like ~ or /) without git: compact single-line.
  if [[ ${#display_pwd} -le 1 && -z "$git_line" ]]; then
    PS1="${sep}${c_dim}\w${c_reset} ${c_dim}${sign}${c_reset} "
  else
    local pwd_parent="${display_pwd%/*}"
    local pwd_tail="${display_pwd##*/}"
    if [[ -z "$pwd_parent" ]]; then
      pwd_parent="/"
    elif [[ "$pwd_parent" != "/" ]]; then
      pwd_parent+="/"
    fi


    PS1="${sep}${c_dim}${pwd_parent}${c_reset}${c_dim_bold}${pwd_tail}${c_reset}"
    [[ -n "$git_line" ]] && PS1+=$'\n'"${git_line}"
    PS1+=$'\n\n'"${c_dim}${sign}${c_reset} "
  fi
}

# If something else already uses PROMPT_COMMAND, append ours.
if [[ -n "${PROMPT_COMMAND-}" ]]; then
  case ";$PROMPT_COMMAND;" in
    *";__prompt_command;"*) : ;;
    *) PROMPT_COMMAND="${PROMPT_COMMAND};__prompt_command" ;;
  esac
else
  PROMPT_COMMAND="__prompt_command"
fi
