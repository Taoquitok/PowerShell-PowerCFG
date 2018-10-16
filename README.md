# PowerShell-PowerCFG
PowerShell powercfg wrapper for logging application and driver Power Requests

Brief script to wrap the snapshot results of `powercfg -requests` and convert it into a method of monitoring application and driver Power Requests for use in debugging.

I created this to aid in figuring out why my desktop would never go to sleep. Spam running this manually didn't show what the offending application was. I wrote this wrapper so I could spam the command and easily manage the results, and I found it useful enough I felt I should share it

Though I've set fairly slow defaults for call delay, I've tested this with a 1ms delay without any impact on other applications, so you can use it for effectively continuous reporting with ease. I would suggest closing all applications first and only using a 1ms delay when your machine is idle unless you want an unweildy output variable
