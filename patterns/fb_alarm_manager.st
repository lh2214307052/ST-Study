(*
===============================================================================
  报警管理模块 - FB_AlarmManager
===============================================================================
  功能: 管理多路报警,支持锁存/复位/确认/消抖/优先级
  作者: ST 学习系统
  版本: v1.0
  日期: 2025-12-21
  
  使用场景:
  - 管理多个报警源(传感器故障、超时、越限等)
  - 需要报警锁存(故障瞬间消失也要记录)
  - 需要报警确认(操作员必须确认才能消除)
  - 需要报警消抖(避免抖动误报)
  
  核心功能:
  1. 报警锁存: 触发后即使条件消失也保持
  2. 报警复位: 需要人工确认或自动复位
  3. 报警消抖: 信号稳定一段时间才触发
  4. 优先级分类: 严重/警告/提示
  
  接口说明(单路报警版):
  输入:
    iAlarmTrigger   : BOOL  - 报警触发条件
    iReset          : BOOL  - 复位信号
    iAutoReset      : BOOL  - 允许自动复位
    tDebounceTime   : TIME  - 消抖时间
    nPriority       : INT   - 优先级(1=提示,2=警告,3=严重)
    
  输出:
    oAlarmActive    : BOOL  - 报警有效(锁存后)
    oAlarmRaw       : BOOL  - 原始报警(消抖后,未锁存)
    oAlarmNew       : BOOL  - 新报警(上升沿脉冲)
    
  使用示例:
    fbAlarm_MotorOverload(
        iAlarmTrigger := MotorCurrent > MAX_CURRENT,
        iReset := ResetButton,
        iAutoReset := FALSE,  // 严重故障,必须人工复位
        tDebounceTime := T#500ms,
        nPriority := 3,
        oAlarmActive => AlarmLamp
    );
===============================================================================
*)

FUNCTION_BLOCK FB_Alarm
(*
    单路报警模块(基础版)
*)
VAR_INPUT
    iAlarmTrigger   : BOOL;         // 报警触发条件
    iReset          : BOOL;         // 复位信号
    iAutoReset      : BOOL;         // 允许自动复位
    tDebounceTime   : TIME := T#0s; // 消抖时间(0表示不消抖)
    nPriority       : INT := 2;     // 优先级(1=提示,2=警告,3=严重)
END_VAR

VAR_OUTPUT
    oAlarmActive    : BOOL;         // 报警有效(锁存后)
    oAlarmRaw       : BOOL;         // 原始报警(消抖后)
    oAlarmNew       : BOOL;         // 新报警标志(上升沿)
END_VAR

VAR
    fbDebounce      : TON;          // 消抖定时器
    bAlarmLatched   : BOOL;         // 报警锁存
    rtAlarm         : R_TRIG;       // 报警上升沿
    rtReset         : R_TRIG;       // 复位上升沿
END_VAR

// === 消抖处理 ===
fbDebounce(IN := iAlarmTrigger, PT := tDebounceTime);

IF tDebounceTime > T#0s THEN
    oAlarmRaw := fbDebounce.Q;  // 有消抖时间,使用定时器输出
ELSE
    oAlarmRaw := iAlarmTrigger; // 无消抖时间,直接使用原始信号
END_IF

// === 报警锁存 ===
rtAlarm(CLK := oAlarmRaw);
IF rtAlarm.Q THEN
    bAlarmLatched := TRUE;  // 上升沿锁存
END_IF

// === 报警复位 ===
rtReset(CLK := iReset);

// 人工复位
IF rtReset.Q THEN
    bAlarmLatched := FALSE;
END_IF

// 自动复位(条件消失且允许自动复位)
IF iAutoReset AND NOT oAlarmRaw THEN
    bAlarmLatched := FALSE;
END_IF

// === 输出赋值 ===
oAlarmActive := bAlarmLatched;
oAlarmNew := rtAlarm.Q;  // 新报警脉冲(用于计数/记录)

END_FUNCTION_BLOCK


