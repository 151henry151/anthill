# Cursor agent shell: troubleshooting (empty output / commands “do nothing”)

## What we see when it’s broken

- The **Shell** tool reports **exit code 0** but **no stdout/stderr** (and very fast “0 ms” timing).
- Commands that should create files (e.g. `echo x > ./probe.txt`) **do not produce those files** in the workspace.
- **Read/Write** tools still work on the same folders.

That usually means the agent’s shell is **not running in the same filesystem view as the workspace**, or **sandbox / policy** is blocking real effects, not that your project is misconfigured.

## 1. Cursor Settings (first place to fix)

Open **Cursor Settings** (Ctrl+,) and search for:

- **Agent**
- **Sandbox**
- **Terminal**

Check specifically:

- **Run in Sandbox** — When enabled (Cursor 2.0+ on supported plans), the agent may run commands in a **kernel sandbox**. If behavior is wrong for your workflow, **turn sandbox off** for local development and rely on approvals, or use the mix of options below (see [Agent Sandboxing announcement](https://forum.cursor.com/t/agent-sandboxing-available-in-cursor-2-0/139449)).
- **Ask Every Time** — If you prefer strict control, you can force approval per command instead of auto-sandbox.
- **Allow git writes without approval** / **Auto-run network access** — Adjust if git or network commands are blocked.

Official references:

- [Agent Terminal](https://cursor.com/docs/agent/terminal)
- [sandbox.json](https://cursor.com/docs/reference/sandbox)
- [Agent hooks](https://cursor.com/docs/agent/hooks) (for replacing older allowlist workflows)

## 2. Workspace `sandbox.json` (optional)

If your team uses project-level sandbox rules, see the [sandbox.json reference](https://cursor.com/docs/reference/sandbox). A bad or overly strict file can make the agent’s environment diverge from what you expect.

## 3. Remote SSH / different machine

If the workspace is **Remote SSH**, confirm the agent is executing on the **remote** host (where `/home/henry/dev/anthill` lives). If anything runs on your **local** machine, paths will not match.

## 4. Verification script (run yourself in the integrated terminal)

From the repo root, in Cursor’s **Terminal** panel (not the agent):

```bash
echo "manual_terminal_ok" > .cursor_manual_shell_probe.txt
cat .cursor_manual_shell_probe.txt
```

If that works, your machine and repo are fine; the issue is **agent execution policy/environment**, not Git or CMake.

Then ask the agent to run the **same** command. If the file **does not** appear when the agent runs it, focus on **Cursor Agent + Sandbox** settings above.

## 5. What the agent should do when shell is unreliable

Prefer **Read** / **Write** / **StrReplace** for file edits, and only use Shell when you’ve confirmed it affects the workspace (e.g. after disabling sandbox or approving “run outside sandbox”).
