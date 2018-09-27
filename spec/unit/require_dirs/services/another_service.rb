# frozen_string_literal: true

require_relative 'regular/all'

module RequireDirs
	module Services
		class AnotherService < Services::Base
			@mailer = RequireDirs::Mailer::SomeMailer

			@regular_all = RequireDirs::Services::Regular::All
		end
	end
end
