# frozen_string_literal: true

include :bundler, static: true

subtool_apply do
	include :exec, exit_on_nonzero_status: true, log_level: Logger::UNKNOWN unless include? :exec
end

require 'gem_toys'
expand GemToys::Template

alias_tool :g, :gem
