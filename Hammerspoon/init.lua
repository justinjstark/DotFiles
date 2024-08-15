hs.application.enableSpotlightForNameSearches(true)
-- hs.loadSpoon("MicMute")
-- hs.hotkey.bind({ 'alt', 'ctrl', 'cmd' }, '/', function() spoon.MicMute:toggleMicMute() end)

-- Adapted from https://www.linkedin.com/pulse/easy-unmute-zoom-teams-macos-global-hotkey-anatol-ulrich/
function toggleMute()
  local zoom = hs.application'Zoom'
  if zoom then
    hs.eventtap.keyStroke({"command", "shift"}, "a", nil, zoom)
  end

  local slack = hs.application'Slack'
  if slack then
    hs.eventtap.keyStroke({"command", "shift"}, "space", nil, slack)
  end

  if not slack and not zoom then
    hs.alert.show('Neither Zoom nor Slack are running')
  end
end

hs.hotkey.bind({"control", "option", "command", "shift"}, "a", toggleMute)



-- Launcher hotkeys
local hotkeys = {
  {"f", "Firefox", "/Applications/Firefox.app"},
  {"z", "Zoom", "/Applications/zoom.us.app"},
  {"s", "Slack", "/Applications/Slack.app"},
  {"c", "Code", "/Applications/Visual Studio Code.app"}
}

local function tableContainsWindow(table, window)
  for _, currentWindow in pairs(table) do
    if currentWindow:id() == window:id() then
      return true
    end
  end
  return false
end

local function cycleWindowsAcrossProcesses(app)
  local windows = {}
  local allWindows = hs.window.visibleWindows()
  for _, win in ipairs(allWindows) do
      if win:application():name() == app then
          table.insert(windows, win)
      end
  end

  -- We have to sort otherwise we always get a 2-cycle.
  table.sort(windows, function(window1, window2) return window1:id() > window2:id() end)

  -- For debugging
  -- for _, window in ipairs(windows) do
  --   hs.alert.show(window:application():bundleID() .. ':' .. window:id())
  -- end

  local currentWindow = hs.window.focusedWindow()
  local nextWindow = nil
  for i, window in ipairs(windows) do
    if window == currentWindow then
      nextWindow = windows[(i % #windows) + 1]
      goto focusNextWindow
    end
  end
  nextWindow = windows[1] -- In case the current focused window was not visible. Lua tables are 1-indexed.

  :: focusNextWindow ::
  if nextWindow then
    nextWindow:focus()
  end
  
  :: endfunction ::
end

-- Function to cycle through open windows of the specified application
local function cycleWindows(app)
  local targetApp = hs.application.get(app)
  if targetApp then
    local appWindows = targetApp:allWindows()
    if #appWindows > 1 then
      local currentWindow = hs.window.focusedWindow()
      local nextWindow = nil
      for i, window in ipairs(appWindows) do
        if window == currentWindow then
          nextWindow = appWindows[(i % #appWindows) + 1]
          break
        end
      end
      if nextWindow then
        nextWindow:focus()
      end
    end
  end
end

-- Bind the hotkeys to their respective functions
for _, entry in ipairs(hotkeys) do
  local key = entry[1]
  local app = entry[2]
  local appPath = entry[3]
  hs.hotkey.bind({"control", "option", "command", "shift"}, key, function()
    local targetApp = hs.application.get(app)
    local frontmostApp = hs.application.frontmostApplication()
    local frontmostWindow = hs.window.frontmostWindow()
    if targetApp and frontmostApp and (frontmostApp:bundleID() == targetApp:bundleID() or not frontmostWindow:isVisible()) then
      cycleWindowsAcrossProcesses(app)
    else
      hs.application.launchOrFocus(appPath)
    end
  end)
end
