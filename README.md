# Android Wii U
Turn your Android device into a Wii U GamePad - play dual screen games with your Android device being the bottom screen, and your PC/Laptop display being the top screen. ENTIRERLY VIBECODED, anyone is welcome to make their own slopless version

---------------

## Android Wii U - First Time Setup:
- Download scrcpy and extract somewhere on your PC (you can doubleclick on "Download scrcpy" to open the GitHub page)
- Run "Install_ADB(RunAsAdministrator)"... as an administrator of course (right click)
- Run "First_Time_Pair" and follow the provided instructions
- Run "Android_WiiU"

## Android Wii U - Daily Use
- Run "Android_WiiU"

If wireless connection fails, go to
Settings -> Developer Options -> Wireless Debugging
and make sure Wireless Debugging is enabled. Sometimes it can disable itself

If you want to change the resolution and/or bitrate of the virtual display/second screen go to wiiu_config.txt

## ! IMPORTANT !
When you've had enough gaming and want to close Android Wii U, go to your Android device's home screen FIRST.
This is the best guarantee that your home screen icon layout won't randomly disappear (this issue doesn't seem to affect gaming frontends or third party launchers).
Then close Android Wii U and scrcpy.

---------------

If you want to use a wired connection instead, just plug in your Android device and make sure USB Debugging is enabled on it.

---------------

Other tools included:
- "x_ADB_Connection_Only" - connects your Android device to your PC
- "Reset_ADB" - resets the ADB connection/server, useful if something fails
- "github_apk_installer(WIRED_ONLY)" - while your Android device and PC are connected, you can use this to install apps on your Android device by pasting in a GitHub link. Only works via wired USB connection and Wireless Debugging disabled
- "Useful repos" - list of useful GitHub repositories, you can use it alongside "github_apk_installer(WIRED_ONLY)"
