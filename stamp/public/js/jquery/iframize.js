$.fn.iframize = function() {
	var arg = arguments;
	$(this).each(function() {
		var o=$(this);

		function loadURL(url) {
			$.get(url, {}, function(data) {
				o.html(data);
			});
		}
		if (arg[0])
			loadURL(arg[0]);

		o.find('a').live('click', function() {
			loadURL($(this).attr('href'));
			return false;
		});
		o.find('form').live('submit', function() {
			$.post(url, $(this).find('*').serialize(), function(data) {
				o.html(data);
			});
		});
	});
	return $(this);
};
