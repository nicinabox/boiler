source /etc/bundlerc

if ! grep -Fxq "source /etc/bundlerc" /etc/profile; then
  echo 'source /etc/bundlerc' >> /etc/profile
fi

if [[ `gem -v` < "2.2" ]]; then
  gem update --system
fi

if [[ `command -v bundle` == "" ]]; then
  gem install bundler
fi

