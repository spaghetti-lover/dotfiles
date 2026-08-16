### Read

Read a web page like a book (still some limitations but yeah, using it for fun)

- install some package
``` shell
  npm install -g @mozilla/readability
  npm install -g jsdom
  npm install -g qutejs
``` 

- Add node modules the path (.zshrc):
export NODE_PATH=$NODE_PATH:$(npm root -g)

- Make a dir in the application folder then copy reading file to
```shell
mkdir -p ~/Library/Application\ Support/qutebrowser/userscripts
```

```shell
cp ~/.qutebrowser/userscript/readability-js ~/Library/Application\ Support/qutebrowser/userscripts/readability-js
```

- Add execute mod
- Set path for browser
```shell
:set qt.environ '{"PATH": "/opt/homebrew/bin", "NODE_PATH": "/opt/homebrew/lib/node_modules"}'
```
- Then read
```shell
:spawn --userscript readability-js
```
