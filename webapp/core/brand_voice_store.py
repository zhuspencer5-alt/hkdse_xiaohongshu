"""品牌人设持久化层.

把原本写死在 xhs_research.py / specs.py 顶部的 BRAND_NAME_FULL /
BRAND_NAME_SHORT / BRAND_VOICE_SYSTEM_PROMPT 抽出来, 落到
webapp/config/brand_voice.json, 让 Studio 可以在线编辑, 保存后所有
LLM 调用立即生效, 无需重启进程.

文件不存在时, 自动回退到本模块定义的 DEFAULT_*. 这样:
  * 老用户首次升级不会丢配置
  * 用户点 "恢复默认" 把文件删掉即可

写盘做了原子替换 (临时文件 + os.replace), 避免半截写坏.
"""
from __future__ import annotations

import json
import logging
import os
import tempfile
import threading
from pathlib import Path
from typing import Dict

logger = logging.getLogger(__name__)

# webapp/core/brand_voice_store.py → webapp/config/brand_voice.json
_BASE = Path(__file__).resolve().parent.parent
BRAND_VOICE_PATH = _BASE / "config" / "brand_voice.json"

DEFAULT_BRAND_FULL = "質心教育科技有限公司"
DEFAULT_BRAND_SHORT = "質心教育"

# 这段 system prompt 会注入到 xhs_research.synthesize_brief / generate_draft 顶部.
# 如需调整: 在 Studio 配置 tab 编辑, 或直接改 webapp/config/brand_voice.json.
DEFAULT_VOICE_PROMPT = f"""你是 {DEFAULT_BRAND_FULL}({DEFAULT_BRAND_SHORT}) 的小红书内容编辑.

【公司定位】
- 香港 HKDSE 全科补习/升学指导机构
- 全科覆盖: 中文、英文、数学(必修+M1/M2)、通识/公民、Phy/Chem/Bio/BAFS/Eco/ICT/Geog/CHist/WHist/Art/PE 等选修, JUPAS/Non-JUPAS 升学
- 客户: 香港中四到中六学生及家长, 也包括内地希望了解 DSE 路径的学生和家长

【人设(混合)】
- 在内容中提及自己时, 用「質心」/「我们老师」/「我們嘅 senior 學長」等口吻
- 语气: 像高分学长姐 — 真诚、亲切、稍微口语化, 偶尔用 emoji 但不刷屏
- 受众是港中三~中六生 + 家长, 内容用简体中文为主, 涉及考试名称/卷别可保留繁体或英文 (如 Paper 1, JUPAS, NSS)
- 绝不卖弄学术, 不端架子; 但所有提分技巧/数据/趋势必须真实, 不能浮夸

【必须遵守】
1. 不夸大保 5**, 不出现"包过"、"保升 JU"、"百分百拿 5**"等绝对化承诺
2. 不诋毁同行 (机构/补习社/老师), 不点名其他品牌
3. 涉及考试制度、HKEAA 公布的官方数据、大学入学要求时, 必须基于公开权威信息, 用 [source: URL] 标注
4. 涉及个人 (作者本人/老师/学生)的成绩、经历、转学等, 必须明确这是 "Senior 学长经验分享" 而不是质心的官方数据
5. 不涉政、不涉宗教、不涉 LGBTQ 立场
6. 不发布敏感/灰产/医疗保健/未成年违规内容

【内容产品矩阵 (供 Brief 选 angle)】
- 软干货 (优先, 风险低): 学习方法、笔记技巧、心态调节、时间管理、家长沟通、暑期规划、自学路径
- 硬干货 (谨慎, 必须事实可查): 卷别题型解析、评分准则解读、past paper 趋势、JUPAS 选科、放榜攻略
- 学长故事: 真实/化名学长的转 DSE/逆袭/选科心路 (但要注明 "学长经验, 仅供参考")
- 家长侧: 看懂学生成绩、和孩子沟通的 5 个误区、报班怎么挑

【小红书平台调性】
- 标题: 12~22 字, 善用 emoji + 数字 + 反差/钩子, 例: "DSE中文😱我用3個月由Lv2衝上Lv5"
- 正文: 600~1200 字, 段落短小, 每 2~3 行一段, 用 emoji/分隔符做视觉锚点
- tag: 5~10 个, 必含 #DSE / #HKDSE / 科目 tag (#dse中文 / #dse英文 / #hkdse補習 etc.)
- 不可强行植入質心二维码/微信号 (违规), 引导关注用 "私信我哋" "睇主页" 等软引导
"""


