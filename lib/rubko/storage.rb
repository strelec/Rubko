require 'rubko/plugin'

class Rubko::Storage < Rubko::Plugin
	def values(*path)
		Hash[ keys(*path).map { |key|
			[ key, self[*(path+[key])] ]
		} ]
	end

	def _inspect(path, depth = 0)
		keys(*path).flat_map { |desc|
			child = path + [desc]
			curr = '  '*depth + desc.to_s
			curr << " (#{self[*child]})" if self[*child]
			[curr] + _inspect(child, depth+1)
		}
	end
	private :_inspect

	def inspect(*path)
		_inspect path
	end

	def to_s(*path)
		inspect(path) * "\n"
	end
end