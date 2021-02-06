# 4dbisect

test versions of 4d to find where a bug occurs


## how to build

its a swift command line, so if not installed, install xcode or swift runtime

```bash
swift build -c release
```

Result in `.build/release/4dbisect`

You could install it to `/usr/local/bin` for instance (using `sudo cp`) to use it everywhere

## how to use

```bash
USAGE: 4dbisect [--min <min>] [--max <max>] [--path <path>] <script>

ARGUMENTS:
  <script>                Path of script to test. 

OPTIONS:
  -m, --min <min>         The minimum version. 
  -M, --max <max>         The maximum version. 
  --path <path>           Path that contains versionned folder 
  -h, --help              Show help information.
```

```bash
4dbisect --min 225555 --max 289999 --path "/Volumes/ENGINEERING/Products/Compiled/Build/Main" ./test.sh
parameters: 225555 ➡ 289999
available: 238629 ➡ 261398
test: 238629 ✅
test: 261398 ❌
available no skip: 238629 ➡ 261398
test: 251291 ❌
test: 245065 ❌
test: 241271 ✅
test: 243242 ❌
test: 242181 🌀
test: 242129 ❌
test: 241673 ✅
test: 241902 ✅
test: 241983 ❌
test: 241919 🌀
result: 241902 ➡ 241983
```

- ✅ good  
- ❌ bad 
- 🌀 skip

### The script

The script will receive the version number and the file path, the one you provide with `--path`

In script you must return 0 if all is ok, and any other code if failed

> Use 125 (like git bisect) to set that the version could not be tested, for instance the 4D zip is not available.

#### example 

An example of script could be found in `test.sh`

If you use it, maybe change path of your database inside, by defaulf it use `$HOME/Bisect`

You must launch your test and quit 4d after that, in database method `onStart` you could put

```4d
ON ERR CALL("onError")
test
QUIT 4D()
```

with `test` your method that could use `ASSERT` in case of bug

Then your base must create an `error` file in `Resources` folder on error when your test failed. 

In `onError` (see `onStart`)

```4d
Folder(fk resources folder).file("error").setText("")
```

> If 4D and `QUIT 4D` allow to set the process exit code this file creation will not be necessary

## Tips

If you want to go further with sources and find the exact commit, you must use `git bisect` but you need to compile 4D at each checkout
