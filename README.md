# PowerShell-PowerCFG

PowerShell powercfg wrapper for logging application and driver power requests

Brief script to wrap the snapshot results of `powercfg /requests` and convert it into a method of monitoring application and driver power requests for use in debugging.

## Background

I created this to aid in figuring out why my desktop would never go to sleep. Spam running this manually didn't show what the offending application was, so I wrote this wrapper to spam the command and easily manage the results. The end result was useful enough I felt I should share it even though it didn't figure out that a usb input was erroneously keeping my desktop awake

Though I've set fairly slow defaults for call delay, I've tested this with a 1ms delay without any noticable impact on other applications, so you can use it for effectively continuous reporting with ease. I would suggest closing all applications first and only using a 1ms delay when your machine is idle unless you want an unweildy amount of results
