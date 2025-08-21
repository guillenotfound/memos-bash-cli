# memos-cli-bash

A simple **Bash CLI tool** to interact with your [**usememos**](https://usememos.com/) server.

It lets you log in, create, and edit memos directly from the terminal using your favorite text editor (via `$EDITOR`).

## Requirements

Make sure you have the following installed:

- [**jq**](https://stedolan.github.io/jq/)
- [**fzf**](https://github.com/junegunn/fzf)
- [**curl**](https://curl.se/)
- (optional) `$EDITOR` (default: `vi`)

---

## Installation

Clone the repo and make the script executable:

```sh
git clone https://github.com/guillenotfound/memos-cli-bash.git

cd memos-cli-bash
chmod +x memos.sh

ln -s "$(pwd)/memos.sh" ~/.local/bin/memos
```

> Make sure `~/.local/bin` is in your `$PATH` for the executable to work.

---

## Commands

- `login`
  Log in to your memos server. You’ll be asked for:
  - **Server URL** (e.g. `http://localhost:5230`)
  - **API Key** (from your Memos settings)  
    Credentials are stored in `.env`.

- `new`
  Create a **new memo**. Opens `$EDITOR`, then posts the content.

- `edit [string]`
  Search and edit an existing memo.
  - If `[string]` matches multiple memos, you can fuzzy-select with `fzf`.
  - If it matches one memo, it opens directly in `$EDITOR`.

- `help`
  Show command usage.
