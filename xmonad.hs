import Data.List
import XMonad hiding ( (|||) ) -- don't use the normal ||| operator
import XMonad.Config.Desktop
import XMonad.Layout.LayoutCombinators -- use the one from LayoutCombinators instead
import XMonad.Layout.ToggleLayouts
import XMonad.Layout.ThreeColumns
import XMonad.Actions.SpawnOn
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.EwmhDesktops
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys, additionalMouseBindings)
import Graphics.X11.ExtraTypes.XF86
import System.IO

import qualified XMonad.StackSet as W
-- http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Layout-NoBorders.html
import XMonad.Layout.NoBorders
-- http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Layout-LayoutCombinators.html

-- Rebind Mod to the Windows key
myModMask = mod4Mask

myTerminal = "termite"
tall = Tall 1 (3/100) (1/2)
threeCol = ThreeCol 1 (3/100) (0.36) -- just enough space for 100 columns wide in vim
myLayout = avoidStruts $ smartBorders $ toggleLayouts Full tall ||| toggleLayouts Full threeCol ||| toggleLayouts Full (Mirror tall)

myBorderWidth = 2

windowPlacement = composeAll [
        -- use `xprop` to get window information

        -- Shift Hangouts video calls to the "videos" desktop.
        -- className =? "Chromium" <&&> role =? "pop-up" <&&> fmap (isInfixOf "Untitled") title --> doShift "video",
        className =? "Chromium" <&&> fmap (isInfixOf "Google Play Music") title --> doShift "9",

        -- Fix for GIMP windows
        className =? "Gimp" --> doFloat,

        role =? "send to play" --> doShift "play",
        role =? "send to wrk" --> doShift "wrk",
        role =? "send to test" --> doShift "test"
    ] where role = stringProperty "WM_WINDOW_ROLE"

-- https://github.com/hcchu/dotfiles/blob/master/.xmonad/xmonad.hs
muteAndShowVolume = "set_volume.py toggle-mute; show-volume.sh"
changeVolume s = "set_volume.py " ++ s ++ "; show-volume.sh"

-- https://obsproject.com/forum/threads/hotkey-to-mute-mic-input.22852/
toggleMicMute = "pactl set-source-mute $(pacmd list-sources|awk '/\\* index:/{ print $3 }') toggle; show-mic-mute.sh"
changeBrightness s = "sudo change-brightness.py " ++ s ++ "; show-brightness.sh"

fullscreenChrome :: X ()
fullscreenChrome = do
    sendMessage ToggleStruts
    spawn "sleep 0.1 && xdotool key --clearmodifiers F11"
    return ()

altMask = mod1Mask
myKeys =
    [
        -- http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Hooks-ManageDocks.html
        ((myModMask, xK_b), sendMessage ToggleStruts),
        ((myModMask, xK_F11), fullscreenChrome),

        -- Launch a terminal (changed from return to semicolon)
        ((myModMask .|. shiftMask, xK_semicolon), spawn myTerminal),

        -- Swap the focused window and the master window
        -- The default uses return, but semicolon is easier, and
        -- doesn't conflict with browers =)
        ((myModMask, xK_semicolon), windows W.swapMaster),

        -- Toggle between.
        ((myModMask, xK_space), sendMessage ToggleLayout),

        -- Go to next layout.
        ((myModMask, xK_t), sendMessage NextLayout),

        -- We stole this shortcut above (to emulate DWM's monocle shortcut)
        -- Lets add a shift modifier.
        -- Move focus to the master window
        ((myModMask .|. shiftMask, xK_m), windows W.focusMaster),

        -- Force window back to tiling mode
        ((myModMask .|. shiftMask, xK_t), withFocused $ windows . W.sink),

        -- Run demenu2 with custom font
        ((myModMask, xK_p), spawn "dmenu_run -fn 'Ubuntu Mono Regular:size=9:bold:antialias=true'"),

        ((0, xF86XK_AudioMute), spawn muteAndShowVolume),
        ((0, xF86XK_AudioRaiseVolume), spawn $ changeVolume "5+"),
        ((0, xF86XK_AudioLowerVolume), spawn $ changeVolume "5-"),
        ((0, xF86XK_AudioMicMute), spawn toggleMicMute),

        ((0, xF86XK_MonBrightnessDown), spawn $ changeBrightness "5%-"),
        ((0, xF86XK_MonBrightnessUp), spawn $ changeBrightness "5%+"),
        ((0, xF86XK_HomePage), spawn $ changeBrightness "5%-"),
        ((0, xF86XK_Search), spawn $ changeBrightness "5%+"),
        ((shiftMask, xK_F5), spawn "colorscheme dark"),
        ((shiftMask, xK_F6), spawn "colorscheme light"),

        -- Prompt the user for an area of the screen
        -- note the sleep 0.2 as a workaround for the ancient:
        --  https://code.google.com/p/xmonad/issues/detail?id=476
        ((0, xK_Print), spawn "sleep 0.2; jscrot --select"),
        ((controlMask, xK_Print), spawn "jscrot --video"),
        ((shiftMask, xK_Print), spawn "jscrot"),

        ((controlMask .|. altMask, xK_Left), spawn "xrandr -o right && setbg"),
        ((controlMask .|. altMask, xK_Right), spawn "xrandr -o left && setbg"),
        ((controlMask .|. altMask, xK_Down), spawn "xrandr -o normal && setbg"),
        ((controlMask .|. altMask, xK_Up), spawn "xrandr -o inverted && setbg"),

        -- Create our own play/pause button.
        ((myModMask, xK_s), spawn "sleep 0.1 && xdotool key --clearmodifiers XF86AudioPlay"),
        ((myModMask, xK_d), spawn "sleep 0.1 && xdotool key --clearmodifiers XF86AudioNext"),
        ((myModMask .|. shiftMask, xK_d), spawn "sleep 0.1 && xdotool key --clearmodifiers XF86AudioPrev"),

        ((myModMask, xK_a), spawn "autoperipherals"),
        ((myModMask .|. shiftMask, xK_a), spawn "mobile.sh")
    ]

main = do
    xmproc <- spawnPipe "xmobar"
    xmonad $ ewmh desktopConfig {
        manageHook = manageDocks <+> manageSpawn <+> windowPlacement <+> manageHook desktopConfig,
        layoutHook = myLayout,
        logHook = logHook desktopConfig <+> dynamicLogWithPP xmobarPP {
            ppOutput = hPutStrLn xmproc,
            ppTitle = xmobarColor "green" "" . shorten 100
        },

        modMask = myModMask,
        XMonad.terminal = myTerminal,
        XMonad.borderWidth = myBorderWidth,
        workspaces = ["web", "play", "wrk", "test", "video", "todo", "7", "8", "9"]
        -- startupHook = do
            -- spawnOn "web" "chromium"
            -- spawnOn "play" "roxterm -e \"bash -c '(cd gitting; bash)'\""
            -- spawnOn "wca" "chromium --profile-directory='Profile 1'"
    } `additionalKeys` myKeys
      `additionalMouseBindings` [ ((0, 9), \_ -> spawn "jscrot --select") ]
