(*
===============================================================================
  通用状态机框架 - FB_StateMachine
===============================================================================
  功能: 提供标准的状态机结构,支持暂停保持/恢复/异常回退
  作者: ST 学习系统
  版本: v1.0
  日期: 2025-12-21
  
  使用场景:
  - 任何需要步进控制的场景(传送带启动、机械手动作、工序流程等)
  - 需要暂停保持和恢复续跑的自动化流程
  - 需要异常处理和安全回退的控制逻辑
  
  接口说明:
  输入:
    iStart      : BOOL  - 启动信号(上升沿触发)
    iReset      : BOOL  - 复位信号(回到初始状态)
    iPause      : BOOL  - 暂停信号(保持当前状态)
    iResume     : BOOL  - 恢复信号(从暂停状态继续)
    iEmergency  : BOOL  - 急停信号(立即进入急停状态)
    
  输出:
    oRunning    : BOOL  - 流程运行中
    oPaused     : BOOL  - 流程已暂停
    oError      : BOOL  - 流程出错
    oComplete   : BOOL  - 流程完成
    nCurrentStep: INT   - 当前步号(用于监控)
    sStepName   : STRING- 当前步名称(用于调试)
    
  内部变量:
    nState      : INT   - 状态机当前状态
    nStateLast  : INT   - 暂停前的状态(用于恢复)
    bFirstScan  : BOOL  - 每个状态的首次扫描标志
    
  使用示例:
    fbMachine(
        iStart := StartButton,
        iReset := ResetButton,
        iPause := PauseButton,
        iResume := ResumeButton,
        iEmergency := EmergencyStop,
        oRunning => SystemRunning,
        oPaused => SystemPaused,
        oError => SystemError,
        oComplete => SystemComplete,
        nCurrentStep => CurrentStepDisplay
    );
===============================================================================
*)

FUNCTION_BLOCK FB_StateMachine

VAR_INPUT
    iStart      : BOOL;     // 启动信号
    iReset      : BOOL;     // 复位信号
    iPause      : BOOL;     // 暂停信号
    iResume     : BOOL;     // 恢复信号
    iEmergency  : BOOL;     // 急停信号
END_VAR

VAR_OUTPUT
    oRunning    : BOOL;     // 运行中
    oPaused     : BOOL;     // 已暂停
    oError      : BOOL;     // 出错
    oComplete   : BOOL;     // 完成
    nCurrentStep: INT;      // 当前步号
    sStepName   : STRING;   // 当前步名称
END_VAR

VAR
    nState      : INT := 0;     // 当前状态
    nStateLast  : INT := 0;     // 暂停前状态(用于恢复)
    bFirstScan  : BOOL;         // 首次扫描标志
    
    // 边沿检测
    rtStart     : R_TRIG;       // 启动上升沿
    rtReset     : R_TRIG;       // 复位上升沿
    rtPause     : R_TRIG;       // 暂停上升沿
    rtResume    : R_TRIG;       // 恢复上升沿
END_VAR

VAR CONSTANT
    // 系统状态定义(负数为特殊状态)
    STATE_IDLE      : INT := 0;     // 空闲
    STATE_PAUSE     : INT := -1;    // 暂停
    STATE_ERROR     : INT := -2;    // 错误
    STATE_EMERGENCY : INT := -3;    // 急停
    
    // 工作状态定义(根据实际流程修改)
    STATE_INIT      : INT := 1;     // 初始化
    STATE_STEP1     : INT := 10;    // 步骤1
    STATE_STEP2     : INT := 20;    // 步骤2
    STATE_STEP3     : INT := 30;    // 步骤3
    STATE_COMPLETE  : INT := 100;   // 完成
END_VAR

// === 边沿检测 ===
rtStart(CLK := iStart);
rtReset(CLK := iReset);
rtPause(CLK := iPause);
rtResume(CLK := iResume);