(*
===============================================================================
  多路报警管理器 - FB_AlarmManager
===============================================================================
  管理多路报警(最多16路)
  提供统一的复位、优先级排序、报警计数功能
===============================================================================
*)

FUNCTION_BLOCK FB_AlarmManager

VAR_INPUT
    iAlarmTriggers  : ARRAY[1..16] OF BOOL;  // 16路报警触发条件
    iResetAll       : BOOL;                   // 全部复位
    iResetSingle    : INT;                    // 单路复位(1-16, 0=无)
END_VAR

VAR_OUTPUT
    oAlarmActive    : ARRAY[1..16] OF BOOL;  // 16路报警状态
    oAnyAlarm       : BOOL;                   // 任意报警有效
    oAlarmCount     : INT;                    // 当前报警数量
    oHighestPriority: INT;                    // 最高优先级(3=严重,2=警告,1=提示)
END_VAR

VAR
    fbAlarms        : ARRAY[1..16] OF FB_Alarm;  // 16个报警实例
    i               : INT;                        // 循环变量
    
    // 每路报警的配置(可外部配置或在此硬编码)
    aPriority       : ARRAY[1..16] OF INT := [
        3, 3, 2, 2, 2, 2, 1, 1,  // 路1-8
        1, 1, 1, 1, 1, 1, 1, 1   // 路9-16
    ];
    
    aDebounceTime   : ARRAY[1..16] OF TIME := [
        T#500ms, T#500ms, T#300ms, T#300ms, T#300ms, T#300ms, T#200ms, T#200ms,
        T#200ms, T#200ms, T#200ms, T#200ms, T#200ms, T#200ms, T#200ms, T#200ms
    ];
    
    aAutoReset      : ARRAY[1..16] OF BOOL := [
        FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE,
        TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
    ];
END_VAR

// === 循环处理每路报警 ===
oAlarmCount := 0;
oHighestPriority := 0;

FOR i := 1 TO 16 DO
    // 调用单路报警模块
    fbAlarms[i](
        iAlarmTrigger := iAlarmTriggers[i],
        iReset := iResetAll OR (iResetSingle = i),
        iAutoReset := aAutoReset[i],
        tDebounceTime := aDebounceTime[i],
        nPriority := aPriority[i],
        oAlarmActive => oAlarmActive[i]
    );
    
    // 统计报警数量
    IF oAlarmActive[i] THEN
        oAlarmCount := oAlarmCount + 1;
        
        // 更新最高优先级
        IF aPriority[i] > oHighestPriority THEN
            oHighestPriority := aPriority[i];
        END_IF
    END_IF
END_FOR

// === 任意报警标志 ===
oAnyAlarm := (oAlarmCount > 0);

END_FUNCTION_BLOCK

