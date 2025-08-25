export VIRTUAL_ENV_DISABLE_PROMPT=1

_PROMPT_PREFIX_='%B❯%b'
_PROMPT_STATUS_='%(?:%{$fg_bold[green]%}$_PROMPT_PREFIX_:%{$fg_bold[red]%}$_PROMPT_PREFIX_)'
_VIRTUALENV_INFO_='$(virtualenv_info)'


ZSH_THEME_VIRTUALENV_PREFIX="%{$FG[116]%}("
ZSH_THEME_VIRTUALENV_SUFFIX=") %{$reset_color%}"

ZSH_THEME_GIT_PREFIX="%{$fg_bold[blue]%}(%{$fg[red]%}"
ZSH_THEME_GIT_SUFFIX="%{$fg_bold[blue]%})%{$reset_color%} "
ZSH_THEME_GIT_DIRTY=" %{$fg[yellow]%}✗"
ZSH_THEME_GIT_CLEAN=" %{$fg[green]%}✔"

function postcmd_newline() {
  # add a newline after every prompt except the first line 
  precmd() {
    precmd() {
      print "" 
    }
  } 
}

function get_current_dir() {
  local dir="${PWD/#$HOME/~}"

  local colored_path=""
  
  if [[ $dir == "~"* ]]; then
    # If home directory, replace with ~
    colored_path="%{$fg_bold[green]%}~%{$reset_color%}"
    dir="${dir:1}"
  elif [[ $dir == "/" ]]; then
    # If Root directory replace with /
    echo "%{$fg[cyan]%}/%{$reset_color%}"
    return
  else
    # Else start without anything
  fi

  # Split the remaining path by /
  local IFS='/'
  local parts=("${(@s:/:)dir}")

  for part in "${parts[@]}"; do
    [[ -z $part ]] && continue
    colored_path+="%{$fg[blue]%}/%{$reset_color%}%{$fg_bold[cyan]%}$part%{$reset_color%}"
  done


  colored_path="${colored_path%/}"

  echo "$colored_path"
}

function virtualenv_info() {
  [[ -n ${VIRTUAL_ENV} ]] || return
  echo "${ZSH_THEME_VIRTUALENV_PREFIX}${VIRTUAL_ENV:t:gs/%/%%}${ZSH_THEME_VIRTUALENV_SUFFIX}"
}

function get_current_time() {
  echo "$(matte_grey '%D{%d/%m %T}')"
}

function git_branch() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  local state=""

  if [[ -n $branch ]]; then
    if git rev-parse --verify HEAD >/dev/null 2>&1; then
      # Repository has commits, check for changes
      if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        state="$ZSH_THEME_GIT_DIRTY"
      else
        state="$ZSH_THEME_GIT_CLEAN"
      fi
    else
      # Empty repository, no commits yet
      state=" %{$fg[yellow]%}⚠ no commits%{$fg[blue]%}"
    fi
  else
    # Detached HEAD with at least one commit
    if git rev-parse --verify HEAD >/dev/null 2>&1; then
      branch="detached: $(git rev-parse --short HEAD 2>/dev/null)"
      if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        state="$ZSH_THEME_GIT_DIRTY"
      else
        state="$ZSH_THEME_GIT_CLEAN"
      fi
    else
      # Empty repository with no branch
      branch="no branch"
      state=" %{$fg[yellow]%}⚠ no commits%{$fg[blue]%}"
    fi
  fi

  if [[ -n $branch ]]; then
    echo "${ZSH_THEME_GIT_PREFIX}${branch}${state}${ZSH_THEME_GIT_SUFFIX}"
  fi
}

function matte_grey() {
  echo "%{$FG[240]%}$1%{$reset_color%}"
}

function prompt_header() {
  print -rP "$(get_current_dir) $(git_branch) $(get_current_time)"
}

postcmd_newline
alias clear="clear; postcmd_newline"

autoload -U add-zsh-hook
add-zsh-hook precmd prompt_header
setopt prompt_subst
ZLE_RPROMPT_INDENT=0

PROMPT="$_VIRTUALENV_INFO_$_PROMPT_STATUS_ "

autoload -U add-zsh-hook
add-zsh-hook precmd prompt_header
