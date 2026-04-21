# Shared npm helpers.
# Wraps npm install/add so successful installs still report the real upstream latest
# and the version npm actually installed after policies like min-release-age apply.

npm_real() {
  command npm "$@"
}

_npm_install_report_enabled() {
  case "${NPM_INSTALL_REPORT:-1}" in
    0|false|FALSE|no|NO)
      return 1
      ;;
  esac

  command -v node >/dev/null 2>&1 || return 1
  [ -f "$HOME/scripts-prompts-config/universal/npm-install-aware.mjs" ] || return 1
  return 0
}

npm() {
  if [ -n "${NPM_INSTALL_REPORT_BYPASS-}" ] || ! _npm_install_report_enabled; then
    command npm "$@"
    return $?
  fi

  case "${1-}" in
    install|i|add)
      command node "$HOME/scripts-prompts-config/universal/npm-install-aware.mjs" "$@"
      ;;
    *)
      command npm "$@"
      ;;
  esac
}
