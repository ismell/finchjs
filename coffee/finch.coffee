#------------------
# Utility
#------------------

isObject = (object) -> (typeof object) is (typeof {}) and object isnt null
isFunction = (object) -> Object::toString.call( object ) is "[object Function]"
isArray = (object) -> Object::toString.call( object ) is "[object Array]"
isString = (object) -> Object::toString.call( object ) is "[object String]"
isNumber = (object) -> Object::toString.call( object ) is "[object Number]"

trim = (str) -> str.replace(/^\s+/, '').replace(/\s+$/, '')
trimSlashes = (str) -> str.replace(/^\//, '').replace(/\/$/, '')
startsWith = (haystack, needle) -> haystack.indexOf(needle) is 0
endsWith = (haystack, needle) ->  haystack.indexOf(needle, haystack.length - needle.length) isnt -1

contains = (haystack, needle) ->
	if isFunction( haystack.indexOf )
		return haystack.indexOf(needle) isnt -1
	else if isArray( haystack )
		for hay in haystack
			return true if hay is needle
	return false
peek = (arr) -> arr[arr.length - 1]

countSubstrings = (str, substr) -> str.split(substr).length - 1

objectKeys = (obj) -> (key for key of obj)
objectValues = (obj) -> (value for key, value of obj)

extend = (obj, extender) ->
	obj = {} unless isObject(obj)
	extender = {} unless isObject(extender)

	obj[key] = value for key, value of extender

	return obj

compact = (obj) ->
	obj = {} unless isObject(obj)
	newObj = {}
	(newObj[key] = value if value?) for key, value of obj
	return newObj

objectsEqual = (obj1, obj2) ->
	for key, value of obj1
		return false if obj2[key] isnt value
	for key, value of obj2
		return false if obj1[key] isnt value
	return true

arraysEqual = (arr1, arr2) ->
	return false if arr1.length isnt arr2.length
	for value, index in arr1
		return false if arr2[index] isnt value
	return true

diffObjects = (oldObject = {}, newObject = {}) ->
	result = {}
	for key, value of oldObject
		result[key] = newObject[key] if newObject[key] != value
	for key, value of newObject
		result[key] = value if oldObject[key] != value
	return result

#------------------
# Ensure that console exists (for non-compatible browsers)
#------------------
console ?= {}
console.log ?= (->)
console.warn ?= (->)

#------------------
# Classes
#------------------

class ParsedRouteString
	constructor: ({components, childIndex}) ->
		@components = components ? []
		@childIndex = childIndex ? 0

class RouteNode
	constructor: ({name, nodeType, parent} = {}) ->
		# The name property is not used by code; it is included
		# for readability of the generated objects
		@name = name ? ""
		@nodeType = nodeType ? null
		@parent = parent ? null
		@routeSettings = null
		@childLiterals = {}
		@childVariable = null
		@bindings = []

class RouteSettings
	constructor: ({setup, teardown, load, context} = {}) ->
		@setup = if isFunction(setup) then setup else (->)
		@load = if isFunction(load) then load else (->)
		@teardown = if isFunction(teardown) then teardown else (->)
		@context = if isObject(context) then context else {}

class RoutePath
	constructor: ({node, boundValues, parameterObservables} = {}) ->
		@node = node ? null
		@boundValues = boundValues ? []
		@parameterObservables = parameterObservables ? [[]]

	getBindings: ->
		bindings = {}
		for binding, index in @node.bindings
			bindings[binding] = @boundValues[index]
		return parseParameters( bindings )

	isEqual: (path) -> path? and @node is path.node and arraysEqual(@boundValues, path.boundValues)

	isRoot: -> not @node.parent?

	getParent: ->
		return null unless @node?
		bindingCount = @node.parent?.bindings.length ? 0
		boundValues = @boundValues.slice(0, bindingCount)
		parameterObservables = @parameterObservables.slice(0,-1)
		return new RoutePath(node: @node.parent, boundValues: boundValues, parameterObservables: parameterObservables)

	getChild: (targetPath) ->
		while targetPath? and not @isEqual(parent = targetPath.getParent())
			targetPath = parent
		targetPath.parameterObservables = @parameterObservables.slice(0)
		targetPath.parameterObservables.push([])
		return targetPath

class ParameterObservable
	constructor: (callback) ->
		@callback = callback
		@callback = (->) unless isFunction(@callback)
		@dependencies = []
		@initialized = false

	notify: (updatedKeys) ->
		shouldTrigger = do =>
			return true if not @initialized
			for key in @dependencies
				return true if contains(updatedKeys, key)
			return false
		@trigger() if shouldTrigger

	trigger: ->
		@dependencies = []
		parameterAccessor = (key) =>
			@dependencies.push(key) unless contains(@dependencies, key)
			return CurrentParameters[key]
		@callback(parameterAccessor)
		@initialized = true

#------------------
# Constants
#------------------

NullPath = new RoutePath(node: null)
NodeType = {
	Literal: 'Literal'
	Variable: 'Variable'
}

#------------------
# Functions
#------------------

#---------------------------------------------------
# Method: parseQueryString
#	Used to parse and objectize a query string
#
# Arguments:
#	queryString - The query string to split up into an object
#
# Returns:
#	object - An object of the split apart query string
#---------------------------------------------------
parseQueryString = (queryString) ->

	#Make sure the query string is valid
	queryString = if isString(queryString) then trim(queryString) else ""

	#setup the return parameters
	queryParameters = {}

	#iterate through the pieces of the query string
	if queryString != ""
		for piece in queryString.split("&")
			[key, value] = piece.split("=", 2)

			queryParameters[key] = value

	#return the result
	return parseParameters( queryParameters )

#END parseQueryString

#---------------------------------------------------
# Method: parseParameters
#	Used to 'smartly' parse through the parameters
#	- converts string bools to booleans
#	- converts string numbers to numbers
#
# Arguments:
#	params - The input parameters to patse through
#
# Returns:
#	object - The parsed parameters
#---------------------------------------------------
parseParameters = (params) ->
	params = {} unless isObject(params)

	#Try to parse through parameters and be smart about their values
	for key, value of params

		#Is thie a boolean
		if value is "true"
			value = true
		else if value is "false"
			value = false
		#Is this an int
		else if /^[0-9]+$/.test(value)
			value = parseInt(value)
		#Is this a float
		else if /^[0-9]+\.[0-9]*$/.test(value)
			value = parseFloat(value)
		params[key] = value

	#Return the parameters
	return params

#END parseParameters


#---------------------------------------------------
# Method: splitUri
#	Splits a uri string into its components.
#
# Arguments:
#	uri - The uri to split
#
# Returns:
#	array - The components of the uri
#
# Examples:
#	splitUri("")         	=> ["/"]
#	splitUri("/")        	=> ["/"]
#	splitUri("foo")      	=> ["/", "foo"]
#	splitUri("/foo/bar/")	=> ["/", "foo", "bar"]
#---------------------------------------------------
splitUri = (uri) ->
	uri = trimSlashes(uri)
	components = if uri is "" then [] else uri.split("/")
	components.unshift("/")
	return components

#---------------------------------------------------
# Method: parseRouteString
#	Validates and parses a route string.
#
# Arguments:
#	routeString - The route string to parse
#
# Returns:
#	ParsedRouteString -the parsed route string,
#	or null if the route string was malformed.
#---------------------------------------------------
parseRouteString = (routeString) ->

	hasParent = contains(routeString, "[") or contains(routeString, "]")

	if hasParent then do ->
		# Validate []s match
		startCount = countSubstrings(routeString, "[")
		unless startCount is 1
			console.warn "Parsing failed on \"#{routeString}\": Extra [" if startCount > 1
			console.warn "Parsing failed on \"#{routeString}\": Missing [" if startCount < 1
			return null

		endCount = countSubstrings(routeString, "]")
		unless endCount is 1
			console.warn "Parsing failed on \"#{routeString}\": Extra ]" if endCount > 1
			console.warn "Parsing failed on \"#{routeString}\": Missing ]" if endCount < 1
			return null

		# Validate the string starts with [
		unless startsWith(routeString, "[")
			console.warn "Parsing failed on \"#{routeString}\": [ not at beginning"
			return null

	# Remove [] from string
	flatRouteString = routeString.replace(/[\[\]]/g, "")

	# Separate string into individual components
	if flatRouteString is "" then components = []
	else components = splitUri(flatRouteString)

	# Validate individual components
	for component in components
		if component is ""
			console.warn "Parsing failed on \"#{routeString}\": Blank component"
			return null

	# Find the index into the components list where the child route starts
	childIndex = 0
	if hasParent
		[parentString] = routeString.split("]")
		parentComponents = splitUri(parentString.replace("[", ""))
		if parentComponents[parentComponents.length-1] isnt components[parentComponents.length-1]
			console.warn "Parsing failed on \"#{routeString}\": ] in the middle of a component"
			return null
		if parentComponents.length is components.length
			console.warn "Parsing failed on \"#{routeString}\": No child components"
			return null
		childIndex = parentComponents.length

	return new ParsedRouteString({components, childIndex})

#END parseRouteString

#---------------------------------------------------
# Method: getComponentType
#---------------------------------------------------
getComponentType = (routeStringComponent) ->
	return NodeType.Variable if startsWith(routeStringComponent, ":")
	return NodeType.Literal

#END getComponentType

#---------------------------------------------------
# Method: getComponentName
#---------------------------------------------------
getComponentName = (routeStringComponent) ->
	switch getComponentType(routeStringComponent)
		when NodeType.Literal then routeStringComponent
		when NodeType.Variable then routeStringComponent[1..]

#END getComponentName

#---------------------------------------------------
# Method: addRoute
#	Adds a new route node to the route tree, given a route string.
#
# Arguments:
#	rootNode - The root node of the route tree.
#	parsedRouteString - The parsed route string to add to the route tree.
#	settings - The settings for the new route
#
# Returns:
#	RouteSettings - The settings of the added route
#---------------------------------------------------
addRoute = (rootNode, parsedRouteString, settings) ->

	{components, childIndex} = parsedRouteString
	parentNode = rootNode
	bindings = []

	(recur = (currentNode, currentIndex) ->
		parentNode = currentNode if currentIndex is childIndex

		# Are we done traversing the route string?
		if parsedRouteString.components.length <= 0
			currentNode.parent = parentNode
			currentNode.bindings = bindings
			return currentNode.routeSettings = new RouteSettings(settings)

		component = components.shift()
		componentType = getComponentType(component)
		componentName = getComponentName(component)

		switch componentType
			when NodeType.Literal
				nextNode = currentNode.childLiterals[componentName] ?= new RouteNode(name: "#{currentNode.name}#{component}/", nodeType: componentType, parent: rootNode)
			when NodeType.Variable
				nextNode = currentNode.childVariable ?= new RouteNode(name: "#{currentNode.name}#{component}/", nodeType: componentType, parent: rootNode)
				# Push the variable name onto the end of the bindings list
				bindings.push(componentName)

		recur(nextNode, currentIndex+1)
	)(rootNode, 0)

#END addRoute

#---------------------------------------------------
# Method: findPath
#	Finds a route in the route tree, given a URI.
#
# Arguments:
#	rootNode - The root node of the route tree.
#	uri - The uri to parse and match against the route tree.
#
# Returns:
#	RoutePath
#	node - The node that matches the URI
#	boundValues - An ordered list of values bound to each variable in the URI
#---------------------------------------------------
findPath = (rootNode, uri) ->
	uriComponents = splitUri(uri)
	boundValues = []

	(recur = (currentNode, uriComponents) ->
		# Are we done traversing the uri?
		if uriComponents.length <= 0
			return new RoutePath( node: currentNode, boundValues: boundValues )

		component = uriComponents[0]

		# Try to find a matching literal component
		if currentNode.childLiterals[component]?
			result = recur(currentNode.childLiterals[component], uriComponents[1..])
			return result if result?

		# Try to find a matching variable component
		if currentNode.childVariable?
			boundValues.push(component)
			result = recur(currentNode.childVariable, uriComponents[1..])
			return result if result?
			boundValues.pop()

		# No matching route found in this traversal branch
		return null
	)(rootNode, uriComponents)

#END findPath

#---------------------------------------------------
# Method: findNearestCommonAncestor
#	Finds the nearest common ancestor route node of two routes.
#
# Arguments:
#	path1, path2 - The two paths to compare.
#
# Returns:
#	RoutePath - The nearest common ancestor path of the two paths, or
#	null if there is no common ancestor.
#---------------------------------------------------
findNearestCommonAncestor = (path1, path2) ->
	# Enumerate all ancestors of path2 in order
	ancestors = []
	currentRoute = path2
	while currentRoute?
		ancestors.push currentRoute
		currentRoute = currentRoute.getParent()

	# Find the first ancestor of path1 that is also an ancestor of path2
	currentRoute = path1
	while currentRoute?
		for ancestor in ancestors
			return currentRoute if currentRoute.isEqual(ancestor)
		currentRoute = currentRoute.getParent()

	# No common ancestors. (Do these nodes belong to different trees?)
	return null

#END findNearestCommonAncestor

#---------------------------------------------------
# Globals
#---------------------------------------------------
RootNode = CurrentPath = CurrentTargetPath = null
PreviousParameters = CurrentParameters = null
HashInterval = CurrentHash = null
HashListening = false
IgnoreObservables = SetupCalled = false # Used to handle cases of same load/setup methods

do resetGlobals = ->
	RootNode = new RouteNode(name: "*")
	CurrentPath = NullPath
	PreviousParameters = {}
	CurrentParameters = {}
	CurrentTargetPath = null
	HashInterval = null
	CurrentHash = null
	HashListening = false
	IgnoreObservables = false
	SetupCalled = false

#END Globals

#---------------------------------------------------
# Method: step
#---------------------------------------------------
step = ->
	#If there is no current target path, only step through the observables
	if CurrentTargetPath is null

		#Execute the observables
		runObservables()

	#If we're at our destination. run the load method
	else if CurrentTargetPath.isEqual(CurrentPath)

		#Execute this path's load method
		stepLoad()

	#Otherwise step through a teardown/setup
	else
		# Find the nearest common ancestor of the current and new path
		ancestorPath = findNearestCommonAncestor(CurrentPath, CurrentTargetPath)

		# If the current path is an ancestor of the new path, then setup towards the new path;
		# otherwise, teardown towards the common ancestor
		if CurrentPath.isEqual(ancestorPath) then stepSetup() else stepTeardown()

#END step

#---------------------------------------------------
# Method: stepSetup
#	Used to execute a setup method on a node
#---------------------------------------------------
stepSetup = ->
	SetupCalled = true

	# During setup and teardown, CurrentPath should always be the path to the
	# node getting setup or torn down.
	# In the setup case: CurrentPath must be set before the setup function is called.
	CurrentPath = CurrentPath.getChild(CurrentTargetPath)

	{context, setup, load} = CurrentPath.node.routeSettings ? {}
	context ?= {}
	setup ?= (->)
	load ?= (->)
	bindings = CurrentPath.getBindings()
	recur = -> step()

	# If the setup/teardown takes two parameters, then it is an asynchronous call
	if setup.length is 2
		setup.call(context, bindings, recur)

	# Otherwise it is a synchronous call
	else
		setup.call(context, bindings)
		recur()

#END stepSetup

#---------------------------------------------------
# Method: stepLoad
#	Used to execute a load method on a node
#---------------------------------------------------
stepLoad = ->
	# End the step process
	CurrentTargetPath = null
	recur = -> step()

	#Stop executing if we don't have a current node
	return recur() unless CurrentPath.node?

	{context, setup, load} = CurrentPath.node.routeSettings ? {}
	context ?= {}
	setup ?= (->)
	load ?= (->)
	bindings = CurrentPath.getBindings()

	#Is the load method asynchronous?
	if load.length is 2
		load.call(context, bindings, recur)

	#Execute it synchronously
	else
		load.call(context, bindings)
		recur()

#END stepLoad

#---------------------------------------------------
# Method: stepTeardown
#	Used to execute a teardown method on a node
#---------------------------------------------------
stepTeardown = ->
	SetupCalled = false

	{context, teardown} = CurrentPath.node.routeSettings ? {}
	context ?= {}
	teardown ?= (->)
	bindings = CurrentPath.getBindings()
	recur = ->
		# During setup and teardown, CurrentPath should always be the path to the
		# node getting setup or torn down.
		# In the teardown case: CurrentPath must be set after the teardown function is called.
		CurrentPath = CurrentPath.getParent()
		step()

	# If the setup/teardown takes two parameters, then it is an asynchronous call
	if teardown.length is 2
		teardown.call(context, bindings, recur)

	# Otherwise it is a synchronous call
	else
		teardown.call(context, bindings)
		recur()

#END stepTeardown

#---------------------------------------------------
# Method: runObservables
#	Used to iterate through the observables
#---------------------------------------------------
runObservables = ->
	# Run observables
	keys = objectKeys( diffObjects( PreviousParameters, CurrentParameters ))
	PreviousParameters = CurrentParameters
	for observableList in CurrentPath.parameterObservables
		for observable in observableList
			observable.notify(keys)

#END runObservables

#---------------------------------------------------
# Method: hashChangeListener
#	Used to respond to hash changes
#---------------------------------------------------
hashChangeListener = (event) ->
	hash = window.location.hash
	hash = hash.slice(1) if startsWith(hash, "#")
	hash = unescape(hash)

	#Only try to run Finch.call if the hash actually changed
	if hash isnt CurrentHash

		#Run Finch.call, if successful save the current hash
		if Finch.call(hash)
			CurrentHash = hash

		#If not successful revert
		else
			window.location.hash = CurrentHash ? ""

#END hashChangeListener

#---------------------------------------------------
# Class: Finch
#
# Methods:
#	Finch.route - Assigns a new route pattern
#	Finch.call - Calls a specific route and operates accordingly
#	Finch.listen - Listens to changes in the hash portion of the window.location
#	Finch.ignore - Ignored hash responses
#	Finch.navigate - Navigates the page (updates the hash)
#	Finch.reset - resets Finch
#---------------------------------------------------
Finch = {
	#---------------------------------------------------
	# Method: Finch.route
	#	Used to setup a new route
	#
	# Arguments:
	#	pattern - The pattern to add
	#	settings - The settings for when this route is executed
	#---------------------------------------------------
	route: (pattern, settings) ->

		#Check if the input parameter was a function, assign it to the setup method
		#if it was
		if isFunction(settings)

			#Store some scoped variables
			cb = settings
			settings = {setup: cb}

			#if the callback was asynchronous, setup the setting as such
			if cb.length is 2
				settings.load = (bindings, callback) ->
					if not SetupCalled
						IgnoreObservables = true
						cb(bindings, callback)

			#Otherwise set them up synchronously
			else
				settings.load = (bindings) ->
					if not SetupCalled
						IgnoreObservables = true
						cb(bindings)

		settings = {} unless isObject(settings)

		# Make sure we have valid inputs
		pattern = "" unless isString(pattern)

		# Parse the route, and return false if it was invalid
		parsedRouteString = parseRouteString(pattern)
		return false unless parsedRouteString?

		# Add the new route to the route tree
		addRoute(RootNode, parsedRouteString, settings)

		return true

	#END Finch.route()

	#---------------------------------------------------
	# Method: Finch.call
	#
	# Arguments:
	#	route - The route to try and call
	#---------------------------------------------------
	call: (uri) ->

		#Make sure we have valid arguments
		uri = "/" unless isString(uri)
		uri = "/" if uri is ""

		#Extract the route and query parameters from the uri
		[uri, queryString] = uri.split("?", 2)

		# Find matching route in route tree, returning false if there is none
		newPath = findPath(RootNode, uri)
		return false unless newPath?

		queryParameters = parseQueryString(queryString)
		bindings = newPath.getBindings()
		CurrentParameters = extend(queryParameters, bindings)

		#If we're not in the middle of executing and the current path is the same
		#as the one we're trying to go to, just execute the observables so we
		#avoid calling the load method again
		if CurrentTargetPath is null and CurrentPath.isEqual(newPath)
			step()

		#Otherwise, start stepping towards our target
		else
			previousTargetPath = CurrentTargetPath
			CurrentTargetPath = newPath

			# Start the process of teardowns/setups if we were not already doing so
			step() unless previousTargetPath?

		return true;

	#END Finch.call()

	#---------------------------------------------------
	# Method: Finch.observe
	#	Used to set up observers on the query string.
	#
	# Form 1:
	#	Finch.observe(key, key, ..., callback(keys...))
	# Arguments:
	#	keys... - A list of parameter keys
	#	callback(keys...) - A callback function to execute with the values bound to each key in order.
	#
	# Form 2:
	#	Finch.observe([key, key, ...], callback(keys...))
	# Arguments:
	#	keys[] - An array of parameter keys
	#	callback(keys...) - A callback function to execute with the values bound to each key in order.
	#
	# Form 3:
	#	Finch.observe(callback(accessor))
	# Arguments:
	#	callback(accessor) - A callback function to execute with a parameter accessor.
	#---------------------------------------------------
	observe: (args...) ->
		#Don't worry about this if we're ignoring the params
		if IgnoreObservables
			return IgnoreObservables = false

		# The callback is alwaysthe last parameter
		callback = args.pop()
		callback = (->) unless isFunction(callback)

		# Handle argument form 1/2
		if args.length > 0

			if args.length is 1 and isArray(args[0])
				keys = args[0]
			else
				keys = args
			return Finch.observe (paramAccessor) ->
				values = (paramAccessor(key) for key in keys)
				callback(values...)

		#Handle form 3
		else
			observable = new ParameterObservable(callback)
			peek(CurrentPath.parameterObservables).push(observable)

	#END Finch.observe()

	#---------------------------------------------------
	# Method: Finch.listen
	#	Used to listen to changes in the window hash, will respond with Finch.call
	#
	# Returns:
	#	boolean - Is Finch listening?
	#---------------------------------------------------
	listen: () ->
		#Only do this if we're currently not listening
		if not HashListening
			#Check if the window has an onhashcnage event
			if "onhashchange" of window
				if isFunction(window.addEventListener)
					window.addEventListener("hashchange", hashChangeListener, true)
					HashListening = true

				else if isFunction(window.attachEvent)
					window.attachEvent("hashchange", hashChangeListener)
					HashListening = true

			# if we're still not listening fallback to a set interval
			if not HashListening
				HashInterval = setInterval(hashChangeListener, 33)
				HashListening = true

			#Perform an initial hash change
			hashChangeListener()

		return HashListening

	#END Finch.listen()

	#---------------------------------------------------
	# Method: Finch.ignore
	#	Used to stop listening to changes in the hash
	#
	# Returns:
	#	boolean - Is Finch done listening?
	#---------------------------------------------------
	ignore: () ->
		#Only continue if we're listening
		if HashListening

			#Are we suing set interval? if so, clear it
			if HashInterval isnt null
				clearInterval(HashInterval)
				HashInterval = null
				HashListening = false

			#Otherwise if the window has onhashchange, try to remove the event listener
			else if "onhashchange" of window

				if isFunction(window.removeEventListener)
					window.removeEventListener("hashchange", hashChangeListener, true)
					HashListening = false

				else if isFunction(window.detachEvent)
					window.detachEvent("hashchange", hashChangeListener)
					HashListening = false

		return not HashListening

	#END Finch.ignore()

	#---------------------------------------------------
	# Method: Finch.navigate
	#	Method used to 'navigate' to a new/update the existing hash route
	#
	# Form 1:
	#	Finch.navigate('/my/favorite/route', {hello: 'world'})
	#	- or -
	#	Finch.navigate(null, {hello: 'world'})
	# Arguments:
	#	uri (string) - string of a uri to browse to, if uri is null, the current uri will be used
	#	queryParams (object) - The query parameters to add the to the uri
	#
	# Form 2:
	#	Finch.navigate({hello: 'world', foo: 'bar'})
	# Arguments:
	#	queryParams (object) - An object to UPDATE the current list of query parameters (won't delete parameters from the list, only add and/or update current)use Finch.navigate(null, {params}) to change the list of query parameters
	#---------------------------------------------------
	navigate: (uri, queryParams) ->

		#if the uri is an object, we'll assume we're just updating the hash
		if isObject(uri)
			queryParams = uri
			uri = null
			currentQueryString = window.location.hash.split("?", 2)[1] ? ""
			currentQueryParams = parseQueryString(currentQueryString)

			#Unescape things fromthe current query params
			do ->
				newQueryParams = {}
				for key, value of currentQueryParams
					newQueryParams[unescape(key)] = unescape(value)
				currentQueryParams = newQueryParams

			#udpate the query params
			queryParams = extend(currentQueryParams, queryParams)
			queryParams = compact(queryParams)

		#otherwise assume they're trying to browser to a completely new route
		else
			uri = null unless isString(uri)
			queryParams = {} unless isObject(queryParams)
			queryParams = compact(queryParams)

		#Generate a query string
		queryString = (escape(key) + "=" + escape(value) for key, value of queryParams).join("&")

		#if the uri is null, use the current uri
		if uri is null
			uri = window.location.hash.split("?", 2)[0] ? ""
			uri = uri.slice(1) if uri.slice(0,1) is "#"

		#escape the uri
		uri = escape(uri)

		#try to attach the query string
		if queryString.length > 0
			uri += if uri.indexOf("?") > -1 then "&" else "?"
			uri += queryString

		#update the hash
		window.location.hash = uri

	#END Finch.navigate()

	#---------------------------------------------------
	# Method: Finch.reset
	#   Tears down the current stack and resets the routes
	#
	# Arguments:
	#	none
	#---------------------------------------------------
	reset: ->
		# Tear down the entire route
		CurrentTargetPath = NullPath
		step()
		Finch.ignore()
		resetGlobals()
		return

	#END Finch.reset()
}

###
# FOR NOW, we'll just comment this out instead of having a debug flag
Finch.private = {
	# utility
	isObject
	isFunction
	isArray
	isString
	isNumber
	trim
	trimSlashes
	startsWith
	endsWith
	contains
	extend
	objectsEqual
	arraysEqual

	# constants
	NullPath
	NodeType

	# classes
	RouteSettings
	RoutePath
	RouteNode

	#functions
	parseQueryString
	splitUri
	parseRouteString
	getComponentType
	getComponentName
	addRoute
	findPath
	findNearestCommonAncestor

	globals: -> return {
		RootNode
		CurrentPath
		CurrentParameters
	}
}
###

#Expose Finch to the window
@Finch = Finch