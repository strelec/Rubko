class Rubko; class Controller; class Signature

	def initialize(path, method)
		case method
		when self.class
			@method = method.method
			@path = method.path if path.empty?
		when UnboundMethod
			@method = method
			@path = [method.name] if path.empty?
		else
			raise "Method mapping requires a method definition."
		end
		@path ||= path.compact.map { |el|
			if Regexp === el
				/\A#{el}\z/
			else
				el
			end
		}
	end

	attr_accessor :method, :path

	def size
		path.size
	end

	def totalSize
		arity = method.arity
		arity = -1*arity - 1 if arity < 0
		size + arity
	end

	INTEGER = /\A[1-9]\d*\z/
	FLOAT = /\A\d+(?:\.\d+)?\z/

	def match(req)
		matches = []

		i = 0
		path.each { |el|
			case el
			when Regexp
				match = req[i].match el
				return unless match
				matches.concat match[1..-1]
			when Class
				if el == String
					matches << req[i]
				elsif el == Integer
					return unless INTEGER =~ req[i]
					matches << req[i].to_i
				elsif el == Float
					return unless FLOAT =~ req[i]
					matches << req[i].to_f
				else
					begin
						obj = el.new req[i]
						matches << obj
					rescue
						return
					end
				end
			when String
				return if el != req[i]
			when Symbol
				return if el.to_s != req[i]
			else
				raise "Unknown mapping parameter: #{el}"
			end
			i += 1
		}
		matches.concat req[i..-1]
	end

	def call(obj, params)
		method.bind(obj).call(*params)
	end

end; end; end