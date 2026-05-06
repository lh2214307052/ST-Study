# 每日学习会话: 2026-05-06
**学习时长**: ~1 小时  
**当前周**: Week 1（复出第二次）  
**今日模块**: 定时器 TON + 边沿检测 R_TRIG/F_TRIG

---

## 📋 今日目标(可验收)
- [x] **目标1**: 掌握 TON 定时器 - 验收：能写出延时启动逻辑，理解 IN/PT/Q/ET 接口
- [x] **目标2**: 掌握 R_TRIG/F_TRIG 边沿检测 - 验收：能解释扫描周期影响，写出按钮切换逻辑
- [x] **目标3**: 综合练习：带防抖的延时启动电机 - 验收：独立写出完整代码并找出两个 bug

---

## 🔑 关键概念(最多 5 条)

1. **TON延时接通**: IN=TRUE 立即开始计时，达到 PT 后 Q 变 TRUE；IN 变 FALSE 则立刻清零重置
2. **R_TRIG 上升沿**: 无论按住多久，只在 FALSE→TRUE 那一个扫描周期输出 TRUE 脉冲
3. **AND 优先级高于 OR**: `A OR B AND C` = `A OR (B AND C)`，忘加括号会导致安全条件被绕过
4. **R_TRIG.Q 不能接 TON.IN**: Q 只持续一个扫描周期，定时器会立即归零，永远到不了设定时间
5. **急停后自动重启隐患**: 急停时定时器若已完成，松开急停会立刻自启——需在 TON.IN 加 `AND NOT iEmergency`

---

## 💻 今日练习

### 练习1: 带防抖的延时启动电机（综合版）

```st
VAR
    iStart        : BOOL;
    iStop         : BOOL;
    iEmergency    : BOOL;
    fbDelayTimer  : TON;
    fbStartEdge   : R_TRIG;
    bRunning      : BOOL;
    bLogTrigger   : BOOL;
END_VAR

// 按下瞬间记录操作日志
fbStartEdge( CLK := iStart );
IF fbStartEdge.Q THEN
    bLogTrigger := NOT bLogTrigger;
END_IF

// 持续按住 3 秒才触发（防误触）
fbDelayTimer( IN := iStart AND NOT iEmergency, PT := T#3s );

// 自保持，急停/停止优先
bRunning := ( fbDelayTimer.Q OR bRunning ) AND NOT iStop AND NOT iEmergency;
```

---

## ✅ 测试清单

- [x] 按住启动 1 秒松手 → 电机不启动（未达 3 秒）
- [x] 按住启动满 3 秒松手 → 电机启动并自保持
- [x] 运行中按停止 → 电机停止
- [x] 运行中按急停 → 立即停止（急停优先）
- [x] 按住启动第 2 秒时按急停 → 电机不启动，定时器重置（因为 IN 加了 AND NOT iEmergency）
- [ ] 急停后松开急停再按启动 → 需重新按满 3 秒（下次验收）

---

## 🔍 今日复盘

### 掌握了什么
- TON 定时器接口与防误触延时启动逻辑
- R_TRIG 边沿检测与按钮切换逻辑
- AND/OR 运算符优先级陷阱（重要！）

**能力等级**:
- 1.5 上升沿/下降沿检测(R_TRIG/F_TRIG): L0 → **L2** ✅
- 1.6 定时器(TON/TOF): L0 → **L1**（TON 掌握，TOF 未练）

### 还不熟的点
- TOF（延时断开）尚未练习
- 急停自启隐患的修复方案（`AND NOT iEmergency` 加在 IN 端）理解了原理，但未验收

### 踩坑记录

1. **R_TRIG.Q 接 TON.IN**: 以为可以链式连接，实际 Q 只有一个扫描周期 → **教训**: 边沿检测和定时器要并联接同一个信号源，不能串联
2. **缺括号导致优先级错误**: `fbDelayTimer.Q OR bRunning AND NOT iEmergency` 急停失效 → **教训**: OR 两侧复合条件必须加括号
3. **命名**: `istop`、`eiEmergency` 前缀/大小写错误 → **教训**: 写代码前默念命名规范前缀表

---

### 明日计划

1. **巩固**: TON 的急停安全修复（`IN := iStart AND NOT iEmergency`），理解为什么 `AND NOT iStop` 不够
2. **新学**: TOF（延时断开）+ 计数器 CTU/CTD
3. **验收**: 能写出带 TOF 的"运行指示灯延时熄灭"逻辑

---

## 📊 今日统计

- **学习时长**: ~1 小时
- **能力等级提升**: 1.5 L0→L2，1.6 L0→L1

---

**今日总结**: AND 优先级高于 OR 是个无声的杀手，加括号是工程习惯，不是可选项。

**明日重点**: TOF + 计数器，完成 Week 1 定时器模块。
