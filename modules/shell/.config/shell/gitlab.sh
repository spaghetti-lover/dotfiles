# Atlas reads these values from Neovim's inherited environment.
_dotfiles_gitlab_env() {
  local host=gitlab-eng.dytechlab.com
  local ca="$HOME/.config/shell/gitlab-eng-ca.pem"
  local system_ca=/etc/ssl/cert.pem
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
  local bundle="$cache_dir/gitlab-ca-bundle.pem"
  local tmp token

  export GITLAB_URL="${GITLAB_URL:-https://$host}"

  if [[ -z ${GITLAB_TOKEN:-} ]] && command -v glab >/dev/null 2>&1; then
    token=$(glab config get token --host "$host" 2>/dev/null)
    [[ -n $token ]] && export GITLAB_TOKEN=$token
  fi

  # Include the system roots so ordinary curl and Git HTTPS requests keep working.
  if [[ ( -z ${CURL_CA_BUNDLE:-} || -z ${GIT_SSL_CAINFO:-} ) && -r $ca && -r $system_ca ]]; then
    if [[ ! -r $bundle || $ca -nt $bundle || $system_ca -nt $bundle ]]; then
      if mkdir -p "$cache_dir" && tmp=$(mktemp "$cache_dir/.gitlab-ca-bundle.XXXXXX"); then
        if ! { cat "$system_ca" "$ca" > "$tmp" && mv -f "$tmp" "$bundle"; }; then
          rm -f "$tmp"
        fi
      fi
    fi
    if [[ -r $bundle ]]; then
      [[ -n ${CURL_CA_BUNDLE:-} ]] || export CURL_CA_BUNDLE=$bundle
      [[ -n ${GIT_SSL_CAINFO:-} ]] || export GIT_SSL_CAINFO=$bundle
    fi
  fi
}
_dotfiles_gitlab_env
unset -f _dotfiles_gitlab_env
