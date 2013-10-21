//(function() {
	//"use strict";

	$.translate={
		add: function(dict) {
			if (!$.translate.dictionary[$.translate.module])
				$.translate.dictionary[$.translate.module]={};
			if (!$.translate.dictionary[$.translate.module][$.translate.language])
				$.translate.dictionary[$.translate.module][$.translate.language]={string: {}, regex: {}};
			$.each(dict, function(key, val) {
				if (val instanceof RegExp) {
					$.translate.dictionary[$.translate.module][$.translate.language].regex[key]=val;
				} else {
					$.translate.dictionary[$.translate.module][$.translate.language].string[$.translate.clear(key).toLowerCase()]=$.translate.clear(val);
				}
			});
		},
		clear: function(str) {
			return str.replace(/^[\s!?.:()]*|[\s!?.:()]*$/gi, '');
		},
		textNodes: function(el) {
			return $(el).not('iframe,script,style').contents().andSelf().filter(function() {
				return (this.nodeType===3 || $(this).is('input[value][type!=radio][type!=checkbox]')) && /[a-z]/i.test($.translate.get(this));
			});
		},
		get: function(el) {
			if (el.nodeType===3)
				return el.nodeValue;
			return $(el).attr('value');
		},
		set: function(el, val) {
			if (el.nodeType===3)
				return el.nodeValue=val;
			return $(el).attr('value', val);
		},
		lookup: function(str, module, language) {
			module = module || $.translate.module;
			language = language || $.translate.language;
			var ret=false;
			var value=$.translate.clear(str);
			if ($.translate.dictionary[module] && $.translate.dictionary[module][language]) {
				var translation=$.translate.dictionary[module][language].string[value.toLowerCase()];
				if (translation) {
					var temp=str.replace(value, translation);
					if (value[0].toLowerCase()===value[0])
						return temp[0].toLowerCase()+temp.slice(1)
					return temp[0].toUpperCase()+temp.slice(1);
				}
				$.each($.translate.dictionary[module][language].regex, function(key, val) {
					if (val.test(str)) {
						ret=str.replace(val, key);
						return false;
					}
				});
			}
			if (!ret)
				console.log(value);
			return ret;
		},
		text: function(str, module, language) {
			var result=$.translate.lookup(str, module, language);
			if (result!==false)
				return result;
			return str;
		},
		dictionary: {},
		module: 'default',
		language: 'xx',
		original: 'en'
	};

	$.fn.translate = function(module, language) {
		module = module || $.translate.module;
		language = language || $.translate.language;
		$.translate.textNodes(this).each(function() {
			$(this).untranslate(true);
			if ($(this).data('translateO') || $.translate.clear($.translate.get(this))) {
				if (!$(this).data('translateO'))
					$(this).data('translateO', $.translate.get(this));
				var translation = $(this).data('translateO');
				if (language === $.translate.original || (translation = $.translate.lookup($(this).data('translateO'), module, language)) ) {
					$.translate.set(this, translation);
					$(this).data('translateM', module).data('translateL', language);
				} else $(this).untranslate(true);
			}
		});
		return $(this);
	};

	$.fn.retranslate = function(module_, language_) {
		$.translate.textNodes(this).each(function() {
			if ($(this).data('translateO')) {
				var module = module_ || $(this).data('translateM');
				var language = language_ || $(this).data('translateL');
				var translation = $(this).data('translateO');
				if (language === $.translate.original || (translation = $.translate.lookup($(this).data('translateO'), module, language)) ) {
					$.translate.set(this, translation);
					$(this).data('translateM', module).data('translateL', language);
				}
			}
		});
		return $(this);
	};

	$.fn.untranslate = function(undo) {
		$.translate.textNodes(this).each(function() {
			if (undo && $(this).data('translateO'))
				$.translate.set(this, $(this).data('translateO'));
			$(this).removeData();
		});
	};
//})();