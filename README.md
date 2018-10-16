# PowerShell-PowerCFG
PowerShell powercfg wrapper for logging application and driver Power Requests

Brief script to wrap the snapshot results of `powercfg -requests` and convert it into a method of monitoring application and driver Power Requests for use in debugging.

I created this to aid in figuring out why my desktop would never go to sleep. Spam running this manually didn't show what the offending application was. I wrote this wrapper so I could spam the command and easily manage the results, and I found it useful enough I felt I should share it
