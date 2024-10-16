#!/bin/bash

# 定义日志目录
LOG_DIR="$HOME/.ros/log"
LOG_FILE="my_node.log"
BACKUP_LOG_PATTERN="my_node.*.log"

# 清理之前的日志文件
echo "Cleaning up old log files..."
rm -f $LOG_DIR/$LOG_FILE
rm -f $LOG_DIR/$BACKUP_LOG_PATTERN

# 启动 ROS2 节点，生成日志
echo "Starting ROS2 node to generate logs..."
source install/setup.bash
ros2 launch my_ros2_logging_project log_test_node_launch.py &

# 等待日志生成
sleep 10

# 检查日志文件是否生成
if [ -f "$LOG_DIR/$LOG_FILE" ]; then
    echo "Log file $LOG_FILE has been created successfully."
else
    echo "Error: Log file $LOG_FILE was not created."
    exit 1
fi

# 检查日志文件内容是否包含期望的日志级别
echo "Checking log file contents..."
if grep -q "INFO log message number" "$LOG_DIR/$LOG_FILE" && \
   grep -q "WARNING log message number" "$LOG_DIR/$LOG_FILE" && \
   grep -q "ERROR log message number" "$LOG_DIR/$LOG_FILE"; then
    echo "Log file contains expected log messages (INFO, WARNING, ERROR)."
else
    echo "Error: Log file does not contain expected log messages."
    exit 1
fi

# 生成更多日志，等待日志轮转
echo "Generating more logs to trigger log rotation..."
sleep 10  # 等待足够的日志输出时间

# 检查日志轮转是否发生
BACKUP_LOG_COUNT=$(ls $LOG_DIR/$BACKUP_LOG_PATTERN 2> /dev/null | wc -l)
if [ "$BACKUP_LOG_COUNT" -gt 0 ]; then
    echo "Log rotation has occurred. Backup log files count: $BACKUP_LOG_COUNT"
else
    echo "Error: Log rotation did not occur."
    exit 1
fi

# 确保不超过5个备份日志文件
if [ "$BACKUP_LOG_COUNT" -le 5 ]; then
    echo "Log rotation is working correctly, no more than 5 backup files."
else
    echo "Error: More than 5 backup log files found."
    exit 1
fi

# 停止 ROS2 节点
echo "Stopping ROS2 node..."
pkill -f "ros2 launch my_ros2_logging_project log_test_node_launch.py"

echo "Test completed successfully."
