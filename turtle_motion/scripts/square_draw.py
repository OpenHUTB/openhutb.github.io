#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# 这个节点用来控制小海龟画一个正方形
# 思路：直走一段距离 -> 停一下 -> 左转90度 -> 再直走，循环4次就是正方形了
# 节点名叫 turtle_square_node，速度指令都发到 /turtle1/cmd_vel 话题上

import math

import rospy
from geometry_msgs.msg import Twist

# 全局的发布者，下面几个函数都要用它来发消息
pub = None


def publish_stop():
    # 发一个全0的速度，让海龟停下来，不然它会因为惯性再往前滑一段
    stop_msg = Twist()
    pub.publish(stop_msg)


def move_forward(speed, distance):
    # 直走函数：speed 是速度（m/s），distance 是要走的距离（m）
    move_msg = Twist()
    move_msg.linear.x = speed      # 只设置x方向的线速度
    pub.publish(move_msg)

    # 这里是时间开环控制：不用管海龟实际走了多远，
    # 根据 t = s / v 算出时间，时间到了就停下来
    t = distance / speed
    rospy.sleep(t)

    # 时间到了，发0速度停下来
    publish_stop()
    rospy.loginfo("直走完成，走了 %.2f 米，用了 %.2f 秒", distance, t)


def rotate_90_degrees(angular_speed):
    # 左转90度的函数：angular_speed 是角速度（rad/s）
    rotate_msg = Twist()
    rotate_msg.angular.z = angular_speed   # 绕z轴正方向转，也就是逆时针
    pub.publish(rotate_msg)

    # 90度换成弧度就是 math.pi / 2，时间 = 角度 / 角速度
    t = (math.pi / 2) / angular_speed
    rospy.sleep(t)

    # 时间到了，发0速度停下来
    publish_stop()
    rospy.loginfo("左转90度完成，用了 %.2f 秒", t)


if __name__ == '__main__':
    # 初始化节点
    rospy.init_node('turtle_square_node')

    # 创建发布者，往 /turtle1/cmd_vel 话题发 Twist 类型的消息
    pub = rospy.Publisher('/turtle1/cmd_vel', Twist, queue_size=10)

    # 先等1秒，让发布者和turtlesim连接好，不然第一条消息可能会收不到
    rospy.sleep(1.0)

    # 运动参数，可以自己改着玩
    speed = 1.0           # 线速度 1 m/s
    distance = 2.0        # 正方形边长 2 m
    angular_speed = 1.0   # 角速度 1 rad/s

    try:
        rospy.loginfo("开始画正方形，边长是 %.2f 米", distance)

        # 正方形有4条边，所以循环4次
        for i in range(4):
            # 检查一下节点有没有被关掉，关了就退出循环
            if rospy.is_shutdown():
                break

            # 第1步：直走一条边
            rospy.loginfo("正在画第 %d 条边", i + 1)
            move_forward(speed, distance)

            # 第2步：停0.5秒，速度置0，把惯性消掉
            publish_stop()
            rospy.sleep(0.5)

            # 第3步：逆时针转90度
            rospy.loginfo("正在转第 %d 个角", i + 1)
            rotate_90_degrees(angular_speed)

            # 第4步：再停0.5秒，速度置0，把惯性消掉
            publish_stop()
            rospy.sleep(0.5)

        rospy.loginfo("正方形画完啦！")
    except rospy.ROSInterruptException:
        # 按Ctrl+C或者节点被关闭的时候会走到这里
        rospy.loginfo("节点被中断，让海龟停下来")
    finally:
        # 不管正常画完还是中间出错，最后都再发一次0速度，保险一点
        if pub is not None:
            publish_stop()
