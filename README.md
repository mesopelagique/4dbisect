# 4dbisect

[![language][code-shield]][code-url]
[![check][check-shield]][check-url]
[![release][release-shield]][release-url]

Test versions of 4d app to find when a bug occurs.

It use dichotomie, so avoid flaky test.

## How to build yourself

Its a swift command line, so if not installed, install Xcode or swift runtime.

Then in project path run

```bash
swift build -c release
```

Result of build will be in `.build/release/4dbisect`

### Put in PATH 

You could install it to `/usr/local/bin` for instance to use it everywhere (or set .build/release/4dbisect in your $PATH)

```bash
sudo cp .build/release/4dbisect /usr/local/bin
````

## How to install the released version

For security reason its better to build yourself but you could download the latest release [![release][release-shield]][release-url]

or launch this command

```bash
sudo curl -sL https://mesopelagique.github.io/4dbisect/.github/4dbisect.sh | bash
```

This will install `4dbisect` to `/usr/local/bin`

## How to use

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

The script will receive as arguments the version number and the file path, the one you provide with `--path` option.

In script you must return `0` if all is ok, and any other code if failed.

> Use 125 (like git bisect) to set that the version could not be tested, for instance the 4D zip is not available.

#### example 

An example of script could be found in [`test.sh`](test.sh)

If you use it, consider changing the path of your database inside the script (by default it use `$HOME/Bisect` path).

A demo database could be found in [`Bisect.zip`](Bisect.zip).

You must launch your test and quit 4d after that, in database method `onStart` you could put

```4d
ON ERR CALL("onError") // handle any error ie. ASSERT
test
If (Not(Shift down)) // so you could open your db without the auto quit
  QUIT 4D()
End if
```

with `test` your method that could use `ASSERT` in case of failure.

Then your base must create an `error` file in `Resources` folder on error when your test failed. 

In `onError` (see `onStart` to choose the name)

```4d
Folder(fk resources folder).file("error").setText("")
```

> If 4D and `QUIT 4D` allow to set the process exit code this file creation will not be necessary

## Tips

If you want to go further with sources and find the exact commit, you must use `git bisect` but you need to compile 4D at each checkout

More information about [bisection](https://en.wikipedia.org/wiki/Bisection_(software_engineering))

---

[<img src="https://mesopelagique.github.io/quatred.png" alt="mesopelagique"/>](https://mesopelagique.github.io/)

[code-shield]: https://img.shields.io/static/v1?label=language&message=swift&color=orange
[code-url]: http://swift.org/
[release-shield]: https://img.shields.io/github/v/release/mesopelagique/4dbisect
[release-url]: https://github.com/mesopelagique/ClassStoreDiagram/4dbisect/latest
[check-shield]: https://github.com/mesopelagique/4dbisect/workflows/Swift/badge.svg
[check-url]: https://github.com/mesopelagique/4dbisect/actions?query=workflow%3ASwift
[release-shield]: https://img.shields.io/github/v/release/mesopelagique/4dbisect
[release-url]: https://github.com/mesopelagique/4dbisect/releases/latest/download/4dbisect.zip
