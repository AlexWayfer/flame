# frozen_string_literal: true

require 'gorilla_patch/slice'

module Flame
	class Controller
		## Module for work with actions
		module Actions
			## Shortcut for not-inherited public methods: actions
			## @return [Array<Symbol>] array of actions (public instance methods)
			def actions
				public_instance_methods(false)
			end

			## Re-define public instance methods (actions) from parent
			## @param actions [Array<Symbol>] Actions for inheritance
			## @param exclude [Array<Symbol>] Actions for excluding from inheritance
			## @example Inherit all parent actions
			##   class MyController < BaseController
			##     inherit_actions
			##   end
			## @example Inherit certain parent actions
			##   class MyController < BaseController
			##     inherit_actions :index, :show
			##   end
			## @example Inherit all parent actions exclude certain
			##   class MyController < BaseController
			##     inherit_actions exclude: %i[edit update]
			##   end
			def inherit_actions(actions = superclass.actions, exclude: [])
				(actions - exclude).each do |public_method|
					um = superclass.public_instance_method(public_method)
					define_method public_method, um
				end
			end

			## Re-define public instance method from module
			## @param mod [Module] Module for including to controller
			## @param exclude [Array<Symbol>] Actions for excluding
			##   from module public instance methods
			## @param only [Array<Symbol>] Actions for re-defining
			##   from module public instance methods
			## @example Define actions from module in controller
			##   class MyController < BaseController
			##     include with_actions Module1
			##     include with_actions Module2
			##     ....
			##   end
			## @example Define actions from module exclude some actions in controller
			##   class MyController < BaseController
			##     include with_actions Module1, exclude: %i[action1 action2 ...]
			##     include with_actions Module2, exclude: %i[action1 action2 ...]
			##     ....
			##   end
			## @example Define actions from module according list in controller
			##   class MyController < BaseController
			##     include with_actions Module1, only: %i[action1 action2 ...]
			##     include with_actions Module2, only: %i[action1 action2 ...]
			##     ....
			##   end
			def with_actions(mod, exclude: [], only: nil)
				Module.new do
					@mod = mod
					@methods_to_define =
						only || (@mod.public_instance_methods(false) - exclude)

					extend ModuleWithActions
				end
			end

			def refined_http_methods
				@refined_http_methods ||= {}
			end

			private

			Flame::Router::HTTP_METHODS.each do |http_method|
				downcased_http_method = http_method.downcase
				define_method(
					downcased_http_method
				) do |action_or_action_path, action = nil|
					action, action_path =
						if action
							[action, action_or_action_path]
						else
							[action_or_action_path, nil]
						end
					refined_http_methods[action] = [downcased_http_method, action_path]
				end
			end

			## Base module for module `with_actions`
			module ModuleWithActions
				using GorillaPatch::Slice

				def included(ctrl)
					ctrl.include @mod

					@methods_to_define.each do |meth|
						ctrl.send :define_method, meth, @mod.public_instance_method(meth)
					end

					return unless @mod.respond_to? :refined_http_methods

					ctrl.refined_http_methods.merge!(
						@mod.refined_http_methods.slice(*@methods_to_define)
					)
				end
			end

			private_constant :ModuleWithActions
		end
	end
end
