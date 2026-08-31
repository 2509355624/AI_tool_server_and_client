# AI Tool - Server + Client (mirror monorepo)

This repo mirrors two independent projects so you can clone once on a new machine.

| Folder | Independent repo | Notes |
|--------|------------------|-------|
| `client/` | https://github.com/2509355624/AI_prompt_and_chareter_performer_clientt | Flutter thin client |
| `server/` | https://github.com/2509355624/AI_prompt_and_chareter_performer | Node server (often branch `comfyUi_combine`) |

## Daily workflow

Keep developing in the **two independent repos**. After you commit/push them, update this mirror:

```powershell
cd D:\AI\AI_tool_server_and_client
.\scripts\sync-to-monorepo.ps1
```

Or from an independent repo (push that repo, then sync the matching folder here):

```powershell
# client
cd D:\AI\console_ui_master_app
.\scripts\push-and-mirror.ps1

# server
cd D:\AI\picture_prompt_produce
.\scripts\push-and-mirror.ps1
```

Edit local paths in `scripts\sync-config.ps1` if your disk layout differs.

## Clone elsewhere

```bash
git clone git@github.com:2509355624/AI_tool_server_and_client.git
```

Do **not** put secrets in git. Server `.env` stays local only.

## Notes

- This monorepo is a **mirror**. Do not treat it as the long-term place to edit app code.
- Sync exports each independent repo's **committed HEAD** only (uncommitted files are skipped).
- See `SYNC_INFO.md` for the last mirrored commit SHAs.