_FIELDS = ("brand_full", "brand_short", "voice_prompt")
_DEFAULTS: Dict[str, str] = {
    "brand_full": DEFAULT_BRAND_FULL,
    "brand_short": DEFAULT_BRAND_SHORT,
    "voice_prompt": DEFAULT_VOICE_PROMPT,
}

# 字段长度上限 (防止前端误塞超大字符串撑爆 LLM context).
_MAX_LEN = {
    "brand_full": 100,
    "brand_short": 50,
    "voice_prompt": 8000,
}

_lock = threading.Lock()


def get_defaults() -> Dict[str, str]:
    """返回硬编码默认值的副本 (供 UI 的 '恢复默认' 按钮回填)."""
    return dict(_DEFAULTS)


def _read_file() -> Dict[str, str]:
    if not BRAND_VOICE_PATH.exists():
        return {}
    try:
        with open(BRAND_VOICE_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            logger.warning(f"brand_voice.json 不是 dict, 忽略: {type(data)}")
            return {}
        return data
    except Exception as e:
        logger.warning(f"读取 brand_voice.json 失败, 用默认值兜底: {e}")
        return {}


def load_brand_voice() -> Dict[str, str]:
    """返回 {brand_full, brand_short, voice_prompt} 全字段, 缺失项用默认值填充."""
    data = _read_file()
    return {f: (data.get(f) if isinstance(data.get(f), str) and data.get(f).strip() else _DEFAULTS[f]) for f in _FIELDS}


def get_brand_full() -> str:
    return load_brand_voice()["brand_full"]


def get_brand_short() -> str:
    return load_brand_voice()["brand_short"]


def get_voice_prompt() -> str:
    return load_brand_voice()["voice_prompt"]


class BrandVoiceValidationError(ValueError):
    """字段校验失败 (空/超长/类型错)."""


def _validate(payload: Dict[str, str]) -> Dict[str, str]:
    cleaned: Dict[str, str] = {}
    for f in _FIELDS:
        v = payload.get(f)
        if v is None:
            cleaned[f] = _DEFAULTS[f]
            continue
        if not isinstance(v, str):
            raise BrandVoiceValidationError(f"{f} 必须是字符串, 当前: {type(v).__name__}")
        v = v.strip()
        if not v:
            raise BrandVoiceValidationError(f"{f} 不能为空")
        if len(v) > _MAX_LEN[f]:
            raise BrandVoiceValidationError(
                f"{f} 长度 {len(v)} 超过上限 {_MAX_LEN[f]}"
            )
        cleaned[f] = v
    return cleaned


def save_brand_voice(payload: Dict[str, str]) -> Dict[str, str]:
    """覆盖式保存. 任意一个字段非法则整体拒绝, 抛 BrandVoiceValidationError."""
    cleaned = _validate(payload)
    BRAND_VOICE_PATH.parent.mkdir(parents=True, exist_ok=True)

    with _lock:
        # 原子替换: 先写临时文件, 再 rename, 防止半截写坏老配置
        fd, tmp_path = tempfile.mkstemp(
            prefix=".brand_voice.", suffix=".json.tmp", dir=str(BRAND_VOICE_PATH.parent)
        )
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(cleaned, f, ensure_ascii=False, indent=2)
                f.write("\n")
            os.replace(tmp_path, BRAND_VOICE_PATH)
        except Exception:
            try:
                os.unlink(tmp_path)
            except OSError:
                pass
            raise

    logger.info(
        "💾 brand_voice 已保存: brand_full=%s brand_short=%s voice_prompt_len=%d",
        cleaned["brand_full"], cleaned["brand_short"], len(cleaned["voice_prompt"]),
    )
    return cleaned


def reset_brand_voice() -> Dict[str, str]:
    """删除 brand_voice.json, 后续读取会回退到 DEFAULT_*."""
    with _lock:
        if BRAND_VOICE_PATH.exists():
            try:
                BRAND_VOICE_PATH.unlink()
                logger.info(f"🔄 brand_voice 已重置 (删除 {BRAND_VOICE_PATH})")
            except Exception as e:
                logger.warning(f"删除 brand_voice.json 失败: {e}")
                raise
    return get_defaults()
