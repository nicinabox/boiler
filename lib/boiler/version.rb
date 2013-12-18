module Boiler
  config = JSON.parse File.read "boiler.json"

  VERSION = config['version']
end
