#!/usr/bin/env puma
# frozen_string_literal: true

require 'yaml'
config = YAML.load_file(File.join(__dir__, 'server.yml'))

is_production = config[:environment] == 'production'

root_dir = File.join(__dir__, '..')
directory root_dir

prune_bundler

exit unless system 'bundle check || bundle install'

rackup 'config.ru'

require 'fileutils'

raise 'Unknown directory for pid files!' unless config[:pids_dir]
pids_dir = File.join root_dir, config[:pids_dir]
FileUtils.mkdir_p pids_dir

pidfile File.join pids_dir, 'puma.pid'
state_path File.join pids_dir, 'puma.state'

raise 'Unknown directory for log files!' unless config[:logs_dir]
log_dir = File.join root_dir, config[:logs_dir]
FileUtils.mkdir_p log_dir

if is_production
	stdout_redirect(
		File.join(log_dir, 'stdout'),
		File.join(log_dir, 'stderr'),
		true # append to file
	)
end

environment config[:environment]

# preload_app! if config['environment'] != 'production'

cores = Etc.nprocessors
workers_count = config[:workers_count] || cores < 2 ? 1 : 2

workers workers_count
worker_timeout is_production ? 15 : 1_000_000
threads 0, config[:threads_count] || 4
daemonize is_production

# bind 'unix://' + File.join(%w[tmp sockets puma.sock])
config[:binds].each do |type, value|
	value = "#{value[:host]}:#{value[:port]}" if type == :tcp
	FileUtils.mkdir_p File.join(root_dir, File.dirname(value)) if type == :unix
	bind "#{type}://#{value}"
end
# activate_control_app 'tcp://0.0.0.0:3000'
