require 'logger'

RestClient.log = Logger.new(STDERR)
