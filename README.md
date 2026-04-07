# QuickBuf is a nvim plugin to quickly mange active bufffers

> Goal :
- Be incredibly minimal and unintrusive
- Do exactly what I want and nothing more
- I wanted to learn lua more and nvim plugin development seemed like a good way to do this


> To Do:
- add ability to rearrange buffers
- add renaming / mv ? 

> Default keybinds
```
   <leader><leader> = Toggle QuickBuf meun (same as :QuickBufToggle)
    :QuickBufDebug prints the contents of M.active_buffers
```

New Feature:
    - Adding a new entry will attempt to load if that file exists, otherwise it will create it
    - Can now delete parent window, it will replace parent with a blank buffer 
thats all thanks
