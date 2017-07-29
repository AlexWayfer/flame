# frozen_string_literal: true

module Flame
	## Declaration of `.with_actions` method and concomitants
	class Controller
		class << self
			## Re-define public instance method from parent
			## @example Inherit controller with parent actions by method
			##   class MyController < BaseController.with_actions
			##   end
			## @example Define actions from module in controller
			##   class MyController < BaseController
			##     include with_actions Module1
			##     include with_actions Module2
			##     ....
			##   end
			def with_actions(mod = nil)
				return mod.extend(ModuleActions) if mod
				@with_actions ||= Class.new(self) { extend ParentActions }
			end
		end

		## Extension for modules whose public methods will be defined as actions
		## via including
		module ModuleActions
			def included(ctrl)
				public_instance_methods.each do |meth|
					ctrl.send :define_method, meth, public_instance_method(meth)
				end
			end
		end

		## Module for public instance methods re-defining from superclass
		## @example Inherit controller with parent actions without forbidden
		## actions by `extend`
		##   class MyController < BaseController
		##     FORBIDDEN_ACTIONS = %[foo bar baz].freeze
		##     extend Flame::Controller::ParentActions
		##   end
		module ParentActions
			def inherited(ctrl)
				ctrl.define_parent_actions
			end

			def self.extended(ctrl)
				ctrl.define_parent_actions
			end

			def define_parent_actions
				(superclass.actions - self::FORBIDDEN_ACTIONS).each do |public_method|
					um = superclass.public_instance_method(public_method)
					define_method public_method, um
				end
			end
		end
	end
end
