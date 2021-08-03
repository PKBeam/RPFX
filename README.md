# RPFX
**RPFX** is a Discord **R**ich **P**resence client **f**or **X**code that lets you share what you're programming on your Discord status.

<img width="250" alt="rpfx" src="https://user-images.githubusercontent.com/18737124/79639955-388b7400-81d2-11ea-9631-95c9635a95dc.png">

RPFX will display the current file you're working on, as well as your workspace.

In addition, it will also show file icons for the following file types:
- `.swift`
- `.playground`
- `.storyboard`
- `.xcodeproj`
- `.h`
- `.m`
- `.cpp`
- `.c`

If you wish, you can tweak RPFX to use your own Discord application if you want to add custom functionality, such as more file icons.

## Dependencies
RPFX uses [my fork](https://github.com/PKBeam/SwordRPC) of [Azoy's SwordRPC](https://github.com/Azoy/SwordRPC).

## System Requirements
- macOS Big Sur (11.0) 
- Xcode and Discord installed (otherwise this program isn't very useful)

## Usage
When you first start up RPFX, it will prompt you for permission to control Xcode. We don't actually need to *control* Xcode, 
but we need that permission to execute AppleScript to get information on Xcode.

You can verify that RPFX has permissions by opening System Preferences and looking in Security & Privacy under Privacy, then Automation.

That's it, you're done - RPFX will now automatically monitor Xcode.

If you like, you can set RPFX to automatically open on login.
