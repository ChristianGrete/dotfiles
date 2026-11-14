# shellcheck disable=SC2016 # literal $DOTFILES in expected output

# Tests for the libexec tooling. Each test works on a throwaway clone or copy
# of the repository; nothing touches the real one or the user's home.

# Clone, commit the current libexec/ on main, and sign with a throwaway key.
__tooling_repo() {
  command -v 'git' > '/dev/null' 2>&1 || skip 'needs git.'
  command -v 'ssh-keygen' > '/dev/null' 2>&1 || skip 'needs ssh-keygen.'

  isolate_git
  ssh-keygen -q -t ed25519 -N '' -f "$TEST_TMP/key"
  git config --global gpg.format 'ssh'
  git config --global user.signingkey "$TEST_TMP/key"
  git config --global commit.gpgsign true

  git clone -q "$TEST_REPO" 'repo'
  cp "$TEST_REPO/libexec/"* 'repo/libexec/'
  cd 'repo' || fail 'cd failed.'
  git checkout -q -B 'main'
  git add -A 'libexec'
  git commit -q --allow-empty -m 'test: current libexec'

  start_commit="$(git rev-parse HEAD)"
  start_version="$(cat 'VERSION')"
  IFS='.' read -r major minor patch < 'VERSION'
  next_version="$major.$minor.$((patch + 1))"
}

# The branch, VERSION, and the working tree are as before the release.
__tooling_assert_untouched() {
  assert_eq "$(git rev-parse HEAD)" "$start_commit"
  assert_eq "$(cat 'VERSION')" "$start_version"
  assert_eq "$(git status --porcelain --untracked-files=no)" ''
}

# Copy libexec/, src/, and VERSION without git (the build version is unknown).
__tooling_copy() {
  mkdir 'repo'
  cp -R "$TEST_REPO/libexec" "$TEST_REPO/src" "$TEST_REPO/VERSION" 'repo/'
  export GIT_CEILING_DIRECTORIES="$TEST_TMP"
}

# Usage: __tooling_install_dir HOME
__tooling_install_dir() {
  if [[ "$(uname -s)" == 'Darwin' ]]; then
    printf '%s' "$1/Library/Application Support/com.christiangrete.dotfiles"
  else
    printf '%s' "$1/.local/share/com.christiangrete.dotfiles"
  fi
}

test_build_derives_etc_and_home_and_keeps_opt_and_var() {
  __tooling_copy
  mkdir -p 'repo/build/bash/etc' 'repo/build/bash/opt/provider' 'repo/build/bash/var/git'
  touch 'repo/build/bash/etc/stale.sh' 'repo/build/bash/var/git/kept'

  repo/libexec/build > '/dev/null' || fail 'build failed.'

  bootstrap="$(cat 'repo/build/bash/etc/bootstrap.sh')"
  assert_contains "$bootstrap" "DOTFILES_SHELL='bash'"
  assert_contains "$bootstrap" "DOTFILES_VERSION='unknown'"
  [[ "$bootstrap" != *__DOTFILES_* ]] || fail 'a placeholder is left.'
  assert_contains "$(cat 'repo/build/zsh/etc/bootstrap.sh')" "DOTFILES_SHELL='zsh'"
  [[ ! -e 'repo/build/bash/etc/stale.sh' ]] || fail 'etc/ was not rebuilt.'
  [[ -e 'repo/build/bash/var/git/kept' ]] || fail 'var/ content was removed.'
  [[ -d 'repo/build/bash/opt/provider' ]] || fail 'opt/ content was removed.'
}

test_dist_builds_from_scratch_with_the_semver() {
  __tooling_copy
  printf '1.2.3\n' > 'repo/VERSION'
  mkdir -p 'repo/dist/bash/var'
  touch 'repo/dist/bash/var/stale'

  repo/libexec/dist > '/dev/null' || fail 'dist failed.'

  assert_contains "$(cat 'repo/dist/bash/etc/bootstrap.sh')" "DOTFILES_VERSION='1.2.3'"
  assert_contains "$(cat 'repo/dist/zsh/etc/bootstrap.sh')" "DOTFILES_SHELL='zsh'"
  [[ ! -e 'repo/dist/bash/var/stale' ]] || fail 'dist was not rebuilt from scratch.'
}

test_dist_rejects_an_invalid_version() {
  __tooling_copy
  printf '1.2\n' > 'repo/VERSION'

  out="$(repo/libexec/dist 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'dist: VERSION is not a plain SemVer (X.Y.Z): 1.2'
}

test_bump_increments_each_level() {
  __tooling_copy
  printf '1.2.3\n' > 'repo/VERSION'

  out="$(repo/libexec/bump patch)"
  assert_eq "$out" 'bump: 1.2.3 -> 1.2.4'
  repo/libexec/bump minor > '/dev/null'
  assert_eq "$(cat 'repo/VERSION')" '1.3.0'
  repo/libexec/bump major > '/dev/null'
  assert_eq "$(cat 'repo/VERSION')" '2.0.0'
}

test_bump_validates_arguments_and_version() {
  __tooling_copy

  out="$(repo/libexec/bump 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'usage: make bump LEVEL=patch|minor|major'

  printf 'x\n' > 'repo/VERSION'
  out="$(repo/libexec/bump patch 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'bump: VERSION is not a plain SemVer (X.Y.Z): x'
}

