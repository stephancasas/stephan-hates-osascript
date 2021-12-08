use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

on run _args
	
end run


(*

// AppleScript is not a strongly-typed language. Type definitions are provided for documentation purposes only.

type UIElementContext = UIElement || window;

type UIElementName = string;

type UIElementType = 'button' || 'UI Element' || 'scroll area' || ...rest;

type UIElementProperty = 'name' || 'selected' || 'enabled' || ...rest;

type UIElementPropertyFilter = `${UIElementProperty} is ${any}`;

type UIElementAbsolutePath = `the first ${UIElementType} of _context whose ${...Array<UIElementPropertyFilter> || UIElementPropertyFilter}`;

type UIElementLoosePath = `the first ${UIElementType}`;

type UIElementPrimitivePath = UIElementName || UIElementPropertyFilter || UIElementAbsolutePath;

type UIElementTypedPathObject = {UIElementType, UIElementPrimitivePath};

type UIElementUnresolvedPath = UIElementPrimitivePath || UIElementTypedPathObject;

type UIElementSelector = {UIElementContext, UIElementAbsolutePath};

type UIElementUnresovledSelector = UIElementUnresolvedPath || UIElementSelector;

type UIElementAXAttribute = 'AXRole' || 'AXSubrole' || 'AXLabel' || ...rest;

type UIElementAXAction = 'AXPress' || 'AXConfirm' || ...rest;

*)

(* Click a given UI Element. *)
(* @accept: (UIElementUnresolvedSelector || UIElement), UIElementAXAttribute *)
(* @return: void *)
(* PUBLIC *)
on ui_click(_selectorOrElement)
	set _element to my resolveSelectorOrElement(_selectorOrElement)
	tell application "System Events" to click _element
end ui_click

