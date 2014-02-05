require 'rubko/controller/signature'

class Rubko; class Controller; module Macros

	[:get, :post, :put, :patch, :delete].each { |method|
		define_method(method) { |*path, df|
			df = instance_method df if Symbol === df
			Signature.new(path, df).tap { |sig|
				(@verbs[method][sig.size] ||= []) << sig
			}
		}
	}

	# REST (Rails like)

	def index(method)
		get nil, method
	end

	def create(method)
		post nil, method
	end


	def show(method)
		get Integer, method
	end

	def update(method)
		put patch Integer, method
	end

	def destroy(method)
		delete Integer, method
	end

end; end; end