test_changelog_lists_commits_since_the_last_tag_without_bumps() {
  __tooling_repo
  git tag 'v9.0.0'
  git commit -q --allow-empty -m 'feat: after the tag'
  git commit -q --allow-empty -m 'bump(version): 9.0.1'

  assert_eq "$(libexec/changelog)" "- feat: after the tag ($(git rev-parse --short HEAD~1))"
}

test_install_links_the_prefix_and_prints_the_setup() {
  __tooling_copy
  mkdir -p 'repo/build/zsh' 'home'
  target="$(__tooling_install_dir "$PWD/home")"

  out="$(HOME="$PWD/home" XDG_DATA_HOME='' repo/libexec/install zsh)"
  assert_eq "$?" '0'
  assert_eq "$(readlink "$target")" "$PWD/repo/build/zsh"
  assert_contains "$out" 'install: add to your ~/.zshrc:'
  assert_contains "$out" '  . "$DOTFILES/home/rc.zsh"'

  HOME="$PWD/home" XDG_DATA_HOME='' repo/libexec/install zsh > '/dev/null' ||
    fail 'a second install failed.'
  assert_eq "$(readlink "$target")" "$PWD/repo/build/zsh"
}

test_install_refuses_to_replace_a_real_directory() {
  __tooling_copy
  mkdir -p 'repo/build/bash'
  target="$(__tooling_install_dir "$PWD/home")"
  mkdir -p "$target"

  out="$(HOME="$PWD/home" XDG_DATA_HOME='' repo/libexec/install bash 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" "install: not a symlink, remove it first: $target"
  [[ -d "$target" && ! -L "$target" ]] || fail 'the directory was replaced.'
}

test_install_validates_shell_and_build() {
  __tooling_copy

  out="$(HOME="$PWD/home" repo/libexec/install fish 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'install: unsupported shell: fish'

  out="$(HOME="$PWD/home" XDG_DATA_HOME='' repo/libexec/install bash 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'install: build/bash not found; run "make build" first.'
}

test_release_validates_arguments() {
  __tooling_copy

  out="$(repo/libexec/release 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'usage: make release LEVEL=patch|minor|major'
}

test_release_refuses_other_branches() {
  __tooling_repo
  git checkout -q -b 'feature'
  start_commit="$(git rev-parse HEAD)"

  out="$(libexec/release patch 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'release: releases are cut from main only, current branch: feature'
  __tooling_assert_untouched
}

test_release_refuses_uncommitted_changes() {
  __tooling_repo
  printf 'local edit\n' >> 'README.md'

  out="$(libexec/release patch 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'release: uncommitted changes, commit or stash them first.'
  assert_eq "$(tail -n 1 'README.md')" 'local edit'
}

test_release_refuses_an_existing_tag_and_rolls_back() {
  __tooling_repo
  git tag "v$next_version"

  out="$(libexec/release patch 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" "release: tag already exists: v$next_version"
  assert_contains "$out" 'release: failed, rolled back to '
  __tooling_assert_untouched
}

test_release_rolls_back_when_signing_fails() {
  __tooling_repo
  git config commit.gpgsign false
  git config user.signingkey '/nonexistent'

  out="$(libexec/release patch 2>&1)" && fail 'the release succeeded.'
  assert_contains "$out" 'release: failed, rolled back to '
  __tooling_assert_untouched
  assert_eq "$(git tag -l "v$next_version")" ''
}

test_release_tags_dist_and_keeps_the_branch_source_only() {
  __tooling_repo

  libexec/release patch > '/dev/null' 2>&1 || fail 'the release failed.'

  assert_eq "$(git log -1 --format='%s')" "bump(version): $next_version"
  assert_eq "$(git ls-tree --name-only "v$next_version" dist)" 'dist'
  assert_eq "$(git ls-tree --name-only HEAD dist)" ''
  assert_eq "$(git status --porcelain --untracked-files=no)" ''
}

test_stamp_keeps_backslashes_in_subjects() {
  __tooling_repo
  git commit -q --allow-empty -m 'fix: handle C:\temp and a\tb'

  libexec/stamp '9.9.9' > '/dev/null' || fail 'stamp failed.'

  assert_contains "$(cat 'CHANGELOG.md')" '- fix: handle C:\temp and a\tb'
}

test_clean_keeps_hidden_files_and_dangling_links() {
  mkdir -p 'repo/libexec' 'repo/build/bash/opt' 'repo/build/bash/var' 'repo/build/zsh/var'
  cp "$TEST_REPO/libexec/clean" 'repo/libexec/'
  touch 'repo/build/bash/var/README.md' 'repo/build/bash/var/.keep' 'repo/build/zsh/var/README.md'
  ln -s '/nonexistent' 'repo/build/bash/opt/link'

  repo/libexec/clean > '/dev/null' || fail 'clean failed.'

  [[ -e 'repo/build/bash/var/.keep' ]] || fail 'a hidden file was removed.'
  [[ -L 'repo/build/bash/opt/link' ]] || fail 'a dangling link was removed.'
  [[ ! -e 'repo/build/zsh' ]] || fail 'an otherwise empty prefix was kept.'
}