// === 急停优先(任何状态下都响应) ===
IF iEmergency THEN
    nState := STATE_EMERGENCY;
    bFirstScan := TRUE;
END_IF

// === 复位处理(次优先) ===
IF rtReset.Q AND NOT iEmergency THEN
    nState := STATE_IDLE;
    bFirstScan := TRUE;
END_IF

// === 暂停/恢复处理 ===
IF rtPause.Q AND nState > 0 THEN  // 只在工作状态下暂停
    nStateLast := nState;         // 保存当前状态
    nState := STATE_PAUSE;
    bFirstScan := TRUE;
END_IF

IF rtResume.Q AND nState = STATE_PAUSE THEN
    nState := nStateLast;         // 恢复到暂停前状态
    bFirstScan := FALSE;          // 恢复时不执行首次扫描动作
END_IF

// === 状态机主逻辑 ===
CASE nState OF
    
    // -------------------------------------------------------------------------
    // 空闲状态
    // -------------------------------------------------------------------------
    STATE_IDLE:
        sStepName := 'IDLE';
        oRunning := FALSE;
        oPaused := FALSE;
        oError := FALSE;
        oComplete := FALSE;
        
        // 等待启动信号
        IF rtStart.Q AND NOT iEmergency THEN
            nState := STATE_INIT;
            bFirstScan := TRUE;
        END_IF
    
    // -------------------------------------------------------------------------
    // 初始化状态
    // -------------------------------------------------------------------------
    STATE_INIT:
        sStepName := 'INIT';
        oRunning := TRUE;
        oComplete := FALSE;
        
        IF bFirstScan THEN
            // 首次进入该状态时执行的动作
            // TODO: 添加初始化动作(如:复位计数器、清除标志位等)
            bFirstScan := FALSE;
        END_IF
        
        // TODO: 添加初始化完成条件
        IF TRUE THEN  // 替换为实际完成条件
            nState := STATE_STEP1;
            bFirstScan := TRUE;
        END_IF
    
    // -------------------------------------------------------------------------
    // 步骤1
    // -------------------------------------------------------------------------
    STATE_STEP1:
        sStepName := 'STEP1';
        oRunning := TRUE;
        
        IF bFirstScan THEN
            // TODO: 添加步骤1的启动动作
            bFirstScan := FALSE;
        END_IF
        
        // TODO: 添加步骤1的持续动作
        
        // TODO: 添加步骤1的完成条件
        IF TRUE THEN  // 替换为实际完成条件
            nState := STATE_STEP2;
            bFirstScan := TRUE;
        END_IF
        
        // TODO: 添加步骤1的超时/异常检测
        IF FALSE THEN  // 替换为实际异常条件
            nState := STATE_ERROR;
            bFirstScan := TRUE;
        END_IF
    
    // -------------------------------------------------------------------------
    // 步骤2
    // -------------------------------------------------------------------------
    STATE_STEP2:
        sStepName := 'STEP2';
        oRunning := TRUE;
        
        IF bFirstScan THEN
            // TODO: 添加步骤2的启动动作
            bFirstScan := FALSE;
        END_IF
        
        // TODO: 添加步骤2的完成条件
        IF TRUE THEN  // 替换为实际完成条件
            nState := STATE_STEP3;
            bFirstScan := TRUE;
        END_IF
    
    // -------------------------------------------------------------------------
    // 步骤3
    // -------------------------------------------------------------------------
    STATE_STEP3:
        sStepName := 'STEP3';
        oRunning := TRUE;
        
        IF bFirstScan THEN
            // TODO: 添加步骤3的启动动作
            bFirstScan := FALSE;
        END_IF
        
        // TODO: 添加步骤3的完成条件
        IF TRUE THEN  // 替换为实际完成条件
            nState := STATE_COMPLETE;
            bFirstScan := TRUE;
        END_IF
    
    // -------------------------------------------------------------------------
    // 完成状态
    // -------------------------------------------------------------------------
    STATE_COMPLETE:
        sStepName := 'COMPLETE';
        oRunning := FALSE;
        oComplete := TRUE;
        
        // 等待复位或重新启动
        // (复位由全局复位处理,这里可以添加自动复位逻辑)
    
    // -------------------------------------------------------------------------
    // 暂停状态
    // -------------------------------------------------------------------------
    STATE_PAUSE:
        sStepName := 'PAUSED';
        oPaused := TRUE;
        
        // 暂停时保持所有输出(不改变任何执行机构状态)
        // 等待恢复或复位信号(由全局处理)
    
    // -------------------------------------------------------------------------
    // 错误状态
    // -------------------------------------------------------------------------
    STATE_ERROR:
        sStepName := 'ERROR';
        oRunning := FALSE;
        oError := TRUE;
        
        IF bFirstScan THEN
            // TODO: 添加错误处理动作(如:停止所有输出、报警等)
            bFirstScan := FALSE;
        END_IF
        
        // 只能通过复位退出错误状态
    
    // -------------------------------------------------------------------------
    // 急停状态
    // -------------------------------------------------------------------------
    STATE_EMERGENCY:
        sStepName := 'EMERGENCY';
        oRunning := FALSE;
        oError := TRUE;
        
        IF bFirstScan THEN
            // TODO: 添加急停动作(立即停止所有危险动作)
            bFirstScan := FALSE;
        END_IF
        
        // 急停解除后需要复位才能继续
    
    // -------------------------------------------------------------------------
    // 未知状态(安全保护)
    // -------------------------------------------------------------------------
    ELSE
        nState := STATE_ERROR;
        bFirstScan := TRUE;
        
