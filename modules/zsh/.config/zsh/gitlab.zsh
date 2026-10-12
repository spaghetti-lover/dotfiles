if command -v glab >/dev/null 2>&1; then
  atlas_gitlab_host=gitlab-eng.dytechlab.com
  export GITLAB_URL="${GITLAB_URL:-https://$atlas_gitlab_host}"

  if [[ -z ${GITLAB_TOKEN:-} ]]; then
    atlas_gitlab_token=$(glab config get token --host "$atlas_gitlab_host" 2>/dev/null)
    [[ -n $atlas_gitlab_token ]] && export GITLAB_TOKEN=$atlas_gitlab_token
    unset atlas_gitlab_token
  fi

  if [[ -z ${CURL_CA_BUNDLE:-} || -z ${GIT_SSL_CAINFO:-} ]]; then
    atlas_gitlab_ca_cert=$(glab config get ca_cert --host "$atlas_gitlab_host" 2>/dev/null)
    if [[ -r $atlas_gitlab_ca_cert ]]; then
      [[ -n ${CURL_CA_BUNDLE:-} ]] || export CURL_CA_BUNDLE=$atlas_gitlab_ca_cert
      [[ -n ${GIT_SSL_CAINFO:-} ]] || export GIT_SSL_CAINFO=$atlas_gitlab_ca_cert
    fi
    unset atlas_gitlab_ca_cert
  fi

  unset atlas_gitlab_host
fi