(* Get the value of a UI Element's attribute. *)
(* @accept: (UIElementUnresolvedSelector || UIElement), UIElementAXAttribute *)
(* @return: any *)
(* PUBLIC *)
on ui_attr(_selectorOrElement, _attribute)
	set _element to my resolveSelectorOrElement(_selectorOrElement)
	tell application "System Events" to return the value of attribute _attribute of _element
end ui_attr

(* Perform a UI Element's action. *)
(* @accept: (UIElementUnresolvedSelector || UIElement), UIElementAXAction *)
(* @return: void *)
(* PUBLIC *)
on ui_action(_selectorOrElement, _action)
	set _element to my resolveSelectorOrElement(_selectorOrElement)
	tell application "System Events"
		tell _element to perform action _action
	end tell
end ui_action

(* Using a default timeout, await return of a UI Element by its selector. *)
(* @accept: UIElementUnresolvedSelector *)
(* @return: UIElement || boolean<false> *)
(* PUBLIC *)
on ui(_selector)
	return my ui_await(_selector, 6)
end ui

(* Get an application process and establish its use as context for `ui_window` and `ui_await_window`. *)
(* @accept: string *)
(* @return: application process *)
(* PUBLIC *)
on ui_process(_processNameOrFalse)
	global __UIProcessContext__
	if _processNameOrFalse is false then
		tell application "System Events" to set __UIProcessContext__ to the first application process whose frontmost is true
	else
		tell application "System Events" to set __UIProcessContext__ to application process _processNameOrFalse
	end if
	
	return __UIProcessContext__
end ui_process

(* Using a default timeout, await return of a window by its path or name, and then establish context. *)
(* @accept: UIElementName || UIElementLoosePath || UIElementPropertyFilter *)
(* @return: window *)
(* PUBLIC *)
on ui_window(_windowPathOrName)
	return my ui_await_window(_windowPathOrName, 6)
end ui_window

(* Await return of a window by its path or name, and then establish context. *)
(* @accept: UIElementName || UIElementLoosePath || UIElementPropertyFilter *)
(* @return: window *)
(* PUBLIC *)
on ui_await_window(_windowPathOrName, _timeout)
	set _processContext to false
	try
		set _processContext to my __UIProcessContext__
	end try
	
	-- establish default process context (frontmost)
	if _processContext is false then my ui_process(false)
	
	global __UISelectorContext__
	set __UISelectorContext__ to my ui_await({my __UIProcessContext__, {"window", _windowPathOrName}}, _timeout)
	
	return __UISelectorContext__
end ui_await_window

(* Using a default timeout, await return of a UI Element by its selector, and then establish context. Pass `false` to clear context*)
(* @accept: UIElementUnresolvedSelector || boolean<false> *)
(* @return: UIElement || boolean<false> *)
(* PUBLIC *)
on ui_context(_selector)
	if _selector is false then
		global __UISelectorContext__
		set __UISelectorContext__ to false
		return
	end if
	
	return my ui_await_context(_selector, 6)
end ui_context

(* Await return of a UI Element by its selector, and then establish context. *)
(* @accept: UIElementUnresolvedSelector, number *)
(* @return: UIElement || boolean<false> *)
(* PUBLIC *)
on ui_await_context(_selector, _timeout)
	global __UISelectorContext__
	tell application "System Events" to set __UISelectorContext__ to my ui_await(_selector, _timeout)
	return my __UISelectorContext__
end ui_await_context

(* Await return of a UI Element by its selector. *)
(* @accept: UIElementUnresolvedSelector, number *)
(* @return: UIElement || boolean<false> *)
(* PUBLIC *)
on ui_await(_selector, _timeout)
	set _resolved to my resolveUiElementSelector(_selector)
	
	set _context to the first item of _resolved
	set _path to the second item of _resolved
	
	global __AwaitUiElementContext__
	global __AwaitUiElementTimeout__
	
	set __AwaitUiElementContext__ to _context
	set __AwaitUiElementTimeout__ to _timeout
	
	tell application "System Events" to return run script "
                                     on run {_caller}
                                     set _ret to false
                                     tell application \"System Events\" 
                                         set _context to _caller's __AwaitUiElementContext__
                                         set _count to 0
                                         repeat until ((" & _path & ") exists) or _count > _caller's __AwaitUiElementTimeout__
                                             set _count to _count + 1
                                             delay 0.5
                                         end repeat
                                         if " & _path & " exists then set _ret to " & _path & "
                                     end tell
                                     return _ret
                                  end" with parameters {me}
end ui_await

on ui_keycode(_sequence)
	if the class of _sequence is list then
		set _code to the first item of _sequence
		set _using to " using {" & the second item of _sequence & "}"
	else
		set _code to _sequence
		set _using to ""
	end if
	run script "
	tell application \"System Events\" to key code " & _code & _using
end ui_keycode

(* Resolve a UIElementSelector or UIElement to a UIElement. *)
(* @accept: UIElementUnresolvedSelector || UIElement *)
(* @return: UIElement *)
(* PRIVATE *)
on resolveSelectorOrElement(_selectorOrElement)
	if the class of _selectorOrElement is list or the class of _selectorOrElement is text then
		return my ui(_selectorOrElement)
	else
		return _selectorOrElement
	end if
end resolveSelectorOrElement

(* Resolve the full path to a UIElement. *)
(* @accept: UIElementUnresolvedPath *)
(* @return: UIElementAbsolutePath *)
(* PRIVATE *)
on resolveUiPathObject(_pathObj)
	-- resolve entry object
	if class of _pathObj as text is "list" then
		-- @format: {Type, Filter || Name}
		set _type to the first item of _pathObj
		set _pathStr to the second item of _pathObj
	else
		-- @format: Name || AbsolutePath
		set _pathStr to _pathObj
		set _type to "UI Element"
	end if
	
	-- resolve path literal
	if (words of _pathStr) contains "first" or (words of _pathStr) contains "is" or (words of _pathStr) contains "_context" or (words of _pathStr) contains "of" then
		-- @format: AbsolutePath || Filter
		if ((words of _pathStr) contains "first") or ((words of _pathStr) contains "of") or ((words of _pathStr) contains "_context") then
			if (words of _pathStr) contains "_context" then
				-- @format: AbsolutePath ("the first button of sheet 1 of _context whose name is \"Go\"")
				set _path to _pathStr
			else
				
				if class of _pathObj as text is "list" then
					-- @format: TypedPath with PropertyFilter
					set _path to "the first " & _type & " of _context whose " & _pathStr
				else
					-- @format: LoosePath ("the first button of sheet 1")
					set _path to _pathStr & " of _context"
				end if
			end if
		else
			-- @format: Filter
			set _path to "the first " & _type & " of _context whose " & _pathStr
		end if
	else
		-- @format: Name
		set _path to "the first " & _type & " of _context " & "whose name is \"" & _pathStr & "\""
	end if
	
	log _path
	
	return _path
end resolveUiPathObject

(* Resolve an unresolved selector's context and full path. *)
(* @accept: UIElementUnresovledSelector *)
(* @return: UIElementSelector *)
(* PRIVATE *)
on resolveUiElementSelector(_selector)
	-- test for element in list-type selector
	if the class of _selector is list then
		set _noElement to false
		try
			get the first reference of _selector
		on error
			set _noElement to true
		end try
	end if
	
	if (class of _selector as text is not "list") or (_noElement is true) then
		-- @format: string || PathObject
		set _context to false -- scope
		
		try
			set _context to my __UISelectorContext__ -- it might not be set
		end try
		
		if the _context is not false then
			set _context to my __UISelectorContext__ -- it's set; use it
		else
			tell application "System Events" to set _context to the first window of (the first application process whose frontmost is true) -- it's not set; use frontmost window
		end if
		set _path to my resolveUiPathObject(_selector)
	else
		-- @format: {Context, string || PathObject}
		
		--test for complex (list-type) path 
		set _complexPath to true
		try
			get the first list of _selector
		on error
			set _complexPath to false
		end try
		
		if _complexPath is true then
			set _path to my resolveUiPathObject(the first list of _selector)
		else
			set _path to my resolveUiPathObject(the first text of _selector)
		end if
		
		set _context to the first reference of _selector
	end if
	
	return {_context, _path}
end resolveUiElementSelector