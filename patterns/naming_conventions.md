# ST 编程命名与注释规范

## 命名规范

### 1. 变量命名前缀(匈牙利命名法)

使用前缀标识变量类型和作用域,提高代码可读性:

#### 作用域前缀:
```
i   - Input          输入参数 (VAR_INPUT)
o   - Output         输出参数 (VAR_OUTPUT)
io  - InOut          引用参数 (VAR_IN_OUT)
(无前缀) - Local     内部变量 (VAR)
g   - Global         全局变量 (GVL)
```

#### 类型前缀:
```
b   - BOOL           布尔变量
n   - INT/DINT/USINT 整数
r   - REAL/LREAL     实数
t   - TIME/TON/TOF   时间/定时器
s   - STRING         字符串
e   - ENUM           枚举
a   - ARRAY          数组
st  - STRUCT         结构体
fb  - Function Block 函数块实例
p   - POINTER        指针(若支持)
```

#### 组合使用示例:
```st
VAR_INPUT
    iStart      : BOOL;         // 输入 + 布尔 (无b前缀,语义清晰)
    ibEnable    : BOOL;         // 输入 + 布尔 (可加b,但通常省略)
    inSpeed     : INT;          // 输入 + 整数
    itTimeout   : TIME;         // 输入 + 时间
END_VAR

VAR_OUTPUT
    oRun        : BOOL;         // 输出 + 布尔
    onPosition  : INT;          // 输出 + 整数
END_VAR

VAR
    bRunning    : BOOL;         // 内部 + 布尔
    nCounter    : INT;          // 内部 + 整数
    rTemperature: REAL;         // 内部 + 实数
    tDelay      : TON;          // 内部 + 定时器
    fbMotor     : FB_Motor;     // 内部 + 函数块实例
    aValues     : ARRAY[1..10] OF INT;  // 内部 + 数组
END_VAR

VAR_GLOBAL
    gnSystemMode: INT;          // 全局 + 整数
    gbEmergency : BOOL;         // 全局 + 布尔
END_VAR
```

---

### 2. 常量命名

全大写+下划线分隔,清晰表达含义:

```st
VAR CONSTANT
    MAX_SPEED           : INT := 3000;     // 最大速度
    MIN_TEMPERATURE     : REAL := -10.0;   // 最小温度
    DEBOUNCE_TIME       : TIME := T#200ms; // 消抖时间
    MOTOR_COUNT         : INT := 10;       // 电机数量
END_VAR
```

**禁止魔法数字**:
```st
// ❌ 错误: 100 是什么意思?
IF counter > 100 THEN
    ...
END_IF

// ✅ 正确: 使用常量
CONST MAX_COUNT : INT := 100;  // 最大计数值
IF counter > MAX_COUNT THEN
    ...
END_IF
```

---

### 3. 函数块/函数命名

#### 函数块(FB):
- **前缀**: `FB_`
- **格式**: `FB_ModuleName` (驼峰命名,首字母大写)
- **示例**: `FB_Motor`, `FB_StateMachine`, `FB_AlarmManager`

#### 函数(FC):
- **前缀**: `FC_`
- **格式**: `FC_FunctionName` (驼峰命名,首字母大写)
- **示例**: `FC_Round`, `FC_Limit`, `FC_CheckRange`

#### 程序(PROGRAM):
- **前缀**: `PRG_`
- **格式**: `PRG_ProgramName`
- **示例**: `PRG_Main`, `PRG_Conveyor`, `PRG_Safety`

```st
// 函数块定义
FUNCTION_BLOCK FB_Motor
    ...
END_FUNCTION_BLOCK

// 函数定义
FUNCTION FC_Limit : REAL
    ...
END_FUNCTION

// 程序定义
PROGRAM PRG_Main
    ...
END_PROGRAM
```

---

### 4. 枚举命名

#### 枚举类型:
- **前缀**: `E_`
- **格式**: `E_TypeName`

#### 枚举值:
- **格式**: 全大写+下划线

```st
TYPE E_SystemMode :
(
    MODE_IDLE       := 0,   // 空闲
    MODE_MANUAL     := 1,   // 手动
    MODE_AUTO       := 2,   // 自动
    MODE_ERROR      := 99   // 错误
);
END_TYPE

TYPE E_AlarmLevel :
(
    ALARM_NONE      := 0,   // 无报警
    ALARM_INFO      := 1,   // 提示
    ALARM_WARNING   := 2,   // 警告
    ALARM_CRITICAL  := 3    // 严重
);
END_TYPE
```

