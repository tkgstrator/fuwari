git config --global --unset commit.template
git config --global --add safe.directory /home/bun/app

git config --global commit.gpgSign true
git config --global --add --bool push.autoSetupRemote true