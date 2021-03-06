module HoboClean

  VERSION = File.read(File.expand_path('../../VERSION', __FILE__)).strip
  @@root = Pathname.new File.expand_path('../..', __FILE__)
  def self.root; @@root; end

  require 'hobo_clean/railtie' if defined?(Rails)

  class Engine < ::Rails::Engine
  end
end
