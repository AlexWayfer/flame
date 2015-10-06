require_relative './request'
require_relative './router'

module Flame
	## Core class, like Framework::Application
	class Application
		## Framework configuration
		def self.config
			@config ||= {}
		end

		def config
			self.class.config
		end

		include Flame::Request

		def self.inherited(app)
			root_dir = File.dirname(caller[0].split(':')[0])
			app.config.merge!(
				root_dir: root_dir,
				public_dir: File.join(root_dir, 'public'),
				views_dir: File.join(root_dir, 'views')
			)
		end

		## Init function
		def call(env)
			new_request(env)
			body = catch :halt do
				try_static
				try_route
			end
			[status, headers, [body]]
		end

		def self.mount(ctrl, path = nil, &block)
			router.add_controller(ctrl, path, block)
		end

		private

		## Router for routing
		def self.router
			@router ||= Flame::Router.new
		end

		def router
			self.class.router
		end

		def try_route
			route = router.find_route(
				method: params['_method'] || request.request_method,
				path: request.path_info
			)
			halt 404 unless route
			status 200
			route.execute(self)
		end

		def try_static
			static_file = File.join(config[:public_dir], request.path_info)
			p static_file
			return nil unless File.exist?(static_file) && File.file?(static_file)
			return_static(static_file)
		end

		def return_static(file)
			since = @env['HTTP_IF_MODIFIED_SINCE']
			file_time = File.mtime(file)
			halt 304 if since && Time.httpdate(since).to_i >= file_time.to_i
			headers.merge!(
				'Content-Type' => file_mime_type(file),
				'Last-Modified' => file_time.httpdate
				# 'Content-Disposition' => 'attachment;' \
				#	"filename=\"#{File.basename(static_file)}\"",
				# 'Content-Length' => File.size?(static_file).to_s
			)
			halt 200, File.read(file), headers
		end

		def file_mime_type(file)
			Rack::Mime.mime_type(File.extname(file))
		end
	end
end