(*
===============================================================================
  使用示例1: 单路报警
===============================================================================

VAR
    fbAlarm_MotorOverload : FB_Alarm;
    MotorCurrent : REAL;
    MAX_CURRENT : REAL := 10.0;
END_VAR

// 电机过载报警
fbAlarm_MotorOverload(
    iAlarmTrigger := (MotorCurrent > MAX_CURRENT),  // 触发条件
    iReset := HMI.ResetButton,                       // 复位按钮
    iAutoReset := FALSE,                             // 必须人工复位
    tDebounceTime := T#500ms,                        // 消抖500ms
    nPriority := 3,                                  // 严重报警
    oAlarmActive => HMI.AlarmLamp                    // 输出到报警灯
);

// 报警触发时停机
IF fbAlarm_MotorOverload.oAlarmActive THEN
    Motor.iStop := TRUE;
END_IF

===============================================================================
  使用示例2: 多路报警管理
===============================================================================

VAR
    fbAlarmMgr : FB_AlarmManager;
    
    // 报警触发条件
    bOverload : BOOL;
    bOverheat : BOOL;
    bLowPressure : BOOL;
    // ...
END_VAR

// 配置报警触发条件
fbAlarmMgr.iAlarmTriggers[1] := bOverload;       // 路1: 过载
fbAlarmMgr.iAlarmTriggers[2] := bOverheat;       // 路2: 过热
fbAlarmMgr.iAlarmTriggers[3] := bLowPressure;    // 路3: 低压
// ...

// 调用报警管理器
fbAlarmMgr(
    iResetAll := HMI.ResetAllButton,
    iResetSingle := HMI.SelectedAlarmIndex  // 单个复位
);

// 显示报警状态
HMI.AlarmCount := fbAlarmMgr.oAlarmCount;
HMI.AnyAlarmActive := fbAlarmMgr.oAnyAlarm;

// 根据优先级控制报警灯颜色
CASE fbAlarmMgr.oHighestPriority OF
    3: HMI.AlarmLampColor := RED;     // 严重
    2: HMI.AlarmLampColor := YELLOW;  // 警告
    1: HMI.AlarmLampColor := BLUE;    // 提示
    ELSE
        HMI.AlarmLampColor := OFF;
END_CASE

===============================================================================
  使用示例3: 报警与状态机联动
===============================================================================

FUNCTION_BLOCK FB_MachineControl
VAR
    fbAlarmMgr : FB_AlarmManager;
    nState : INT;
END_VAR

// 严重报警时自动停机
IF fbAlarmMgr.oHighestPriority >= 3 THEN
    nState := STATE_ERROR;  // 进入错误状态
END_IF

// 警告时仅提示,不停机
IF fbAlarmMgr.oHighestPriority = 2 THEN
    HMI.WarningMessage := 'Warning: Check system';
END_IF

END_FUNCTION_BLOCK

===============================================================================
  测试清单
===============================================================================

【基础功能】
1. 触发条件成立 → oAlarmActive=TRUE
2. 触发条件消失,人工复位 → oAlarmActive=FALSE

【锁存机制】
3. 触发条件瞬间成立(100ms)后消失 → oAlarmActive=TRUE(锁存保持)
4. 锁存后必须复位才能消除 → 即使触发条件消失也保持

【消抖功能】
5. 触发条件抖动(ON 100ms, OFF 100ms) → 无报警(未达到消抖时间)
6. 触发条件稳定500ms → 报警触发

【自动复位】
7. 允许自动复位,触发条件消失 → oAlarmActive=FALSE(自动复位)
8. 不允许自动复位,触发条件消失 → oAlarmActive=TRUE(保持,需人工复位)

【多路报警】
9. 3路同时报警 → oAlarmCount=3, oAnyAlarm=TRUE
10. 复位全部 → oAlarmCount=0, oAnyAlarm=FALSE
11. 单个复位路2 → 路2复位,其他保持

【优先级排序】
12. 路1(严重),路3(警告)同时报警 → oHighestPriority=3
13. 路1复位后 → oHighestPriority=2

【边界条件】
14. 连续触发10次 → oAlarmNew只在第一次触发时为TRUE(上升沿)
15. 复位按钮连按10次 → 只复位一次(边沿检测)

===============================================================================
  设计要点
===============================================================================

1. **锁存 vs 非锁存**:
   - 锁存: 故障瞬间即记录,需人工确认(适用于严重故障)
   - 非锁存(自动复位): 条件消失即恢复(适用于轻微提示)

2. **消抖时间选择**:
   - 机械触点: 50-200ms
   - 传感器信号: 100-500ms
   - 模拟量越限: 500-1000ms(避免边界抖动)

3. **优先级分类建议**:
   - 3 严重: 必须立即停机(过载、急停、安全门打开)
   - 2 警告: 需要关注但可继续运行(温度偏高、压力偏低)
   - 1 提示: 仅提示信息(维护提醒、计数达到)

4. **报警历史记录**(扩展):
   - 可添加 ARRAY[1..100] OF AlarmRecord 记录最近100条
   - 记录: 时间戳、报警ID、触发值、复位时间

5. **报警优先级显示**:
   - 严重: 红色闪烁 + 蜂鸣器
   - 警告: 黄色常亮
   - 提示: 蓝色常亮

===============================================================================
*)