END_CASE

// === 输出当前步号 ===
nCurrentStep := nState;

END_FUNCTION_BLOCK

(*
===============================================================================
  测试清单
===============================================================================

【基础功能】
1. 空闲状态按启动 → 进入初始化 → 依次执行STEP1/2/3 → 完成
2. 完成后按复位 → 回到空闲状态

【暂停保持】
3. STEP2运行中按暂停 → 进入暂停状态,保持当前输出
4. 暂停状态按恢复 → 回到STEP2继续执行

【急停处理】
5. 任意状态按急停 → 立即进入急停状态
6. 急停解除后必须复位才能重新启动

【边界条件】
7. 连续按启动10次 → 只启动一次(边沿检测)
8. 暂停后按复位 → 直接回到空闲(不需要先恢复)
9. 错误状态按启动 → 无效,必须先复位

【状态一致性】
10. 暂停→恢复 → 从暂停点继续,不重复执行首次扫描动作
11. 掉电恢复到STEP2 → 不自动继续,需要人工确认后启动

【异常处理】
12. STEP1出现异常(超时/传感器故障) → 进入错误状态
13. 错误状态按复位 → 回到空闲,需重新检查故障原因

===============================================================================
  使用提示
===============================================================================

1. **状态号规划**:
   - 负数: 特殊状态(暂停/错误/急停)
   - 0: 空闲
   - 1-99: 工作状态(建议每10个数字一个大步骤)
   - 100+: 结束状态

2. **bFirstScan 用途**:
   - 用于区分"单次执行"和"持续执行"
   - 启动动作(如发脉冲)必须在 bFirstScan=TRUE 时执行
   - 持续动作(如保持输出)不检查 bFirstScan

3. **暂停保持机制**:
   - 暂停时 nStateLast 保存当前状态号
   - 恢复时 bFirstScan=FALSE,避免重复执行启动动作
   - 暂停状态下不改变任何输出(保持现场)

4. **扩展建议**:
   - 添加超时检测(每个步骤加 TON 定时器)
   - 添加步骤计时(记录每步耗时)
   - 添加步骤计数器(统计执行次数)
   - 添加步骤历史(记录最近N步的轨迹)

===============================================================================
*)
