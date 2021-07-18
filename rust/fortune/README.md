# Fortune

Serve random fortunes via HTTP.

## Usage

Begin serving fortunes from the current working directory.

```
$ fortune
Listening on http://127.0.0.1:5000
```

Fortunes are automatically refreshed every 30 seconds.

## Fortunes

Expects a `fortunes` file in the current working directory.

This should be a list of UTF-8 encoded fortunes separated by `\n%\n`.

Example:

```
"Curiouser and curiouser"
                -- Lewis Carroll [Alice in Wonderland]
%
Reply hazy, try again.
%
Q:      What is yellow and extremely dangerous?
A:      Shark infested custard.
```