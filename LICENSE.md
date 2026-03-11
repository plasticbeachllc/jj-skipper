# MIT License

Copyright (c) 2026 Plastic Beach LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## Acknowledgments

This project draws inspiration and ideas from the following works:

| Project | Author | License | What we drew from |
|---------|--------|---------|-------------------|
| [kawaz/claude-plugin-jj](https://github.com/kawaz/claude-plugin-jj) | kawaz | MIT | Three-layer architecture (hook/skill/agent), PreToolUse guard pattern, `:;git` escape hatch, jj expert knowledge, non-interactive fileset patterns |
| [kalupa/jj-workflow](https://github.com/kalupa/jj-workflow) | kalupa | No explicit license | WorktreeCreate/WorktreeRemove hook bridge to jj workspaces, `/develop` slash command, `/jj-commit` with pre-commit validation, session-start config inspection |
| [danverbraganza/jujutsu-skill](https://github.com/danverbraganza/jujutsu-skill) | Dan Verbraganza | MIT | "Describe first, then code" workflow philosophy, `allowed-tools` restriction pattern, atomic commit emphasis |
| [alexlwn123/jj-claude-code-plugin](https://github.com/alexlwn123/jj-claude-code-plugin) | alexlwn123 | No explicit license | Config import command pattern, Context7 delegation for edge cases |

All implementations in jj-skipper are original. Where upstream repos lack an explicit license, our use is limited to ideas and patterns (not copyrightable expression).
