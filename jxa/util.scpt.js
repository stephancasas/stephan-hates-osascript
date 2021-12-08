/**
 * Get the authoritative user application context.
 * @returns Context
 */
function ctx() {
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  return app;
}

/**
 * Resolve a known unix path using an user/app/script-relative directory.
 * @param relative The relative user/app/script directory.
 * @param absolute The path(s) within the relative directory to resolve.
 * @returns string
 * @requires ctx()
 * @requires exec()
 */
function pathTo(relative = 'me', ...absolute) {
  // resolve to correct path, if editing in script editor
  let appPathPrefix;
  try {
    appPathPrefix =
      ctx().properties().name === 'Script Editor'
        ? ctx()
            .windows[0].document.path()
            .replace(/\.app.*/, '.app')
        : ctx().pathTo().toString();
  } catch (ex) {
    appPathPrefix = ctx().pathTo().toString();
  }
  // TODO: add consideration for standalone scpt files
  const appPath = (arg) => `${appPathPrefix}${arg ? '/' + arg : ''}`;
  const usrPath = (arg) =>
    `${exec('echo ~')}/${arg[0].toUpperCase()}${Array.from(arg)
      .slice(1)
      .join('')
      .toLowerCase()}`;

  const paths = {
    // app paths
    me: { arg: 'Contents/Resources/Scripts/main.scpt', resolver: appPath },
    app: { arg: null, resolver: appPath },
    content: { arg: 'Contents', resolver: appPath },
    contents: { arg: 'Contents', resolver: appPath },
    resources: { arg: 'Contents/Resources', resolver: appPath },
    scripts: { arg: 'Contents/Resources/Scripts', resolver: appPath },

    // user paths
    downloads: { arg: relative, resolver: usrPath },
    desktop: { arg: relative, resolver: usrPath },
    documents: { arg: relative, resolver: usrPath },

    DEFAULT: { arg: relative, resolver: usrPath },
  };

  const { resolver, arg } = paths[relative.toLowerCase()] || paths.DEFAULT;
  return `${resolver(arg)}${[''].concat(absolute || []).join('/')}`;
}

/**
 * Execute a command in the shell, using the paths and environment variables
 * available to the current user's session.
 * @param cmd The command to execute.
 * @returns string | boolean
 * @requires ctx()
 */
function exec(...cmd) {
  const paths = ctx()
    .doShellScript(`cat /etc/paths`)
    .split('\r')
    .map((path) => `export PATH="${path}:$PATH"`)
    .join(';');

  try {
    return ctx().doShellScript(`${paths}; source ~/.zshrc; ${cmd.join(' ')}`);
  } catch (ex) {
    return false;
  }
}

/**
 * Perform a synchronous/blocking fetch operation.
 * @param url The url to read.
 * @returns string
 * @requires ctx()
 * @requires exec()
 */
function fetchSync(url) {
  return ctx().exec(`curl "${url}"`);
}
