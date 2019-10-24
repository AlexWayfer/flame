# frozen_string_literal: true

require 'gorilla_patch/inflections'

## Base module
module Flame
	using GorillaPatch::Inflections

	%i[Config Application Controller VERSION]
		.each do |constant_name|
			autoload(
				constant_name, "#{__dir__}/flame/#{constant_name.to_s.underscore}"
			)
		end
end
