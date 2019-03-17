# Jekyll Google+ importer

This script takes a [Takeout export of your Google+ Stream](https://takeout.google.com/settings/takeout/custom/stream)
and converts it into [Jekyll posts](https://jekyllrb.com/docs/posts/) suitable for hosting on a static blog.

**NOTE:** You must select `JSON` as the Posts export format when archiving your Google+ Stream. The default HTML format
is not supported

## Requirements

- Python 3
- lxml

## Usage

```bash
$ cd _posts
$ path/to/import.py path/to/Takeout
```
