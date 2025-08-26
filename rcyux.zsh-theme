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

# Asegúrate de tener los colores de zsh cargados en tu .zshrc:
# autoload -U colors && colors

function get_current_dir() {
  local wd="$PWD"
  local colored_path=""

  if [[ $wd == "$HOME" || $wd == $HOME/* ]]; then
    colored_path="%{$fg_bold[green]%}~%{$reset_color%}"
    local rest="${wd#$HOME}"
    if [[ -n $rest ]]; then
      local -a parts
      parts=("${(@s:/:)${rest#/}}")
      local sep="%{$fg[blue]%}/%{$reset_color%}"
      for part in "${parts[@]}"; do
        [[ -z $part ]] && continue
        colored_path+="$sep%{$fg_bold[cyan]%}$part%{$reset_color%}"
      done
    fi
    echo "$colored_path"
    return
  fi

  if [[ $wd == "/" ]]; then
    echo "%{$fg[red]%}/%{$reset_color%}%{$fg_bold[red]%}root%{$reset_color%}"
    return
  fi

  local -a parts
  parts=("${(@s:/:)wd}")

  colored_path="%{$fg[red]%}/%{$reset_color%}"

  local first=true
  for part in "${parts[@]}"; do
    [[ -z $part ]] && continue
    if $first; then
      colored_path+="%{$fg_bold[cyan]%}$part%{$reset_color%}"
      first=false
    else
      colored_path+="%{$fg[blue]%}/%{$reset_color%}%{$fg_bold[cyan]%}$part%{$reset_color%}"
    fi
  done

  echo "$colored_path"
}

function virtualenv_info() {
  [[ -n ${VIRTUAL_ENV} ]] || return
  echo "${ZSH_THEME_VIRTUALENV_PREFIX}${VIRTUAL_ENV:t:gs/%/%%}${ZSH_THEME_VIRTUALENV_SUFFIX}"
}

function get_current_time() {
  echo "   $(matte_grey '%D{%d/%m %T}')   "
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

function get_space() {
  local size=$1
  local space="—"
  while [[ $size -gt 0 ]]; do
    space="$space—"
    let size=$size-1
  done
  echo "$(matte_grey $space)"
}

function matte_grey() {
  echo "%{$FG[240]%}$1%{$reset_color%}"
}

function prompt_len() {
  emulate -L zsh
  local -i COLUMNS=${2:-COLUMNS}
  local -i x y=${#1} m
  if (( y )); then
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ))
    done
    while (( y > x + 1 )); do
      (( m = x + (y - x) / 2 ))
      (( ${${(%):-$1%$m(l.x.y)}[-1]} = m ))
    done
  fi
  echo $x
}

function prompt_header() {
  local left_prompt="$(get_current_dir) $(git_branch)"
  local right_prompt="$(get_current_time)"
  local prompt_len=$(prompt_len $left_prompt$right_prompt)
  local space_size=$(( $COLUMNS - $prompt_len - 1 ))
  local space=$(get_space $space_size)

  print -rP "$left_prompt$space$right_prompt"
  # print -rP "$left_prompt$right_prompt"
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
