# Maintainer only (not for people who just clone this repo)

This combined repo is a normal GitHub repo with `client/` and `server/`.
It is what you share. Outsiders only clone this one repo.

Your two independent repos are for YOUR daily development.
When those change, refresh the folders here, then push this repo.

## Sync (your machine)

Edit paths in `sync-config.ps1` if needed, then:

```powershell
cd D:\AI\AI_tool_server_and_client
.\scripts\sync-to-monorepo.ps1
```

Or after pushing an independent repo:

```powershell
# client
cd D:\AI\console_ui_master_app
.\scripts\push-and-mirror.ps1

# server
cd D:\AI\picture_prompt_produce
.\scripts\push-and-mirror.ps1
```

## What this is / is not

- GitHub has no special "mount" you must turn on for this.
- This is not submodule mounting for end users.
- End users see real `client/` and `server/` files in one clone.
- Sync = you copy the latest committed trees into those folders and push.
