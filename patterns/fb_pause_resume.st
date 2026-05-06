(*
===============================================================================
  全局暂停保持模块 - FB_PauseResume
===============================================================================
  功能: 提供全局暂停保持功能,支持多设备同步暂停/恢复
  作者: ST 学习系统
  版本: v1.0
  日期: 2025-12-21
  
  使用场景:
  - 整条生产线的全局暂停(所有设备同步暂停)
  - 需要保持现场状态的暂停(不是急停,而是"定格")
  - 需要从暂停点精确恢复的场景
  
  核心思想:
  - 暂停时"冻结"所有状态,不改变任何输出
  - 恢复时从冻结点继续,不重复执行已完成的动作
  - 提供"暂停允许条件"检查,避免危险位置暂停
  
  接口说明:
  输入:
    iPauseRequest   : BOOL  - 暂停请求
    iResumeRequest  : BOOL  - 恢复请求
    iEmergencyStop  : BOOL  - 急停(强制暂停,不检查条件)
    iPauseEnable    : BOOL  - 暂停允许条件(TRUE时才能暂停)
    
  输出:
    oPaused         : BOOL  - 当前已暂停
    oPauseActive    : BOOL  - 暂停信号有效(供其他模块读取)
    oResuming       : BOOL  - 恢复中(可用于渐进恢复)
    oPauseRejected  : BOOL  - 暂停请求被拒绝(条件不满足)
    
  使用示例:
    // 1. 在主程序中实例化(全局单例)
    fbGlobalPause : FB_PauseResume;
    
    // 2. 调用
    fbGlobalPause(
        iPauseRequest := PauseButton,
        iResumeRequest := ResumeButton,
        iEmergencyStop := EmergencyStop,
        iPauseEnable := SafePositionReached,  // 只在安全位置允许暂停
        oPaused => SystemPaused,
        oPauseActive => GlobalPauseSignal
    );
    
    // 3. 其他模块响应暂停信号
    IF fbGlobalPause.oPauseActive THEN
        // 冻结当前状态,不改变输出
        RETURN;  // 提前退出,不执行后续逻辑
    END_IF
===============================================================================
*)

FUNCTION_BLOCK FB_PauseResume

VAR_INPUT
    iPauseRequest   : BOOL;     // 暂停请求
    iResumeRequest  : BOOL;     // 恢复请求
    iEmergencyStop  : BOOL;     // 急停信号
    iPauseEnable    : BOOL;     // 暂停允许条件
END_VAR

VAR_OUTPUT
    oPaused         : BOOL;     // 当前已暂停
    oPauseActive    : BOOL;     // 暂停信号有效(供其他模块读取)
    oResuming       : BOOL;     // 恢复中
    oPauseRejected  : BOOL;     // 暂停请求被拒绝
END_VAR

VAR
    bPausedState    : BOOL;     // 暂停状态锁存
    bResumingState  : BOOL;     // 恢复状态
    
    rtPause         : R_TRIG;   // 暂停上升沿
    rtResume        : R_TRIG;   // 恢复上升沿
    
    fbRejectPulse   : TP;       // 拒绝脉冲(用于显示)
    
    CONST_REJECT_PULSE_TIME : TIME := T#2s;  // 拒绝提示持续时间
END_VAR

// === 边沿检测 ===
rtPause(CLK := iPauseRequest);
rtResume(CLK := iResumeRequest);

// === 暂停逻辑 ===
IF rtPause.Q THEN
    // 检查暂停条件
    IF iPauseEnable OR iEmergencyStop THEN
        // 条件满足,执行暂停
        bPausedState := TRUE;
        bResumingState := FALSE;
        oPauseRejected := FALSE;
    ELSE
        // 条件不满足,拒绝暂停
        fbRejectPulse(IN := TRUE, PT := CONST_REJECT_PULSE_TIME);
    END_IF
END_IF

// === 急停强制暂停(优先级最高) ===
IF iEmergencyStop THEN
    bPausedState := TRUE;
    bResumingState := FALSE;
END_IF

// === 恢复逻辑 ===
IF rtResume.Q AND bPausedState AND NOT iEmergencyStop THEN
    bPausedState := FALSE;
    bResumingState := TRUE;  // 进入恢复中状态
END_IF

// === 恢复中状态处理(可用于渐进恢复) ===
IF bResumingState THEN
    // 这里可以添加渐进恢复逻辑
    // 例如:先恢复低速,再恢复正常速度
    // 目前简化为立即恢复
    bResumingState := FALSE;
END_IF

// === 输出赋值 ===
oPaused := bPausedState;
oPauseActive := bPausedState;  // 供其他模块读取的暂停信号
oResuming := bResumingState;

// === 拒绝提示脉冲 ===
fbRejectPulse(IN := FALSE);  // 自动关闭输入
oPauseRejected := fbRejectPulse.Q;

END_FUNCTION_BLOCK

