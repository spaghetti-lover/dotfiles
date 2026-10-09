gpup() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  git push --set-upstream origin "$branch"
}

unalias gst 2>/dev/null
zmodload -F zsh/stat b:zstat
zmodload zsh/datetime

_gst_ago() {
  local s=$1
  if   (( s < 60 ));    then print -rn -- "just now"
  elif (( s < 3600 ));  then print -rn -- "$(( s / 60 ))m ago"
  elif (( s < 86400 )); then print -rn -- "$(( s / 3600 ))h ago"
  else                       print -rn -- "$(( s / 86400 ))d ago"
  fi
}

gst() {
  emulate -L zsh

  git rev-parse --is-inside-work-tree &>/dev/null || {
    print -ru2 -- "gst: not a git repository"
    return 1
  }

  local RS=$'\e[0m' DIM=$'\e[2m' B=$'\e[1m' GREEN=$'\e[32m' RED=$'\e[31m'
  local -A hue=(M $'\e[33m' A $'\e[32m' D $'\e[31m' R $'\e[34m' C $'\e[34m' U $'\e[35m' '?' $'\e[2m')

  local base=HEAD label='against HEAD'
  git rev-parse --verify -q HEAD >/dev/null || { base=--cached; label='in the index' }

  local -A plus minus
  local a d p st line
  while IFS=$'\t' read -r a d p; do
    plus[$p]=$a minus[$p]=$d
  done < <(git -c core.quotePath=false diff --numstat --no-renames $base)

  local -a rows
  while IFS= read -r line; do
    st=${line[1,2]} p=${line[4,-1]}
    p=${p#*" -> "}                    # renames: keep the new name
    [[ $p == \"* ]] && p=${(Q)p}      # git quotes odd paths
    if [[ $st == '??' ]]; then
      plus[$p]=$(git diff --numstat --no-index -- /dev/null $p 2>/dev/null | cut -f1)
      minus[$p]=0
    fi
    rows+=("$p"$'\t'"$st")
  done < <(git -c core.quotePath=false status --porcelain -uall)

  local n=${#rows}
  (( n )) || { print -r -- "  ${DIM}working tree clean${RS}"; return 0 }
  rows=("${(@o)rows}")                # by path, so siblings sit together

  local -a dirs names glyphs pstr mstr tstr zs
  local i av dv shown w=0 pw=0 mw=0 ta=0 td=0

  for (( i = 1; i <= n; i++ )); do
    p=${rows[i]%%$'\t'*}
    [[ $p == */* ]] && dirs[i]=${p%/*}/ || dirs[i]=''
  done

  for (( i = 1; i <= n; i++ )); do
    p=${rows[i]%%$'\t'*}
    if [[ -n ${dirs[i]} && ( ${dirs[i]} == ${dirs[i-1]} || ${dirs[i]} == ${dirs[i+1]} ) ]]; then
      names[i]=${p##*/}
      [[ ${dirs[i]} == ${dirs[i+1]} ]] && glyphs[i]='├── ' || glyphs[i]='└── '
    else
      names[i]=$p glyphs[i]=''
    fi
    shown=${glyphs[i]}${names[i]}
    (( ${#shown} > w )) && w=${#shown}

    av=${plus[$p]:-0} dv=${minus[$p]:-0}
    if [[ $av == - ]]; then           # binary
      pstr[i]=bin mstr[i]=''
    else
      (( ta += av, td += dv ))
      (( av )) && pstr[i]="+$av" || pstr[i]=0
      (( dv )) && mstr[i]="-$dv" || mstr[i]=0
    fi
    (( ${#pstr[i]} > pw )) && pw=${#pstr[i]}
    (( ${#mstr[i]} > mw )) && mw=${#mstr[i]}

    tstr[i]=''
    zstat -A zs +mtime -- $p 2>/dev/null && tstr[i]=$(_gst_ago $(( EPOCHSECONDS - zs[1] )))
  done

  local mark c pad pc mc
  print
  for (( i = 1; i <= n; i++ )); do
    [[ -n ${glyphs[i]} && ${dirs[i]} != ${dirs[i-1]} ]] && print -r -- "  ${DIM}${dirs[i]}${RS}"

    st=${rows[i]##*$'\t'}
    mark=''
    for c in "${st[1]}" "${st[2]}"; do mark+="${hue[$c]}$c${hue[$c]:+$RS}"; done

    pad=${(l:$(( w - ${#glyphs[i]} - ${#names[i]} )):):-}
    pc=$DIM; [[ ${pstr[i]} == +* ]] && pc=$GREEN
    mc=$DIM; [[ ${mstr[i]} == -* ]] && mc=$RED

    print -r -- "  $mark ${DIM}${glyphs[i]}${RS}${B}${names[i]}${RS}$pad   ${pc}${(l:pw:):-${pstr[i]}}${RS}  ${mc}${(l:mw:):-${mstr[i]}}${RS}   ${DIM}${tstr[i]}${RS}"
  done

  pc=$DIM; (( ta )) && pc=$GREEN
  mc=$DIM; (( td )) && mc=$RED
  (( n == 1 )) && c='' || c=s
  print
  print -r -- "  ${B}${n}${RS} file$c  ${pc}+${ta}${RS}  ${mc}-${td}${RS}  ${DIM}${label}${RS}"
}
