git config --global --unset commit.template
git config --global --add safe.directory /home/bun/app
git config --global fetch.prune true
git config --global --add --bool push.autoSetupRemote true
git branch --merged|egrep -v '\*|develop|main|master'|xargs git branch -d
git branch --remotes --merged | grep -v "origin/main" | sed -E 's/  origin\/(.*)/\1/' | xargs -I{} git push origin :{}

if gpg --list-secret-keys | grep -q 'sec'; then
  GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | awk '/sec/{print $2}' | cut -d'/' -f2)
  git config --global user.signingkey $GPG_KEY_ID
  git config --global commit.gpgSign true
fi