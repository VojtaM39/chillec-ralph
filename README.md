# Ralph

Run a Claude Code prompt in a loop with automatic progress tracking.

## Quick Install (devcontainers)

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/ralph/main/ralph-loop.sh -o /usr/local/bin/ralph-loop && chmod +x /usr/local/bin/ralph-loop
```

Replace `OWNER` with your GitHub username.

## Install from Source

```bash
git clone https://github.com/OWNER/ralph.git
cd ralph
make install
```

To install to a custom location:

```bash
make install PREFIX=~/.local/bin
```

Uninstall with `make uninstall`.

## Usage

```bash
ralph-loop "<prompt>" <max_iterations>
```

Example:

```bash
ralph-loop "Refactor the auth module and add tests" 5
```

## How It Works

`ralph-loop` runs Claude Code repeatedly (up to `max_iterations` times) against the same prompt. A progress file (`ralph-progress.md`) persists across iterations so Claude knows what's already been done and doesn't repeat work.

When Claude determines the task is fully complete, it writes a completion marker to the progress file and the loop exits early.

## Devcontainer Setup

Add to your `.devcontainer/devcontainer.json`:

```json
{
  "postCreateCommand": "curl -fsSL https://raw.githubusercontent.com/OWNER/ralph/main/ralph-loop.sh -o /usr/local/bin/ralph-loop && chmod +x /usr/local/bin/ralph-loop"
}
```
