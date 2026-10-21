# Punyforth syntax highlighting for VS Code

This folder is a small VS Code language extension for `.fth`, `.forth`, and
`.4th` files. Non-literal words are highlighted as complete whitespace-delimited
tokens, including punctuation; strings, numbers, character literals, and
comments keep their own scopes.

To try it from this repository:

1. Open `editors/vscode` as a folder in VS Code.
2. Press `F5` to open an Extension Development Host.
3. Open a Forth source file in that window.

To install it into the regular VS Code profile, package this folder as a VSIX
with `@vscode/vsce`:

```bash
npx @vscode/vsce package
code --install-extension punyforth-language-0.1.2.vsix
```
