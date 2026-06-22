# Daily Notes

Build all daily Markdown notes into an EPUB, ordered by filename:

```sh
./build-epub.sh
```

The output is `daily-notes.epub`. The script uses local `pandoc` if installed,
or Docker otherwise. Custom metadata and output paths are supported:

```sh
./build-epub.sh --title "My Daily Notes" --author "Your Name" --output notes.epub
```

Pass Markdown paths at the end of the command to build an EPUB from only those
files. Run `./build-epub.sh --help` for all options.
