# Workspace

This is the default working directory for every terminal session. Claude Code and other agents start here.

## For agents

- **Editing existing files**: If the user refers to a file by path, use that path directly — no need to move or copy anything.
- **Creating a new project**: Create a dedicated subdirectory here (e.g., `./my-app/`) rather than writing files directly into this folder. This keeps each project self-contained and avoids conflicts with other work.
- **Before creating a new project**: Check what directories already exist here (`ls`) so you don't collide with a project the user already started.

## Note

This folder is shared across sessions. Stopping and restarting the server does not clear it — anything built here persists between sessions.
