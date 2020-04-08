# frozen_string_literal: true

module RequireDirs
	module Services
		class SomethingService < Services::Base
			@mailer = RequireDirs::Mailer::SomeMailer
		end
	end
end