---

### 5. 结构体命名

#### 结构体类型:
- **前缀**: `ST_`
- **格式**: `ST_TypeName`

```st
TYPE ST_MotorParameters :
STRUCT
    rSpeed          : REAL;     // 速度
    rAcceleration   : REAL;     // 加速度
    nMaxCurrent     : INT;      // 最大电流
    tStartDelay     : TIME;     // 启动延时
END_STRUCT
END_TYPE

TYPE ST_AlarmData :
STRUCT
    bActive         : BOOL;     // 报警有效
    nID             : INT;      // 报警ID
    sDescription    : STRING;   // 报警描述
    tTimestamp      : TIME;     // 触发时间
END_STRUCT
END_TYPE
```

---

### 6. 状态/步号命名

使用清晰的常量定义状态号:

```st
VAR CONSTANT
    // 系统状态(负数为特殊状态)
    STATE_IDLE      : INT := 0;     // 空闲
    STATE_PAUSE     : INT := -1;    // 暂停
    STATE_ERROR     : INT := -2;    // 错误
    STATE_EMERGENCY : INT := -3;    // 急停
    
    // 工作步号(建议每10个数字一个大步骤)
    STEP_INIT       : INT := 10;    // 初始化
    STEP_CHECK      : INT := 20;    // 检查
    STEP_START      : INT := 30;    // 启动
    STEP_RUN        : INT := 40;    // 运行
    STEP_STOP       : INT := 50;    // 停止
    STEP_COMPLETE   : INT := 100;   // 完成
END_VAR
```

---

## 注释规范

### 1. 何时注释

**必须注释**:
- ✅ 每个 FB/FC 的头部(功能说明)
- ✅ 复杂逻辑的"为什么"(不是"做什么")
- ✅ 魔法数字的含义(更好的是用常量代替)
- ✅ 非显而易见的算法
- ✅ 工程相关的约束/限制

**不需要注释**(代码自解释):
- ❌ 显而易见的逻辑: `iStart := TRUE;  // 启动为真` (废话)
- ❌ 变量名已经很清楚的: `nCounter := 0;  // 计数器清零` (冗余)

---

### 2. FB/FC 头部注释模板

```st
(*
===============================================================================
  模块名称 - FB_Motor
===============================================================================
  功能: 单台电机控制,支持启停/互锁/报警
  作者: 张三
  版本: v1.2
  日期: 2025-12-21
  
  使用场景:
  - 普通三相异步电机控制
  - 需要启停互锁和急停保护
  
  接口说明:
  输入:
    iStart      : BOOL  - 启动按钮(上升沿触发)
    iStop       : BOOL  - 停止按钮
    iEmergency  : BOOL  - 急停信号
    
  输出:
    oRun        : BOOL  - 运行输出(接触器线圈)
    oAlarm      : BOOL  - 报警输出
    
  使用示例:
    fbMotor1(
        iStart := StartButton,
        iStop := StopButton,
        iEmergency := EmergencyStop,
        oRun => MotorContactor
    );
    
  修改历史:
    v1.2 2025-12-21 - 增加防抖功能
    v1.1 2025-12-15 - 修复急停优先级问题
    v1.0 2025-12-10 - 初始版本
===============================================================================
*)

FUNCTION_BLOCK FB_Motor
    ...
END_FUNCTION_BLOCK
```

---

### 3. 行内注释

**注释"为什么",而非"做什么"**:

```st
// ❌ 错误示例(废话注释)
bRunning := TRUE;  // 设置运行标志为TRUE

// ✅ 正确示例(解释原因)
bRunning := TRUE;  // 启动后保持运行,直到收到停止或急停信号
```

**复杂逻辑必须注释**:
```st
// ❌ 无注释(难以理解)
IF (iStart AND NOT iStop) OR (bRunning AND NOT iStop AND NOT iEmergency) THEN
    oRun := TRUE;
END_IF

// ✅ 有注释(逻辑清晰)
// 启动条件: 按启动且未按停止
// 自保持条件: 已运行且未按停止且未急停
IF (iStart AND NOT iStop) OR (bRunning AND NOT iStop AND NOT iEmergency) THEN
    oRun := TRUE;
END_IF
```

---

### 4. 分段注释

用分隔线划分代码段:

