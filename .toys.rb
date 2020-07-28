# frozen_string_literal: true

include :bundler, static: true

subtool_apply do
	include :exec, exit_on_nonzero_status: true, log_level: Logger::UNKNOWN unless include? :exec
end

require 'gem_toys'
expand GemToys::Template

alias_tool :g, :gem

tool :rspec do
	def run
		exec 'rspec'
	end
end

alias_tool :spec, :rspec
alias_tool :test, :rspec

tool :rubocop do
	def run
		exec 'rubocop'
	end
end
