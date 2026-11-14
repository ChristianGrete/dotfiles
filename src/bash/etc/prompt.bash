# Dynamic text is referenced by name in PS1, so bash never expands its contents.
__dotfiles_prompt_command() {
  local out state br sign

  # Separator: empty line before prompt (except on the very first one).
  local sep="${__dotfiles_prompt_sep:-}"
  __dotfiles_prompt_sep=$'\n'

  # Compute display path for length check (replicates \w behavior).
  local display_pwd="$PWD"
  if [[ "$PWD" == "$HOME" || "$PWD" == "$HOME/"* ]]; then
    display_pwd="~${PWD#"$HOME"}"
  fi

  # Non-printing sequences must be wrapped in \[ \] for bash.
  local c_reset='\[\033[0m\]'
  local c_dim='\[\033[2m\]'
  local c_dim_bold='\[\033[2;1m\]'

  # Without promptvars, bash never expands PS1, so text can be embedded as is.
  local embed=false
  shopt -q promptvars || embed=true

  # Git segment (optional).
  local git_line=""
  out="$(__dotfiles_prompt_git 2> '/dev/null')" || out=""
  if [[ -n "$out" ]]; then
    local IFS=$'\t'
    read -r state br <<< "$out"
    __dotfiles_prompt_branch="$br"

    local branch_text="\${__dotfiles_prompt_branch}"
    [[ "$embed" == true ]] && branch_text="${br//\\/\\\\}"

    local c_green='\[\033[32m\]'
    local c_orange='\[\033[33m\]'
    local c_red='\[\033[31m\]'
    local c_bold='\[\033[1m\]'

    case "$state" in
      0) git_line="${c_dim}└── ${c_dim_bold}${branch_text}${c_reset}" ;;
      1) git_line="${c_dim}└── ${c_reset}${c_green}${c_bold}${branch_text}${c_reset}" ;;
      2) git_line="${c_dim}└── ${c_reset}${c_orange}${c_bold}${branch_text}${c_reset}" ;;
      3) git_line="${c_dim}└── ${c_reset}${c_red}${c_bold}${branch_text}${c_reset}" ;;
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

    __dotfiles_prompt_parent="$pwd_parent"
    __dotfiles_prompt_tail="$pwd_tail"

    local parent_text="\${__dotfiles_prompt_parent}"
    local tail_text="\${__dotfiles_prompt_tail}"
    if [[ "$embed" == true ]]; then
      parent_text="${pwd_parent//\\/\\\\}"
      tail_text="${pwd_tail//\\/\\\\}"
    fi

    PS1="${sep}${c_dim}${parent_text}${c_reset}${c_dim_bold}${tail_text}${c_reset}"
    [[ -n "$git_line" ]] && PS1+=$'\n'"${git_line}"
    PS1+=$'\n\n'"${c_dim}${sign}${c_reset} "
  fi
}

# If something else already uses PROMPT_COMMAND, append ours.
if [[ -n "${PROMPT_COMMAND-}" ]]; then
  case ";$PROMPT_COMMAND;" in
    *";__dotfiles_prompt_command;"*) : ;;
    *) PROMPT_COMMAND="${PROMPT_COMMAND};__dotfiles_prompt_command" ;;
  esac
else
  PROMPT_COMMAND="__dotfiles_prompt_command"
fi
