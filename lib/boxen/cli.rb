require "boxen/config"
require "boxen/flags"
require "boxen/postflight"
require "boxen/preflight"
require "boxen/puppeteer"

module Boxen
  class CLI
    attr_reader :config
    attr_reader :flags
    attr_reader :puppet

    def initialize(config, flags)
      @config = config
      @flags  = flags
      @puppet = Boxen::Puppeteer.new @config
    end

    def run

      # --env prints out the current BOXEN_ env vars.

      exec "env | grep ^BOXEN_ | sort" if flags.env?

      # --help prints some CLI help and exits.

      abort "#{flags}\n" if flags.help?

      # --projects prints a list of available projects and exits.

      if flags.projects?
        config.projects.each do |project|
          prefix = project.installed? ? "*" : " "
          puts "#{prefix} #{project.name}"
        end

        exit
      end

      0 # FIX: puppet exit code
    end

    # Run Boxen by wiring together the command-line flags, config,
    # preflights, Puppet execution, and postflights. Returns Puppet's
    # exit code.

    def self.run(*args)
      config = Boxen::Config.load
      flags  = Boxen::Flags.new args

      # Apply command-line flags to the config in case we're changing or
      # overriding anything.

      flags.apply config

      # Run the preflight checks.

      Boxen::Preflight.run config

      # Save the config for Puppet (and next time).

      Boxen::Config.save config

      # Make the magic happen.

      code = Boxen::CLI.new(config, flags).run

      # Run the postflight checks.

      Boxen::Postflight.run config if code.zero?

      return code
    end
  end
end
