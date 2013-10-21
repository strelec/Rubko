class UrlPlugin
	def config
		# :ending, :base, :fileBase, :fileTime, :fullPath

		rewrite 'favicon.ico', 'files/img/favicon.png'
	end
end