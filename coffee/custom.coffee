#------------------------------------
#	Utility Methods
#------------------------------------
isString = (object) -> Object::toString.call(object) is "[object String]"
isFunction = (object) -> Object::toString.call(object) is "[object Function]"
trim = (str) -> str.replace(/^\s+/, '').replace(/\s+$/, '')
defer = (callback) ->
	callback = (->) unless isFunction(callback)
	setTimeout(callback, 1)

# Just some helper methods
sectionize = (input) -> trim(input ? "").toLowerCase().replace(/[^a-z0-9]+/g,"")

#Setup some jquery stuff
$.ajaxSetup( cache: false )

#------------------------------------
# Viewmodels
#------------------------------------
class LayoutViewModel
	@instance = null

	constructor: () ->
		LayoutViewModel.instance = this

		@ContentViewModel = ko.observable({})
		@ContentTemplate = ko.observable()

class DocsViewModel
	@instance = null

	constructor: () ->
		DocsViewModel.instance = this

		@ArticleViewModel = ko.observable({})
		@ArticleTemplate = ko.observable()

#------------------------------------
# Finch Routes
#------------------------------------
Finch.route "/", ({}, callback) -> 
	
	mpq.track "Viewing Home", {}, ->
		$("#content").fadeTo 'fast', 0, ->
			$.get "./pages/home.tmpl", (data) ->
				Layout = LayoutViewModel.instance
				Layout.ContentViewModel(new DocsViewModel)
				Layout.ContentTemplate(data)
				console.log data
				$("#content").fadeTo 'fast', 1, callback
			# END get
		#END fade
	#END track


Finch.route "download", ({}, callback) ->
	
	mpq.track "Viewing Download", {}, ->
		$("#content").fadeTo 'fast', 0, ->
			$.get "./pages/download.tmpl", (data) ->
				Layout = LayoutViewModel.instance
				Layout.ContentViewModel({})
				Layout.ContentTemplate(data)

				$("#content").fadeTo 'fast', 1, callback
			# END get
		#END fade
	#END track

Finch.route "docs", 
	setup: ({}, callback) ->
	
		mpq.track "Viewing Documentation", {}, ->
			$("#content").fadeTo 'fast', 0, ->
				$.get "./pages/docs.tmpl", (data) ->
					Layout = LayoutViewModel.instance
					Layout.ContentViewModel(new DocsViewModel)
					Layout.ContentTemplate(data)

					defer callback
				# END get
			#END fade
		#END track
	
	load: () -> Finch.call("docs/introduction")


Finch.route "[docs]/:article", 
	setup: ({article}, callback) ->
	
		$.get "./pages/docs/#{article}.md", (data) ->
			Docs = DocsViewModel.instance
			Docs.ArticleViewModel({})
			Docs.ArticleTemplate(marked(data))

			$("#content").fadeTo 'fast', 1, callback
	
	load: ({article}) ->
		article = sectionize(article)

		for elm in $("h1")
			elm = $(elm) 
			if sectionize(elm.text()) is article
				return $.scrollTo(elm, {duration: 1000, offset: -$("#header").height()-30})


Finch.route "[docs/:article]/:section", 
	load: ({section}) ->
		section = sectionize(section)

		for elm in $("h2")
			elm = $(elm) 
			if sectionize(elm.text()) is section
				return $.scrollTo(elm, {duration: 1000, offset: -$("#header").height()-30})


Finch.route "[docs/:article/:section]/:subsection", 
	load: ({subsection}) ->
		subsection = sectionize(subsection)

		for elm in $("h3")
			elm = $(elm) 
			if sectionize(elm.text()) is subsection
				return $.scrollTo(elm, {duration: 1000, offset: -$("#header").height()-30})

#------------------------------------
# Initialize the page
#------------------------------------
$ ->
	ko.applyBindings( new LayoutViewModel )

	Finch.listen()