#!/usr/bin/env zsh
# Lightweight test suite for setup.zsh, .functions and .aliases.
# No dependencies beyond zsh, git and jq. Every test runs against a throwaway $HOME,
# so it is safe to run on your own machine:
#
#   zsh tests/run_tests.zsh
#
# Nothing here touches the network: setup.zsh is only run in --link or --dry-run mode.

emulate -L zsh
setopt err_return no_unset pipe_fail

REPO_DIR="${0:A:h:h}"
SETUP="$REPO_DIR/setup.zsh"
PASS=0
FAIL=0
FAILED_TESTS=()

# ---------------------------------------------------------------- helpers
new_home() {
  TEST_HOME=$(mktemp -d)
}

fail() {
  echo "    assertion failed: $*"
  return 1
}

assert_eq() { [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'${3:+ ($3)}"; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "output does not contain '$2'"; }
assert_not_contains() { [[ "$1" != *"$2"* ]] || fail "output unexpectedly contains '$2'"; }
assert_link_to() {
  [[ -L "$1" ]] || fail "$1 is not a symlink"
  assert_eq "$(readlink "$1")" "$2" "link target of $1"
}
assert_not_exists() { [[ ! -e "$1" && ! -L "$1" ]] || fail "$1 should not exist"; }

# Run setup.zsh with an isolated HOME and no inherited oh-my-zsh variables.
run_setup() {
  env -u ZSH -u ZSH_CUSTOM HOME="$TEST_HOME" zsh "$SETUP" "$@" 2>&1
}

run_test() {
  local name="$1"
  new_home
  if ( "$name" ) >"$TEST_HOME.log" 2>&1; then
    PASS=$((PASS + 1))
    echo "ok   - $name"
  else
    FAIL=$((FAIL + 1))
    FAILED_TESTS+=("$name")
    echo "FAIL - $name"
    sed 's/^/    /' "$TEST_HOME.log"
  fi
  rm -rf "$TEST_HOME" "$TEST_HOME.log"
}

# ---------------------------------------------------------------- setup.zsh
test_no_args_prints_usage() {
  local out
  out=$(run_setup)
  assert_contains "$out" "Usage:"
}

test_help_flag() {
  local out
  out=$(run_setup --help)
  assert_contains "$out" "--dry-run"
}

test_unknown_flag_fails() {
  local out rc=0
  out=$(run_setup --bogus) || rc=$?
  assert_eq "$rc" "1" "exit code"
  assert_contains "$out" "Unknown parameter passed: --bogus"
}

test_dry_run_alone_changes_nothing() {
  # Regression: `./setup.zsh -d` (as documented in README) used to fail with "Unknown parameter"
  local out
  out=$(run_setup -d)
  assert_contains "$out" "Dry run: Linking"
  assert_contains "$out" "Dry run: ZSH="
  assert_eq "$(ls -A "$TEST_HOME")" "" "HOME should be empty after a dry run"
}

test_dry_run_flag_order_does_not_matter() {
  local a b
  a=$(run_setup -d -y)
  b=$(run_setup -y -d)
  assert_eq "$a" "$b"
  assert_eq "$(ls -A "$TEST_HOME")" "" "HOME should be empty after a dry run"
}

test_zsh_mode_dry_run_with_unset_ZSH() {
  # Regression: a fresh machine has no $ZSH and `set -u` crashed setup_ohmyzsh
  local out
  out=$(run_setup -z -d)
  assert_contains "$out" "--keep-zshrc"
  assert_not_contains "$out" "parameter not set"
}

test_link_creates_expected_symlinks() {
  run_setup -l -y >/dev/null
  local f
  for f in .zshrc .aliases .functions .vimrc .p10k.zsh .gitignore_global; do
    assert_link_to "$TEST_HOME/$f" "$REPO_DIR/$f"
  done
}

test_link_skips_repo_only_files() {
  # Regression: setup.zsh itself and gitignore_global (without the dot) used to be linked
  run_setup -l -y >/dev/null
  local f
  for f in setup.zsh README.md omz_install.sh .gitignore tests iterm .github gitignore_global; do
    assert_not_exists "$TEST_HOME/$f"
  done
}

test_link_is_idempotent() {
  run_setup -l -y >/dev/null
  local out
  out=$(run_setup -l -y)
  assert_contains "$out" "Already linked: $TEST_HOME/.zshrc"
  assert_eq "$(ls "$TEST_HOME" | grep -c '\.bak\.' || true)" "0" "no backups on re-run"
}

test_link_backs_up_existing_files() {
  echo "my precious vimrc" >"$TEST_HOME/.vimrc"
  run_setup -l -y >/dev/null
  assert_link_to "$TEST_HOME/.vimrc" "$REPO_DIR/.vimrc"
  local backups=("$TEST_HOME"/.vimrc.bak.*(N))
  assert_eq "${#backups}" "1" "number of .vimrc backups"
  assert_eq "$(cat "${backups[1]}")" "my precious vimrc"
}

test_link_interactive_decline_keeps_file() {
  echo "keep me" >"$TEST_HOME/.vimrc"
  # Answer "n" to every overwrite prompt
  printf 'n\n%.0s' {1..50} | run_setup -l -i >/dev/null
  [[ ! -L "$TEST_HOME/.vimrc" ]] || fail ".vimrc should not have been replaced"
  assert_eq "$(cat "$TEST_HOME/.vimrc")" "keep me"
  # Files that did not exist are still linked without prompting
  assert_link_to "$TEST_HOME/.zshrc" "$REPO_DIR/.zshrc"
}

test_link_works_from_any_directory() {
  ( cd /tmp && run_setup -l -y >/dev/null )
  assert_link_to "$TEST_HOME/.zshrc" "$REPO_DIR/.zshrc"
}

# ---------------------------------------------------------------- .functions / .aliases
# Run a snippet in a fresh zsh with .functions sourced and an isolated HOME.
fn() {
  HOME="$TEST_HOME" zsh -c "source '$REPO_DIR/.functions'; $1" 2>&1
}

test_asdf_set_invalid_args_does_not_kill_shell() {
  # Regression: asdf_set used `exit`, which closes the user's terminal when sourced
  local out
  out=$(fn 'asdf_set bogus terraform 1.0 >/dev/null; echo "rc=$?"; echo survived')
  assert_contains "$out" "rc=1"
  assert_contains "$out" "survived"
}

test_jwtd_decodes_base64url_without_padding() {
  command -v jq >/dev/null || { echo "    (skipped: jq not installed)"; return 0; }
  # Payload chosen so its base64 contains '+' / '/' and needs padding
  local header payload out
  header=$(printf '{"alg":"HS256"}' | base64 | tr '+/' '-_' | tr -d '=\n')
  payload=$(printf '{"n":"??>>~~"}' | base64 | tr '+/' '-_' | tr -d '=\n')
  [[ "$payload" == *[-_]* ]] || fail "test payload should contain base64url chars"
  out=$(fn "jwtd '$header.$payload.sig'")
  assert_contains "$out" '"alg": "HS256"'
  assert_contains "$out" '"n": "??>>~~"'
  assert_contains "$out" "Signature: sig"
}

test_jwtd_requires_argument() {
  local out
  out=$(fn 'jwtd; echo "rc=$?"')
  assert_contains "$out" "Usage: jwtd"
  assert_contains "$out" "rc=1"
}

test_kfile_selects_kubeconfig() {
  # Regression: `find -depth 1` is BSD-only and errored on Linux
  mkdir -p "$TEST_HOME/.kube"
  touch "$TEST_HOME/.kube/a-config" "$TEST_HOME/.kube/b-config"
  local out
  out=$(fn 'echo 1 | kfile')
  assert_contains "$out" "[0]: a-config"
  assert_contains "$out" "KUBECONFIG set to $TEST_HOME/.kube/b-config"
}

test_kfile_rejects_invalid_choice() {
  mkdir -p "$TEST_HOME/.kube"
  touch "$TEST_HOME/.kube/a-config"
  local out
  for choice in 5 abc ""; do
    out=$(fn "echo '$choice' | kfile")
    assert_contains "$out" "Invalid selection!"
  done
}

test_sed_alias_only_when_gsed_present() {
  local out
  out=$(PATH=/usr/bin:/bin zsh -c "source '$REPO_DIR/.aliases'; alias sed || echo no-alias")
  if command -v gsed >/dev/null; then
    assert_contains "$out" "gsed"
  else
    assert_contains "$out" "no-alias"
  fi
}

test_all_shell_files_parse() {
  local f
  for f in setup.zsh .zshrc .aliases .functions .p10k.zsh .spaceship.zsh; do
    zsh -n "$REPO_DIR/$f" || fail "syntax error in $f"
  done
}

# ---------------------------------------------------------------- main
for t in ${(ok)functions[(I)test_*]}; do
  run_test "$t"
done

echo
echo "$PASS passed, $FAIL failed"
(( FAIL == 0 ))
