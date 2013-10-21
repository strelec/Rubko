class LogPlugin < Rubko::Plugin

	def init
		@mapper = {
			sql: [:term, :file],
			time: [:term],
			debug: [:term],
		}
		config
	end

	Colors = {
		black: 0,
		red: 1,
		green: 2,
		yellow: 3,
		blue: 4,
		magenta: 5,
		cyan: 6,
		white: 7,
		default: 9,
	}

	def mark(*what)
		insert = what.map(&:to_s).join ';'
		"\033[#{insert}m"
	end

	def color(color = 0, bold = 0)
		mark bold, color+30
	end

	def bg(color = 0)
		mark color+40
	end

	def reset
		mark 0
	end

	def method_missing(name, *params)
		unless @mapper && @mapper.key?(name)
			return super
		end

		clr = name.hash/2%7 + 1
		puts "#{color clr, 1}#{name.to_s.upcase}:#{reset} #{params * ', '}"
	end
end