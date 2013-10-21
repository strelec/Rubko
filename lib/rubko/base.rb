require 'date'
require 'json'

class Rubko
	module Base
		def initialize(parent = nil)
			@parent = parent
			finalizers << self if @parent
			@plugins = {}
			puts "#{self.class} initialized." unless production?
		end

		def init(*) end
		def finalize(*) end

		attr_accessor :parent

		def loadFile(name)
			require(name) || true
		rescue LoadError
			false
		end

		def camelize(array)
			array.map { |x|
				x.to_s.downcase.capitalize
			}.join
		end
		def uncamelize(str)
			str.to_s.split(/(?=[A-Z])/).map(&:downcase)
		end

		def load(what, name, *args)
			Kernel.const_get(camelize [*[*name].reverse, what]).
				new(self).tap { |x| x.init(*args) }
		end
		private :load

		def loadPlugin(name, *args)
			require 'rubko/plugin'

			process = -> search, range, proc=nil {
				p = Dir[search].sort_by { |x|
					x.split('/').size
				}.first
				if p
					loadFile p
					p[range].split '/'
				else
					proc.call if proc
				end
			}

			path = uncamelize(name).reverse * '/'
			name = process.call "./plugins/**/#{path}.rb", 10..-4, -> {
				d = __dir__
				process.call "#{d}/plugins/**/#{path}.rb", (d.size+9)..-4
			}
			return false unless name

			load(:plugin, name, *args).tap { |plugin|
				loadFile "./config/#{name * '/'}.rb"
			}
		end

		def loadController(name, *args)
			require 'rubko/controller'
			return false unless loadFile "./controllers/#{name}.rb"
			load :controller, name, *args
		end

		def loadModel(name, *args)
			require 'rubko/model'
			return false unless loadFile "./models/#{name}.rb"
			load :model, name, *args
		end

		def loadView(*name)
			if production?
				template = memory[:views, name]
			end
			unless template
				fileName = 'views/'+name.join('/')+'.erb'
				if File.exists? fileName
					require 'erb'
					template = ERB.new File.read(fileName)
				else
					fileName = 'views/'+name.join('/')+'.haml'
					return unless File.exists? fileName
					require 'haml'
					template = Haml::Engine.new File.read(fileName), ugly: true, remove_whitespace: true
				end
				memory[:views, name] = template if production?
				puts "Template #{name * '/'} initialized."
			end

			case template.class.to_s
			when 'ERB'
				template.result binding
			when 'Haml::Engine'
				template.render binding
			end
		end

		def method_missing(name, *args)
			if @plugins && @plugins[name]
				@plugins[name]
			elsif parent
				parent.__send__ name, *args
			else
				@plugins[name] = loadPlugin(name) || super
			end
		end

		def httpGet(url)
			require 'net/http'
			Net::HTTP.get_response(URI.parse url).body
		end

		def jsonParse(resource)
			JSON.parse resource, symbolize_names: true
		end
	end
end