#!/usr/bin/env puma
# frozen_string_literal: true

require 'yaml'
config = YAML.load_file(File.join(__dir__, 'server.yml'))

environment = ENV['RACK_ENV'] || config[:environment]
env_config = config[environment]

root_dir = File.join(__dir__, '..')
directory root_dir

prune_bundler

rackup 'config.ru'

require 'fileutils'

raise 'Unknown directory for pid files!' unless env_config[:pids_dir]
pids_dir = File.join root_dir, env_config[:pids_dir]
FileUtils.mkdir_p pids_dir

pidfile File.join pids_dir, env_config[:pid_file]
state_path File.join pids_dir, 'puma.state'

raise 'Unknown directory for log files!' unless env_config[:logs_dir]
log_dir = File.join root_dir, env_config[:logs_dir]
FileUtils.mkdir_p log_dir

if env_config[:daemonize]
	stdout_redirect(
		File.join(log_dir, 'stdout'),
		File.join(log_dir, 'stderr'),
		true # append to file
	)
end

environment environment

# preload_app! if config['environment'] != 'production'

cores = Etc.nprocessors
workers_count = env_config[:workers_count] || (cores < 2 ? 1 : 2)

workers workers_count
worker_timeout env_config[:daemonize] ? 15 : 1_000_000
threads 0, env_config[:threads_count] || 4
daemonize env_config[:daemonize]

# bind 'unix://' + File.join(%w[tmp sockets puma.sock])
env_config[:binds].each do |type, value|
	value = "#{value[:host]}:#{value[:port]}" if type == :tcp
	FileUtils.mkdir_p File.join(root_dir, File.dirname(value)) if type == :unix
	bind "#{type}://#{value}"
end
# activate_control_app 'tcp://0.0.0.0:3000'
