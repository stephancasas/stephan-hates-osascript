#!/usr/bin/env osascript -l JavaScript

function run(argv) {
  // --------------------------------- Setup -------------------------------- //

  ObjC.import('Cocoa');
  const App = Application.currentApplication();
  App.includeStandardAdditions = true;

  // ---------------------------- Cursor Helper ----------------------------- //

  const Cursor = {
    __events: {
      button: {
        left: {
          drag: $.kCGEventLeftMouseDragged,
          down: $.kCGEventLeftMouseDown,
          up: $.kCGEventLeftMouseUp,
        },
        right: {
          down: $.kCGEventRightMouseDown,
          up: $.kCGEventRightMouseUp,
        },
      },
      move: $.kCGEventMouseMoved,
      scroll: $.KCGEventScrollWheel,
    },
    __eventFactory(type, pos) {
      var event = $.CGEventCreateMouseEvent(
        $(),
        type,
        pos,
        $.kCGMouseButtonLeft,
      );
      $.CGEventPost($.kCGHIDEventTap, event);
      delay(0.01);
    },
    get position() {
      const screenH = $.NSScreen.mainScreen.frame.size.height;
      const pos = $.NSEvent.mouseLocation;

      return [
        parseInt(pos.x),
        // coordinates need the screen height minus the coordinates obtained
        screenH - Math.trunc(pos.y),
      ];
    },
    get x() {
      return Cursor.position[0];
    },
    get y() {
      return Cursor.position[1];
    },
    leftButton: {
      down([x = Cursor.x, y = Cursor.y]) {
        Cursor.__eventFactory(Cursor.__events.button.left.down, { x, y });
      },
      up([x = Cursor.x, y = Cursor.y]) {
        Cursor.__eventFactory(Cursor.__events.button.left.up, { x, y });
      },
      click([x = Cursor.x, y = Cursor.y]) {
        Cursor.leftButton.down([x, y]);
        Cursor.leftButton.up([x, y]);
      },
    },
    rightButton: {
      down([x = Cursor.x, y = Cursor.y]) {
        Cursor.__eventFactory(Cursor.__events.button.right.down, { x, y });
      },
      up([x = Cursor.x, y = Cursor.y]) {
        Cursor.__eventFactory(Cursor.__events.button.right.up, { x, y });
      },
      click([x = Cursor.x, y = Cursor.y]) {
        Cursor.rightButton.down([x, y]);
        Cursor.rightButton.up([x, y]);
      },
    },
    drag([x, y], from = [Cursor.x, Cursor.y]) {
      Cursor.leftButton.down(from);
      Cursor.__eventFactory(Cursor.__events.button.left.drag, { x, y });
      delay(0.5);
      Cursor.leftButton.up([x, y]);
    },
    move([x, y]) {
      Cursor.__eventFactory(Cursor.__events.move, { x, y });
    },
  };

  // --------------------------- Context Helpers ---------------------------- //

  const FrontmostApp = () =>
    Application('System Events').applicationProcesses.whose({
      frontmost: true,
    })()[0];
  const FrontmostWindow = () => FrontmostApp().windows.at(0);

  // ----------------------- Mission Control Helpers ------------------------ //

  /**
   * Get the position of a Mission Control desktop broker.
   * @param desktop The desktop number to find.
   */
  const DesktopBrokerPosition = (desktop = 1) => {
    // jiggle cursor at top of display to reveal desktop brokers
    const restore = Cursor.position;
    Cursor.move([10, 10]);
    Cursor.move([20, 10]);

    // restore cursor position
    Cursor.move(restore);

    return Application('System Events')
      .applicationProcesses.byName('Dock')
      .groups.byName('Mission Control')
      .groups.at(0)
      .groups.byName('Spaces Bar')
      .lists.at(0)
      .buttons.byName(`Desktop ${desktop}`)
      .properties().position;
  };

  /**
   * Get the position of a Mission Control window broker.
   * @param windowTitle The title of the window to find.
   */
  const WindowBrokerPosition = (windowTitle) =>
    Application('System Events')
      .applicationProcesses.byName('Dock')
      .groups.byName('Mission Control')
      .groups.at(0)
      .groups.at(0)
      .buttons.byName(windowTitle)
      .properties().position;

  // ---------------------------- Script Actions ---------------------------- //

  // store the window to be moved and cursor position for restore
  const windowTitle = FrontmostWindow().title();
  const restoreCursor = Cursor.position;

  // start mission control, delay for ui animation before getting positions
  Application('Mission Control').launch();
  delay(0.5);

  //get positions of the window and desktop brokers
  const [desktopX, desktopY] = DesktopBrokerPosition(1);
  const [windowX, windowY] = WindowBrokerPosition(windowTitle);

  // move cursor to the top of display so that we can see the spaces ui elements
  Cursor.move([10, 10]);

  // jiggle the cursor over the window broker to activate its state
  Cursor.move([windowX + 30, windowY + 30]);
  delay(0.2);
  Cursor.move([windowX + 40, windowY + 40]);
  delay(0.2);
  Cursor.move([windowX + 30, windowY + 30]);

  // move the window broker to the target space, await ui animation
  Cursor.drag([desktopX + 10, desktopY + 10], [windowX + 30, windowY + 30]);
  delay(0.5);

  // click the target space to switch focus
  Cursor.leftButton.click([desktopX + 10, desktopY + 10]);

  // restore cursor
  Cursor.move(restoreCursor);
}
