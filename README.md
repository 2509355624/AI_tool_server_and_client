# AI 工具合仓（服务端 + Flutter 客户端）

一次克隆即可拿到完整项目，两个目录：

| 目录 | 是什么 |
|------|--------|
| `server/` | Node 服务端：角色扮演聊天、ComfyUI 生图、局域网 API |
| `client/` | Flutter 手机客户端：连你家局域网里的服务端，躺着就能用 |

适合：电脑跑服务端 + Comfy，手机装客户端，在同一 Wi‑Fi 下使用。

---

## 别人怎么用（推荐流程）

```bash
git clone https://github.com/2509355624/AI_tool_server_and_client.git
cd AI_tool_server_and_client
```

### 1. 服务端 `server/`

1. 安装 [Node.js](https://nodejs.org/)（建议 LTS）
2. 本机已能访问 ComfyUI（默认地址按你环境配置）
3. 进入目录并安装依赖：

```bash
cd server
npm install
cp .env.example .env
```

4. 编辑 `.env`，填入你的 API Key、Comfy 地址等（**不要把 `.env` 发给别人或提交到 Git**）
5. 启动：

```bash
node server.js
```

记下电脑的局域网 IP（例如 `192.168.0.128`）和端口（默认多为 `3000`）。  
手机和电脑必须在同一 Wi‑Fi。

### 2. 客户端 `client/`

1. 安装 [Flutter](https://docs.flutter.dev/get-started/install)
2. 进入目录：

```bash
cd client
flutter pub get
```

3. 用 USB 调试或无线调试连上手机，运行：

```bash
flutter run
```

4. 在 App 设置里把服务地址改成你的局域网地址，例如：

`http://192.168.0.128:3000`

之后即可在手机上聊天、生图（具体能力以当前服务端功能为准）。

---

## 目录说明（一句话）

- **server**：大脑和算力入口（AI / Comfy 密钥只放在服务端 `.env`）
- **client**：薄客户端，只连你的局域网服务，不把密钥写进手机 App

有问题先确认：服务端已启动、防火墙放行端口、手机与电脑同一局域网、客户端里的 `serverUrl` 填对。
