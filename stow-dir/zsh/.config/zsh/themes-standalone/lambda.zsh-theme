# Lambda V ZHS theme.

function git_prompt_info() {
  local ref
  if [[ "$(command git config --get oh-my-zsh.hide-status 2>/dev/null)" != "1" ]]; then
    ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
    ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
    echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$ZSH_THEME_GIT_PROMPT_SUFFIX"
  fi
}

function node_version_info() {
  # Show NODE status only for JS-specific folders
  if [[ -f package.json || -d node_modules || -f *.js ]]; then
    echo "⬢ $(node -v) "
  fi
}

PROMPT='%F{247}[%D{%H:%M:%S}%b]%f (%n%) %F{045}$(virtualenv_prompt_info)%f %F{green}$(node_version_info)%f%F{106}%~ %f$(git_prompt_info) $(git_prompt_status)%{$reset_color%}
%(?.%{$fg[white]%}.%{$fg[red]%})λ%{$reset_color%} > '

ZSH_THEME_GIT_PROMPT_PREFIX="%F{011}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"

ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[red]%}%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[red]%}%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[cyan]%}%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[cyan]%}%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[red]%}%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%}%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[magenta]%}%{$reset_color%} "