(*
===============================================================================
  使用模式1: 全局暂停(单例模式)
===============================================================================

// === 在全局变量(GVL)中声明 ===
VAR_GLOBAL
    fbGlobalPause : FB_PauseResume;  // 全局唯一实例
END_VAR

// === 在主程序中调用 ===
PROGRAM Main
VAR
    SafePositionReached : BOOL;  // 安全位置标志
END_VAR

// 调用全局暂停模块
fbGlobalPause(
    iPauseRequest := HMI.PauseButton,
    iResumeRequest := HMI.ResumeButton,
    iEmergencyStop := IO.EmergencyStop,
    iPauseEnable := SafePositionReached,  // 只在安全位置允许暂停
    oPaused => HMI.PausedLamp,
    oPauseRejected => HMI.PauseRejectedAlarm
);

// 检查安全位置(示例:所有电机都停止)
SafePositionReached := 
    NOT Motor1.oRunning AND 
    NOT Motor2.oRunning AND 
    NOT Conveyor.oRunning;

END_PROGRAM

===============================================================================
  使用模式2: 状态机响应全局暂停
===============================================================================

FUNCTION_BLOCK FB_ConveyorControl
VAR_INPUT
    iStart : BOOL;
END_VAR
VAR_OUTPUT
    oRunning : BOOL;
END_VAR
VAR
    nState : INT;
END_VAR

// === 暂停优先检查(在状态机最前面) ===
IF fbGlobalPause.oPauseActive THEN
    // 暂停时冻结状态,不执行后续逻辑
    RETURN;
END_IF

// === 状态机正常逻辑 ===
CASE nState OF
    0: // 空闲
        IF iStart THEN
            nState := 10;
        END_IF
    
    10: // 启动
        oRunning := TRUE;
        // ...
END_CASE

END_FUNCTION_BLOCK

===============================================================================
  使用模式3: 渐进恢复(高级用法)
===============================================================================

// 修改 FB_PauseResume 的恢复逻辑:
VAR
    fbResumeDelay : TON;  // 恢复延时
    nResumePhase : INT;   // 恢复阶段
END_VAR

// 恢复时分阶段处理
IF rtResume.Q AND bPausedState AND NOT iEmergencyStop THEN
    bPausedState := FALSE;
    bResumingState := TRUE;
    nResumePhase := 1;  // 开始第一阶段
END_IF

IF bResumingState THEN
    CASE nResumePhase OF
        1:  // 第一阶段:低速恢复
            fbResumeDelay(IN := TRUE, PT := T#2s);
            IF fbResumeDelay.Q THEN
                nResumePhase := 2;
                fbResumeDelay(IN := FALSE);
            END_IF
        
        2:  // 第二阶段:正常速度
            bResumingState := FALSE;
            nResumePhase := 0;
    END_CASE
END_IF

// 其他模块根据 oResuming 调整速度
IF fbGlobalPause.oResuming THEN
    MotorSpeed := LowSpeed;  // 恢复阶段使用低速
ELSE
    MotorSpeed := NormalSpeed;
END_IF

===============================================================================
  测试清单
===============================================================================

【基础功能】
1. 按暂停按钮(条件满足) → oPaused=TRUE, 所有设备冻结
2. 暂停状态按恢复 → oPaused=FALSE, 设备从暂停点继续

【暂停条件检查】
3. 设备运行中按暂停(条件不满足) → oPauseRejected=TRUE, 暂停失败
4. 设备停止后按暂停(条件满足) → oPaused=TRUE, 暂停成功

【急停处理】
5. 运行中急停 → oPaused=TRUE (强制暂停,不检查条件)
6. 急停状态按恢复 → 无效,必须先解除急停

【状态保持】
7. 暂停时传送带位置X → 恢复后仍从位置X继续(不回退)
8. 暂停时计数器值100 → 恢复后从100继续计数(不清零)

【边界条件】
9. 连续按暂停10次 → 只暂停一次(边沿检测)
10. 暂停后立即按恢复 → 正常恢复(无延时限制)
11. 未暂停时按恢复 → 无效(无副作用)

【多设备同步】
12. 3台电机运行,暂停 → 3台同时冻结
13. 恢复 → 3台同时恢复,保持相对位置关系

【拒绝提示】
14. 暂停被拒绝 → oPauseRejected 保持2秒(提示用户)

===============================================================================
  设计要点
===============================================================================

1. **暂停 ≠ 急停**:
   - 暂停: 可控的、可恢复的、保持现场的"定格"
   - 急停: 紧急的、安全的、可能丢失状态的"硬停"

2. **暂停条件检查**:
   - 避免危险位置暂停(如:机械手在空中)
   - 建议: 只在设备停稳、无运动时允许暂停
   - 特殊需求: 可以设计"运动中暂停"(需要额外的位置保存逻辑)

3. **状态冻结技巧**:
   - 在每个FB最前面检查 oPauseActive
   - 如果暂停,RETURN 提前退出,不执行后续逻辑
   - 不改变任何输出,保持现场

4. **恢复策略**:
   - 简单场景: 直接恢复
   - 复杂场景: 渐进恢复(低速→正常速度)
   - 安全场景: 恢复前重新检查安全条件

5. **全局单例模式**:
   - 整个系统只需要一个 FB_PauseResume 实例
   - 在全局变量(GVL)中声明
   - 所有模块读取同一个 oPauseActive 信号

===============================================================================
*)
