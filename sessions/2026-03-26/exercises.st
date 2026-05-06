(*
===============================================================================
  今日练习: 单电机启停控制
  日期: 2026-03-26
  
  核心目标: 掌握自保持、急停优先、停止优先的工程化表达
  请补充 TODO 部分的逻辑，实现满足标准的 FB_MotorControl。
===============================================================================
*)

FUNCTION_BLOCK FB_MotorControl
VAR_INPUT
    iStart      : BOOL;     // 启动按钮 (常开动作: TRUE 为按下)
    iStop       : BOOL;     // 停止按钮 (此处假定 TRUE 为按下)
    iEmergency  : BOOL;     // 急停信号 (TRUE 为触发急停)
END_VAR

VAR_OUTPUT
    oRun        : BOOL;     // 电机运行输出控制
END_VAR

VAR
    bRunning    : BOOL;     // 内部运行状态
END_VAR

// ==========================================
// 逻辑编写区
// ==========================================

// TODO 1: 添加急停优先逻辑

if iStart and not iStop AND not iEmergency then
bRunning:=TRUE;
ELSIF iStop or  iEmergency then
bRunning:=FALSE;
end_if;


// TODO 2: 添加停止优先逻辑
// TODO 3: 添加启动互锁与自保持逻辑
// 
// 提示：你可以使用结构的 IF...ELSIF...ELSE，或者纯布尔逻辑 (:= ... AND_NOT ...)



// 最终将内部状态赋值给输出引脚
oRun:=bRunning AND not iEmergency;

END_FUNCTION_BLOCK
