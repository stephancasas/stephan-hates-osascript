# stephan-hates-osascript

A collection of "useful" AppleScript and JXA utilities.

## Introduction

I hate OSAScript.

## AppleScript

I must commend Apple for baking UI scripting right into the fundamentals of their operating system. This feature is unique to macOS, and helps to knock-down access and learning barriers for people with disabilities. Accessibility is one of the areas in which Apple continuously excels and, despite this being an underrated feature of their software and hardware, they are second to none in this respect.

Unfortunately, they found the most bewildering implementation to engage in this pursuit.

To this end, I offer you [`await-ui-selector`](https://github.com/stephancasas/stephan-hates-osascript/blob/main/applescript/await-ui-selector.applescript), which is designed to make short work of waiting for a UI element to be available, after which it can be made actionable via `System Events` or other functions available in the library.

This is based loosely on the JavaScript function `document.querySelector()` — which allows for the retrieval of elements via standard CSS selectors. Of course, macOS doesn't use CSS selectors, but there are frequently-revisited `UI Element` reducers which are used during script authoring. Such reducers may include things like:

> _\*deep breath\*_

```applescript
tell application "System Events" to click the first button of the first splitter group of first window of (the first application process whose frontmost is true) whose name is "Create"
```

That's a lot of text for just one button. Instead, make use of the `await-ui-selector` functions `ui_context()` and `ui_click()`:

```applescript
my ui_context("splitter group")
my ui_click("Create")
```

Isn't that easier? I think so, and I hate AppleScript, so that's saying quite a bit. There are additional functions included which can help to narrow your "selector" context by process or by window. All utilities are explained via inline comments in the library, but here's a few examples:

```applescript
-- EXAMPLE --
-- get a ui element from the frontmost window whose name is "Create"
my ui("Create")

-- EXAMPLE --
-- click a ui element in the frontmost window whose name is "Create"
my ui_click("Create")

-- EXAMPLE --
-- establish the process which will be used to find windows for context, establish the window context, and then click a button whose name is "Create"
my ui_process("FileMaker Pro")
my ui_context({"window", "Database Design Report"})
my ui_click("Create")

-- EXAMPLE --
-- clear the ui process context, and return to using the frontmost application and window as the default context
my ui_process(false)

-- EXAMPLE --
-- clear the ui context, and return to using the frontmost window as the default context
my ui_context(false)

-- EXAMPLE --
-- get a ui element from the provided context whose name is "Create"
tell application "System Events"
	set _window to the first window of application process "FileMaker Pro"

	set _create to my ui({_window, "Create"})
end tell

-- EXAMPLE --
-- get a button from the default context using its name ("Create") and type ("button")
my ui({"button", "create"})

-- EXAMPLE --
-- get a button from the default context using an absolute path
my ui("the first button of _context whose visible is true")

-- EXAMPLE --
-- get a ui element from the default context using a property filter
my ui("selected is true")

-- EXAMPLE --
-- get a button from the default context using a property filter and type
my ui({"button", "selected is true"})

-- EXAMPLE --
-- get a sheet element from the default context using a loose path
my ui("the first button of sheet 1")

-- EXAMPLE --
-- set the process which should be used to find windows using ui_window
my ui_process("FileMaker Pro")

-- EXAMPLE --
-- get a window and use it as context
my ui_window("Database Design Report")
```

## JXA

I don't have much to share here other than some utilities that I routinely recycle in my automation scripts (though I think they're admittedly quite good). At some point, I'd like to port `await-ui-selector` to JXA, but until I can attach it to a billable project, I'll stick with what's tried and true.