```st
// === 边沿检测 ===
rtStart(CLK := iStart);
rtStop(CLK := iStop);

// === 急停优先处理 ===
IF iEmergency THEN
    oRun := FALSE;
    RETURN;
END_IF

// === 启停逻辑 ===
IF rtStart.Q THEN
    bRunning := TRUE;
END_IF

IF rtStop.Q OR iEmergency THEN
    bRunning := FALSE;
END_IF

// === 输出赋值 ===
oRun := bRunning;
```

---

### 5. TODO/FIXME/NOTE 标记

```st
// TODO: 添加超时检测
// FIXME: 急停后恢复逻辑有问题
// NOTE: 此处必须先判断停止,再判断启动(停止优先)
// WARNING: 修改此逻辑时注意安全互锁
```

---

## 代码组织规范

### 1. 变量声明顺序

```st
FUNCTION_BLOCK FB_Example

VAR_INPUT
    // 按功能分组
    // === 控制信号 ===
    iStart      : BOOL;
    iStop       : BOOL;
    iReset      : BOOL;
    
    // === 参数 ===
    nSpeed      : INT;
    tTimeout    : TIME;
END_VAR

VAR_OUTPUT
    oRun        : BOOL;
    oAlarm      : BOOL;
END_VAR

VAR_IN_OUT
    ioData      : ST_DataBuffer;
END_VAR

VAR
    // === 状态变量 ===
    nState      : INT;
    bRunning    : BOOL;
    
    // === 定时器/边沿 ===
    tDelay      : TON;
    rtStart     : R_TRIG;
    
    // === 函数块实例 ===
    fbAlarm     : FB_Alarm;
END_VAR

VAR CONSTANT
    MAX_SPEED   : INT := 3000;
END_VAR
```

---

### 2. 代码逻辑顺序

```st
// 1. 边沿检测
rtStart(CLK := iStart);

// 2. 优先级最高的逻辑(急停/复位)
IF iEmergency THEN
    RETURN;
END_IF

// 3. 状态机/主逻辑
CASE nState OF
    ...
END_CASE

// 4. 输出赋值
oRun := bRunning;
```

---

## 示例: 完整的规范代码

```st
(*
===============================================================================
  单电机控制模块 - FB_Motor
===============================================================================
  功能: 控制单台电机,支持启停互锁/急停保护/故障报警
  版本: v1.0
  日期: 2025-12-21
===============================================================================
*)

FUNCTION_BLOCK FB_Motor

VAR_INPUT
    // === 控制信号 ===
    iStart      : BOOL;     // 启动按钮
    iStop       : BOOL;     // 停止按钮
    iEmergency  : BOOL;     // 急停信号
    
    // === 监控信号 ===
    iOverload   : BOOL;     // 过载检测
END_VAR

VAR_OUTPUT
    oRun        : BOOL;     // 运行输出
    oAlarm      : BOOL;     // 报警输出
END_VAR

VAR
    // === 状态变量 ===
    bRunning    : BOOL;     // 运行状态
    
    // === 边沿检测 ===
    rtStart     : R_TRIG;   // 启动上升沿
    rtStop      : R_TRIG;   // 停止上升沿
    
    // === 定时器 ===
    tStartDelay : TON;      // 启动延时(防误触)
END_VAR

VAR CONSTANT
    DELAY_TIME  : TIME := T#500ms;  // 启动延时时间
END_VAR

// === 边沿检测 ===
rtStart(CLK := iStart);
rtStop(CLK := iStop);

// === 急停优先(最高优先级) ===
IF iEmergency OR iOverload THEN
    bRunning := FALSE;
    oRun := FALSE;
    oAlarm := (iOverload);  // 过载报警
    RETURN;  // 提前退出,不执行后续逻辑
END_IF

// === 启动逻辑(含防抖) ===
tStartDelay(IN := rtStart.Q, PT := DELAY_TIME);
IF tStartDelay.Q THEN
    bRunning := TRUE;
END_IF

// === 停止逻辑(停止优先) ===
IF rtStop.Q THEN
    bRunning := FALSE;
END_IF

// === 输出赋值 ===
oRun := bRunning;
oAlarm := iOverload;

END_FUNCTION_BLOCK
```

---

## 总结: 核心原则

1. **命名清晰 > 注释补救**: 好的命名让代码自解释
2. **注释"为什么" > "做什么"**: 代码已经说明了"做什么",注释要说明"为什么"
3. **禁止魔法数字**: 任何数字都用常量定义
4. **一致性 > 个人喜好**: 团队统一规范比个人习惯更重要
5. **工程思维**: 代码要给6个月后的自己看,给接手项目的同事看

---

**记住: 代码是写给人看的,机器只是顺便执行而已!**
