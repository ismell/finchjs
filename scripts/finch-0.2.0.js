/*
  Finch.js - Powerfully simple javascript routing
  by Rick Allen (stoodder) and Greg Smith (smrq)

  Version 0.2.0
  Full source at https://github.com/stoodder/finchjs
  Copyright (c) 2011 RokkinCat, http://www.rokkincat.com

  MIT License, https://github.com/stoodder/finchjs/blob/master/LICENSE.md
  This file is generated by `cake build`, do not edit it by hand.
*/
(function() {
  var CurrentHash, CurrentParameters, CurrentPath, CurrentTargetPath, Finch, HashInterval, HashListening, IgnoreObservables, NodeType, NullPath, ParameterObservable, ParsedRouteString, PreviousParameters, RootNode, RouteNode, RoutePath, RouteSettings, SetupCalled, addRoute, arraysEqual, contains, countSubstrings, diffObjects, endsWith, extend, findNearestCommonAncestor, findPath, getComponentName, getComponentType, hashChangeListener, isArray, isFunction, isNumber, isObject, isString, objectKeys, objectValues, objectsEqual, parseQueryString, parseRouteString, peek, resetGlobals, runObservables, splitUri, startsWith, step, stepLoad, stepSetup, stepTeardown, trim, trimSlashes,
    __slice = Array.prototype.slice;

  isObject = function(object) {
    return (typeof object) === (typeof {}) && object !== null;
  };

  isFunction = function(object) {
    return Object.prototype.toString.call(object) === "[object Function]";
  };

  isArray = function(object) {
    return Object.prototype.toString.call(object) === "[object Array]";
  };

  isString = function(object) {
    return Object.prototype.toString.call(object) === "[object String]";
  };

  isNumber = function(object) {
    return Object.prototype.toString.call(object) === "[object Number]";
  };

  trim = function(str) {
    return str.replace(/^\s+/, '').replace(/\s+$/, '');
  };

  trimSlashes = function(str) {
    return str.replace(/^\//, '').replace(/\/$/, '');
  };

  startsWith = function(haystack, needle) {
    return haystack.indexOf(needle) === 0;
  };

  endsWith = function(haystack, needle) {
    return haystack.indexOf(needle, haystack.length - needle.length) !== -1;
  };

  contains = function(haystack, needle) {
    return haystack.indexOf(needle) !== -1;
  };

  peek = function(arr) {
    return arr[arr.length - 1];
  };

  countSubstrings = function(str, substr) {
    return str.split(substr).length - 1;
  };

  objectKeys = function(obj) {
    var key, _results;
    _results = [];
    for (key in obj) {
      _results.push(key);
    }
    return _results;
  };

  objectValues = function(obj) {
    var key, value, _results;
    _results = [];
    for (key in obj) {
      value = obj[key];
      _results.push(value);
    }
    return _results;
  };

  extend = function(obj, extender) {
    var key, value;
    if (!isObject(obj)) obj = {};
    if (!isObject(extender)) extender = {};
    for (key in extender) {
      value = extender[key];
      obj[key] = value;
    }
    return obj;
  };

  objectsEqual = function(obj1, obj2) {
    var key, value;
    for (key in obj1) {
      value = obj1[key];
      if (obj2[key] !== value) return false;
    }
    for (key in obj2) {
      value = obj2[key];
      if (obj1[key] !== value) return false;
    }
    return true;
  };

  arraysEqual = function(arr1, arr2) {
    var index, value, _len;
    if (arr1.length !== arr2.length) return false;
    for (index = 0, _len = arr1.length; index < _len; index++) {
      value = arr1[index];
      if (arr2[index] !== value) return false;
    }
    return true;
  };

  diffObjects = function(oldObject, newObject) {
    var key, result, value;
    if (oldObject == null) oldObject = {};
    if (newObject == null) newObject = {};
    result = {};
    for (key in oldObject) {
      value = oldObject[key];
      if (newObject[key] !== value) result[key] = newObject[key];
    }
    for (key in newObject) {
      value = newObject[key];
      if (oldObject[key] !== value) result[key] = value;
    }
    return result;
  };

  if (typeof console === "undefined" || console === null) console = {};

  if (console.log == null) console.log = (function() {});

  if (console.warn == null) console.warn = (function() {});

  ParsedRouteString = (function() {

    function ParsedRouteString(_arg) {
      var childIndex, components;
      components = _arg.components, childIndex = _arg.childIndex;
      this.components = components != null ? components : [];
      this.childIndex = childIndex != null ? childIndex : 0;
    }

    return ParsedRouteString;

  })();

  RouteNode = (function() {

    function RouteNode(_arg) {
      var name, nodeType, parent, _ref;
      _ref = _arg != null ? _arg : {}, name = _ref.name, nodeType = _ref.nodeType, parent = _ref.parent;
      this.name = name != null ? name : "";
      this.nodeType = nodeType != null ? nodeType : null;
      this.parent = parent != null ? parent : null;
      this.routeSettings = null;
      this.childLiterals = {};
      this.childVariable = null;
      this.bindings = [];
    }

    return RouteNode;

  })();

  RouteSettings = (function() {

    function RouteSettings(_arg) {
      var context, load, setup, teardown, _ref;
      _ref = _arg != null ? _arg : {}, setup = _ref.setup, teardown = _ref.teardown, load = _ref.load, context = _ref.context;
      this.setup = isFunction(setup) ? setup : (function() {});
      this.load = isFunction(load) ? load : (function() {});
      this.teardown = isFunction(teardown) ? teardown : (function() {});
      this.context = isObject(context) ? context : {};
    }

    return RouteSettings;

  })();

  RoutePath = (function() {

    function RoutePath(_arg) {
      var boundValues, node, parameterObservables, _ref;
      _ref = _arg != null ? _arg : {}, node = _ref.node, boundValues = _ref.boundValues, parameterObservables = _ref.parameterObservables;
      this.node = node != null ? node : null;
      this.boundValues = boundValues != null ? boundValues : [];
      this.parameterObservables = parameterObservables != null ? parameterObservables : [];
    }

    RoutePath.prototype.getBindings = function() {
      var binding, bindings, index, _len, _ref;
      bindings = {};
      _ref = this.node.bindings;
      for (index = 0, _len = _ref.length; index < _len; index++) {
        binding = _ref[index];
        bindings[binding] = this.boundValues[index];
      }
      return bindings;
    };

    RoutePath.prototype.isEqual = function(path) {
      return (path != null) && this.node === path.node && arraysEqual(this.boundValues, path.boundValues);
    };

    RoutePath.prototype.isRoot = function() {
      return !(this.node.parent != null);
    };

    RoutePath.prototype.getParent = function() {
      var bindingCount, boundValues, parameterObservables, _ref, _ref2;
      if (this.node == null) return null;
      bindingCount = (_ref = (_ref2 = this.node.parent) != null ? _ref2.bindings.length : void 0) != null ? _ref : 0;
      boundValues = this.boundValues.slice(0, bindingCount);
      parameterObservables = this.parameterObservables.slice(0, -1);
      return new RoutePath({
        node: this.node.parent,
        boundValues: boundValues,
        parameterObservables: parameterObservables
      });
    };

    RoutePath.prototype.getChild = function(targetPath) {
      var parent;
      while ((targetPath != null) && !this.isEqual(parent = targetPath.getParent())) {
        targetPath = parent;
      }
      targetPath.parameterObservables = this.parameterObservables.slice(0);
      targetPath.parameterObservables.push([]);
      return targetPath;
    };

    return RoutePath;

  })();

  ParameterObservable = (function() {

    function ParameterObservable(callback) {
      this.callback = callback;
      if (!isFunction(this.callback)) this.callback = (function() {});
      this.dependencies = [];
      this.initialized = false;
    }

    ParameterObservable.prototype.notify = function(updatedKeys) {
      var shouldTrigger,
        _this = this;
      shouldTrigger = (function() {
        var key, _i, _len, _ref;
        if (!_this.initialized) return true;
        _ref = _this.dependencies;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          key = _ref[_i];
          if (contains(updatedKeys, key)) return true;
        }
        return false;
      })();
      if (shouldTrigger) return this.trigger();
    };

    ParameterObservable.prototype.trigger = function() {
      var parameterAccessor,
        _this = this;
      this.dependencies = [];
      parameterAccessor = function(key) {
        if (!contains(_this.dependencies, key)) _this.dependencies.push(key);
        return CurrentParameters[key];
      };
      this.callback(parameterAccessor);
      return this.initialized = true;
    };

    return ParameterObservable;

  })();

  NullPath = new RoutePath({
    node: null
  });

  NodeType = {
    Literal: 'Literal',
    Variable: 'Variable'
  };

  parseQueryString = function(queryString) {
    var key, piece, queryParameters, value, _i, _len, _ref, _ref2;
    queryString = isString(queryString) ? trim(queryString) : "";
    queryParameters = {};
    if (queryString !== "") {
      _ref = queryString.split("&");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        piece = _ref[_i];
        _ref2 = piece.split("=", 2), key = _ref2[0], value = _ref2[1];
        queryParameters[key] = value;
      }
    }
    return queryParameters;
  };

  splitUri = function(uri) {
    var components;
    uri = trimSlashes(uri);
    components = uri === "" ? [] : uri.split("/");
    components.unshift("/");
    return components;
  };

  parseRouteString = function(routeString) {
    var childIndex, component, components, flatRouteString, hasParent, parentComponents, parentString, _i, _len;
    hasParent = contains(routeString, "[") || contains(routeString, "]");
    if (hasParent) {
      (function() {
        var endCount, startCount;
        startCount = countSubstrings(routeString, "[");
        if (startCount !== 1) {
          if (startCount > 1) {
            console.warn("Parsing failed on \"" + routeString + "\": Extra [");
          }
          if (startCount < 1) {
            console.warn("Parsing failed on \"" + routeString + "\": Missing [");
          }
          return null;
        }
        endCount = countSubstrings(routeString, "]");
        if (endCount !== 1) {
          if (endCount > 1) {
            console.warn("Parsing failed on \"" + routeString + "\": Extra ]");
          }
          if (endCount < 1) {
            console.warn("Parsing failed on \"" + routeString + "\": Missing ]");
          }
          return null;
        }
        if (!startsWith(routeString, "[")) {
          console.warn("Parsing failed on \"" + routeString + "\": [ not at beginning");
          return null;
        }
      })();
    }
    flatRouteString = routeString.replace(/[\[\]]/g, "");
    if (flatRouteString === "") {
      components = [];
    } else {
      components = splitUri(flatRouteString);
    }
    for (_i = 0, _len = components.length; _i < _len; _i++) {
      component = components[_i];
      if (component === "") {
        console.warn("Parsing failed on \"" + routeString + "\": Blank component");
        return null;
      }
    }
    childIndex = 0;
    if (hasParent) {
      parentString = routeString.split("]")[0];
      parentComponents = splitUri(parentString.replace("[", ""));
      if (parentComponents[parentComponents.length - 1] !== components[parentComponents.length - 1]) {
        console.warn("Parsing failed on \"" + routeString + "\": ] in the middle of a component");
        return null;
      }
      if (parentComponents.length === components.length) {
        console.warn("Parsing failed on \"" + routeString + "\": No child components");
        return null;
      }
      childIndex = parentComponents.length;
    }
    return new ParsedRouteString({
      components: components,
      childIndex: childIndex
    });
  };

  getComponentType = function(routeStringComponent) {
    if (startsWith(routeStringComponent, ":")) return NodeType.Variable;
    return NodeType.Literal;
  };

  getComponentName = function(routeStringComponent) {
    switch (getComponentType(routeStringComponent)) {
      case NodeType.Literal:
        return routeStringComponent;
      case NodeType.Variable:
        return routeStringComponent.slice(1);
    }
  };

  addRoute = function(rootNode, parsedRouteString, settings) {
    var bindings, childIndex, components, parentNode, recur;
    components = parsedRouteString.components, childIndex = parsedRouteString.childIndex;
    parentNode = rootNode;
    bindings = [];
    return (recur = function(currentNode, currentIndex) {
      var component, componentName, componentType, nextNode, _base, _ref, _ref2;
      if (currentIndex === childIndex) parentNode = currentNode;
      if (parsedRouteString.components.length <= 0) {
        currentNode.parent = parentNode;
        currentNode.bindings = bindings;
        return currentNode.routeSettings = new RouteSettings(settings);
      }
      component = components.shift();
      componentType = getComponentType(component);
      componentName = getComponentName(component);
      switch (componentType) {
        case NodeType.Literal:
          nextNode = (_ref = (_base = currentNode.childLiterals)[componentName]) != null ? _ref : _base[componentName] = new RouteNode({
            name: "" + currentNode.name + component + "/",
            nodeType: componentType,
            parent: rootNode
          });
          break;
        case NodeType.Variable:
          nextNode = (_ref2 = currentNode.childVariable) != null ? _ref2 : currentNode.childVariable = new RouteNode({
            name: "" + currentNode.name + component + "/",
            nodeType: componentType,
            parent: rootNode
          });
          bindings.push(componentName);
      }
      return recur(nextNode, currentIndex + 1);
    })(rootNode, 0);
  };

  findPath = function(rootNode, uri) {
    var boundValues, recur, uriComponents;
    uriComponents = splitUri(uri);
    boundValues = [];
    return (recur = function(currentNode) {
      var component, result;
      if (uriComponents.length <= 0) {
        return new RoutePath({
          node: currentNode,
          boundValues: boundValues
        });
      }
      component = uriComponents.shift();
      if (currentNode.childLiterals[component] != null) {
        result = recur(currentNode.childLiterals[component]);
        if (result != null) return result;
      }
      if (currentNode.childVariable != null) {
        boundValues.push(component);
        result = recur(currentNode.childVariable);
        if (result != null) return result;
        boundValues.pop();
      }
      return null;
    })(rootNode);
  };

  findNearestCommonAncestor = function(path1, path2) {
    var ancestor, ancestors, currentRoute, _i, _len;
    ancestors = [];
    currentRoute = path2;
    while (currentRoute != null) {
      ancestors.push(currentRoute);
      currentRoute = currentRoute.getParent();
    }
    currentRoute = path1;
    while (currentRoute != null) {
      for (_i = 0, _len = ancestors.length; _i < _len; _i++) {
        ancestor = ancestors[_i];
        if (currentRoute.isEqual(ancestor)) return currentRoute;
      }
      currentRoute = currentRoute.getParent();
    }
    return null;
  };

  RootNode = CurrentPath = CurrentTargetPath = null;

  PreviousParameters = CurrentParameters = null;

  HashInterval = CurrentHash = null;

  HashListening = false;

  IgnoreObservables = SetupCalled = false;

  (resetGlobals = function() {
    RootNode = new RouteNode({
      name: "*"
    });
    CurrentPath = NullPath;
    PreviousParameters = {};
    CurrentParameters = {};
    CurrentTargetPath = null;
    HashInterval = null;
    CurrentHash = null;
    HashListening = false;
    IgnoreObservables = false;
    return SetupCalled = false;
  })();

  step = function() {
    var ancestorPath;
    if (CurrentTargetPath === null) {
      return runObservables();
    } else if (CurrentTargetPath.isEqual(CurrentPath)) {
      return stepLoad();
    } else {
      ancestorPath = findNearestCommonAncestor(CurrentPath, CurrentTargetPath);
      if (CurrentPath.isEqual(ancestorPath)) {
        return stepSetup();
      } else {
        return stepTeardown();
      }
    }
  };

  stepSetup = function() {
    var bindings, context, load, recur, setup, _ref, _ref2;
    SetupCalled = true;
    CurrentPath = CurrentPath.getChild(CurrentTargetPath);
    _ref2 = (_ref = CurrentPath.node.routeSettings) != null ? _ref : {}, context = _ref2.context, setup = _ref2.setup, load = _ref2.load;
    if (context == null) context = {};
    if (setup == null) setup = (function() {});
    if (load == null) load = (function() {});
    bindings = CurrentPath.getBindings();
    recur = function() {
      return step();
    };
    if (setup.length === 2) {
      return setup.call(context, bindings, recur);
    } else {
      setup.call(context, bindings);
      return recur();
    }
  };

  stepLoad = function() {
    var bindings, context, load, recur, setup, _ref, _ref2;
    CurrentTargetPath = null;
    recur = function() {
      return step();
    };
    if (CurrentPath.node == null) return recur();
    _ref2 = (_ref = CurrentPath.node.routeSettings) != null ? _ref : {}, context = _ref2.context, setup = _ref2.setup, load = _ref2.load;
    if (context == null) context = {};
    if (setup == null) setup = (function() {});
    if (load == null) load = (function() {});
    bindings = CurrentPath.getBindings();
    if (load.length === 2) {
      return load.call(context, bindings, recur);
    } else {
      load.call(context, bindings);
      return recur();
    }
  };

  stepTeardown = function() {
    var bindings, context, recur, teardown, _ref, _ref2;
    SetupCalled = false;
    _ref2 = (_ref = CurrentPath.node.routeSettings) != null ? _ref : {}, context = _ref2.context, teardown = _ref2.teardown;
    if (context == null) context = {};
    if (teardown == null) teardown = (function() {});
    bindings = CurrentPath.getBindings();
    recur = function() {
      CurrentPath = CurrentPath.getParent();
      return step();
    };
    if (teardown.length === 2) {
      return teardown.call(context, bindings, recur);
    } else {
      teardown.call(context, bindings);
      return recur();
    }
  };

  runObservables = function() {
    var keys, observable, observableList, _i, _len, _ref, _results;
    keys = objectKeys(diffObjects(PreviousParameters, CurrentParameters));
    PreviousParameters = CurrentParameters;
    _ref = CurrentPath.parameterObservables;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      observableList = _ref[_i];
      _results.push((function() {
        var _j, _len2, _results2;
        _results2 = [];
        for (_j = 0, _len2 = observableList.length; _j < _len2; _j++) {
          observable = observableList[_j];
          _results2.push(observable.notify(keys));
        }
        return _results2;
      })());
    }
    return _results;
  };

  hashChangeListener = function(event) {
    var hash;
    hash = window.location.hash;
    if (startsWith(hash, "#")) hash = hash.slice(1);
    hash = unescape(hash);
    if (hash !== CurrentHash) {
      if (Finch.call(hash)) {
        return CurrentHash = hash;
      } else {
        return window.location.hash = CurrentHash != null ? CurrentHash : "";
      }
    }
  };

  Finch = {
    route: function(pattern, settings) {
      var cb, parsedRouteString;
      if (isFunction(settings)) {
        cb = settings;
        settings = {
          setup: cb
        };
        if (cb.length === 2) {
          settings.load = function(bindings, callback) {
            if (!SetupCalled) {
              IgnoreObservables = true;
              return cb(bindings, callback);
            }
          };
        } else {
          settings.load = function(bindings) {
            if (!SetupCalled) {
              IgnoreObservables = true;
              return cb(bindings);
            }
          };
        }
      }
      if (!isObject(settings)) settings = {};
      if (!isString(pattern)) pattern = "";
      parsedRouteString = parseRouteString(pattern);
      if (parsedRouteString == null) return false;
      addRoute(RootNode, parsedRouteString, settings);
      return true;
    },
    call: function(uri) {
      var bindings, newPath, previousTargetPath, queryParameters, queryString, _ref;
      if (!isString(uri)) uri = "/";
      if (uri === "") uri = "/";
      _ref = uri.split("?", 2), uri = _ref[0], queryString = _ref[1];
      newPath = findPath(RootNode, uri);
      if (newPath == null) return false;
      queryParameters = parseQueryString(queryString);
      bindings = newPath.getBindings();
      CurrentParameters = extend(queryParameters, bindings);
      if (CurrentTargetPath === null && CurrentPath.isEqual(newPath)) {
        step();
      } else {
        previousTargetPath = CurrentTargetPath;
        CurrentTargetPath = newPath;
        if (previousTargetPath == null) step();
      }
      return true;
    },
    observe: function() {
      var args, callback, keys, observable;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (IgnoreObservables) return IgnoreObservables = false;
      callback = args.pop();
      if (!isFunction(callback)) callback = (function() {});
      if (args.length > 0) {
        if (args.length === 1 && isArray(args[0])) {
          keys = args[0];
        } else {
          keys = args;
        }
        return Finch.observe(function(paramAccessor) {
          var key, values;
          values = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = keys.length; _i < _len; _i++) {
              key = keys[_i];
              _results.push(paramAccessor(key));
            }
            return _results;
          })();
          return callback.apply(null, values);
        });
      } else {
        observable = new ParameterObservable(callback);
        return peek(CurrentPath.parameterObservables).push(observable);
      }
    },
    listen: function() {
      if (!HashListening) {
        if ("onhashchange" in window) {
          if (isFunction(window.addEventListener)) {
            window.addEventListener("hashchange", hashChangeListener, true);
            HashListening = true;
          } else if (isFunction(window.attachEvent)) {
            window.attachEvent("hashchange", hashChangeListener);
            HashListening = true;
          }
        }
        if (!HashListening) {
          HashInterval = setInterval(hashChangeListener, 33);
          HashListening = true;
        }
        hashChangeListener();
      }
      return HashListening;
    },
    ignore: function() {
      if (HashListening) {
        if (HashInterval !== null) {
          clearInterval(HashInterval);
          HashInterval = null;
          HashListening = false;
        } else if ("onhashchange" in window) {
          if (isFunction(window.removeEventListener)) {
            window.removeEventListener("hashchange", hashChangeListener, true);
            HashListening = false;
          } else if (isFunction(window.detachEvent)) {
            window.detachEvent("hashchange", hashChangeListener);
            HashListening = false;
          }
        }
      }
      return !HashListening;
    },
    navigate: function(uri, queryParams) {
      var currentQueryParams, currentQueryString, key, queryString, value, _ref, _ref2;
      if (isObject(uri)) {
        queryParams = uri;
        uri = null;
        currentQueryString = (_ref = window.location.hash.split("?", 2)[1]) != null ? _ref : "";
        currentQueryParams = parseQueryString(currentQueryString);
        for (key in currentQueryParams) {
          value = currentQueryParams[key];
          currentQueryParams[unescape(key)] = unescape(value);
        }
        queryParams = extend(currentQueryParams, queryParams);
      } else {
        if (!isString(uri)) uri = null;
        if (!isObject(queryParams)) queryParams = {};
      }
      queryString = ((function() {
        var _results;
        _results = [];
        for (key in queryParams) {
          value = queryParams[key];
          _results.push(escape(key) + "=" + escape(value));
        }
        return _results;
      })()).join("&");
      if (uri === null) {
        uri = (_ref2 = window.location.hash.split("?", 2)[0]) != null ? _ref2 : "";
        if (uri.slice(0, 1) === "#") uri = uri.slice(1);
      }
      uri = escape(uri);
      if (queryString.length > 0) {
        uri += uri.indexOf("?") > -1 ? "&" : "?";
        uri += queryString;
      }
      return window.location.hash = uri;
    },
    reset: function() {
      CurrentTargetPath = NullPath;
      step();
      Finch.ignore();
      resetGlobals();
    }
  };

  /*
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
  */

  this.Finch = Finch;

}).call(this);