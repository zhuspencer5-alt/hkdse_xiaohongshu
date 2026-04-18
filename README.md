# 質心教育 · 小红书营销自动化 Studio

> 多 Agent 协作 + ByteDance Seedream 4.5 出图. 一次启动 N 个选题, 回来挑顺眼的批量发.

![status](https://img.shields.io/badge/status-v1.5-brightgreen) ![python](https://img.shields.io/badge/python-3.11+-blue) ![license](https://img.shields.io/badge/license-MIT-blue)

---

## 这是什么

为 **質心教育科技有限公司** HKDSE 推广搭建的小红书内容工厂.

### 核心能力 (v1.5)

| 能力 | 说明 |
|---|---|
| 🤖 **5 + 1 个专职 agent** | TrendScout 抓爆款 → Strategist 出 brief → Writer 写正文 → Critic 审稿 → Reviser 修订 → CoverDesigner 出图 |
| 🎨 **AI 自动出图** | ByteDance **Seedream 4.5**, 中文小字渲染准确, 1 张封面 + 2 张正文图 |
| 📚 **自动事实查证** | Critic 反查 `[source: ]` 占位, 自动用真实 URL 回填 |
| 📦 **批量模式** | 输入 10 个选题, 并发 3 个 workflow, 跑完自动入草稿 |
| 🚀 **一键批量发布** | 草稿勾选 → 顺序间隔发到小红书, 失败可重试 |
| 📊 **实时事件流** | SSE 推所有 agent 事件 (tool_call / llm_response / critic_score) |

详细使用流程见 **[docs/tutorial.pdf](docs/tutorial.pdf)** (8 页 PDF 教程).

---

## 快速上手 (推荐: 一键脚本, 3 步)

> 💡 适用 macOS (Apple Silicon / Intel) 和 Linux. Windows 同事请用 WSL 或参考下方手动安装.

### Step 0 · 准备一个 OpenRouter Key

去 [openrouter.ai](https://openrouter.ai) 注册, 拿一个 `sk-or-v1-...` 开头的 key. 充 \$10 够跑 50 篇.

(可选, 装了更好: [Tavily](https://tavily.com) 让 Critic 自动核查事实, [Jina](https://jina.ai/reader) 抓网页正文)

### Step 1 · clone + 一键装

```bash
git clone https://github.com/Lancelot2004314/xhs-hkdse.git
cd xhs-hkdse
bash install.sh    # 自动装 Python venv + 下载 xhs-mcp 二进制 + 准备配置
```

装完按提示编辑 `webapp/config/app_config.json` 把 `sk-or-v1-YOUR...` 替换成你的 key.

### Step 2 · 扫码登录你自己的小红书 (一次性)

```bash
bash login.sh      # 弹 Chromium 二维码 → 用手机小红书 App 扫
```

cookies 存在 `xhs-mcp/cookies.json` (gitignored, 不会上传 GitHub).

> 🔒 **每个同事在自己的电脑上跑这一步, 用自己的小红书账号**. 互不影响, 内容各发各号.

### Step 3 · 启动

```bash
bash start.sh      # 后台起 xhs-mcp + webapp, 自动开浏览器
```

打开 **http://localhost:8080/studio** 就能用了.

停止: `bash stop.sh` · 看日志: `tail -f webapp/app.log xhs-mcp/xhs-mcp.log`

---

<details>
<summary>📋 手动安装 (不想用脚本时展开)</summary>

```bash
# 1. Python 环境
cd webapp && python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt && cd ..

# 2. xhs-mcp 二进制 (从 https://github.com/xpzouying/xiaohongshu-mcp/releases 下载对应平台)
mkdir -p xhs-mcp && cd xhs-mcp
curl -fL -o mcp.tar.gz https://github.com/xpzouying/xiaohongshu-mcp/releases/latest/download/xiaohongshu-mcp-darwin-arm64.tar.gz
tar xzf mcp.tar.gz && rm mcp.tar.gz
chmod +x xiaohongshu-mcp-* xiaohongshu-login-*
cd ..

# 3. 配置
cp webapp/config/app_config.example.json webapp/config/app_config.json
# 编辑填 OpenRouter key

# 4. 扫码 + 启动 (两个 terminal)
cd xhs-mcp && ./xiaohongshu-login-darwin-arm64    # 一次性
./xiaohongshu-mcp-darwin-arm64 -port :18060        # Terminal A
cd webapp && source .venv/bin/activate && python app.py   # Terminal B
```

</details>

---

## 主流程 (从输入到发布)

### A. 批量出 10 篇带图草稿 (主玩法)

1. 切到 **🤖 Agents** tab → 展开 **📦 批量模式**
2. textarea 每行一个选题 (支持 `关键词 | 主题 | 科目 | 方向` 格式)
3. workflow 选 `完整 (含研究+封面)`, 并发 3
4. 点 **🚀 启动批量** → 状态卡片实时刷新, 跑完约 12-15 分钟
5. 跑完自动进 **📝 草稿** tab

### B. 挑稿 + 批量发布

1. 切到 **📝 草稿** tab
2. 检查每篇: 封面文字 / 正文 / `[source: ]` 是否填满
3. 勾选要发的草稿 → 点 **🚀 批量发布选中** (默认 6 秒间隔)

### C. 单篇精修

`🤖 Agents` tab 不展开批量, 直接选 workflow + 填关键词 + 主题 → 启动. 右侧 timeline 实时刷 agent 事件, 适合 debug 或重要稿件.

---

## 安全规则 (写在 LLM prompt 里, 同事审稿也请遵守)

- ❌ 不出现「包过 / 保 5** / 100%」等绝对化承诺
- ❌ 不点名其他补习社/老师/机构
- ❌ 不发敏感话题 (政/教/性向)
- ✅ HKEAA 数据/分数线/JUPAS 政策必须有 source URL
- ✅ 学长成绩故事必须标「学长经验, 仅供参考」

---

## 技术栈

| 层 | 选型 |
|---|---|
| 发布/搜索 MCP | [xpzouying/xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp) (Go) |
| Web Studio | FastAPI + Vanilla JS SPA |
| LLM 编排 | 自研 Multi-Agent Orchestrator (`webapp/core/agents/`) |
| LLM | OpenRouter → Claude Sonnet 4.5 (默认, 可改) |
| 出图 | OpenRouter → ByteDance Seedream 4.5 |
| 事实查证 | Tavily / Jina (可选) |

## 目录结构

```
xhs-hkdse/
├── README.md
├── docs/
│   ├── tutorial.tex / .pdf       # 8 页使用教程
│   └── day1_xhs_mcp_setup.md     # xhs-mcp 部署细节
├── xhs-mcp/                      # Go 二进制 (.gitignore) + cookies (.gitignore)
└── webapp/
    ├── app.py                    # FastAPI 主入口
    ├── agents.yaml               # 6 个 agent 的 system prompt (可改)
    ├── requirements.txt
    ├── config/
    │   ├── app_config.example.json   # 模板
    │   └── app_config.json           # 真 key (.gitignore)
    ├── core/
    │   └── agents/
    │       ├── orchestrator.py   # workflow 调度
    │       ├── agent.py          # LLM-tool loop
    │       ├── specs.py          # 6 个 agent 的默认定义
    │       ├── tools.py          # XHS / Web / Image generate
    │       └── workflows.py      # 3 个预定义 workflow
    ├── cache/
    │   ├── cache_manager.py
    │   ├── task_history.json     # (.gitignore)
    │   └── images/               # AI 生成图 (.gitignore)
    ├── templates/studio.html
    └── static/js/studio.js
```

## 改 Agent Prompt

所有 agent 的 system prompt 都在 `webapp/agents.yaml`, 改完保存即热生效 (FastAPI 自动 reload).

要恢复默认: 删掉 `agents.yaml` 里某个 agent 的整段, 重启 app 会从 `core/agents/specs.py` 的 `DEFAULT_SPECS` 自动重建.

## 核心 API

| 路径 | 说明 |
|---|---|
| `POST /api/workflow/run` | 单 run 启动 |
| `POST /api/workflow/batch/run` | 批量启动 (返回 batch_id + 所有 run_ids) |
| `GET /api/workflow/batch/{id}` | 批量状态查询 |
| `GET /api/agents/specs` | 当前 agent 定义 |
| `POST /api/agents/specs` | 覆盖保存 agent 定义 |
| `GET /api/drafts` | 列所有草稿 |
| `POST /api/draft/{id}/publish` | 发到小红书 |
| `GET /api/account/status` | 登录状态 (5 分钟缓存) |

## 已知限制 (v1.5)

- 单账号 (多账号在 v2 路上)
- 草稿存 JSON 文件 (单进程 OK, < 5000 条 OK)
- 没有 HKEAA past paper RAG (用 web search + Critic 兜)
- Seedream 4.5 偶尔字号 / 构图不理想 (\~5% 概率), 可重新生图

## 成本估算

| 项目 | 单价 | 一篇成本 |
|---|---|---|
| Claude Sonnet 4.5 (4 个 agent 调用) | \$0.05 / 篇 | \$0.05 |
| Seedream 4.5 (3 张图) | \$0.04 / 张 | \$0.12 |
| **总计** | | **\$0.17 / 篇** (\~¥1.2) |

10 篇约 \$1.7 / ¥12.

## License

MIT.

---

**Made for 質心教育科技有限公司 · HKDSE 全科补习与升学指导**
