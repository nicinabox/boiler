if [[ `command -v trolley` == "" ]]; then
  wget -qO- --no-check-certificate https://raw.github.com/nicinabox/trolley/master/install.sh | sh -
fi

source /etc/bundlerc

if ! grep -Fxq "source /etc/bundlerc" /etc/profile; then
  echo 'source /etc/bundlerc' >> /etc/profile
fi

if [[ `gem -v` < "2.1" ]]; then
  gem update --system
fi

if [[ `command -v bundle` == "" ]]; then
  gem install bundler
fi

bundle install --gemfile=/usr/local/boiler/Gemfile
