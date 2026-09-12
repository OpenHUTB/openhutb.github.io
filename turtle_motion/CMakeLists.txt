cmake_minimum_required(VERSION 3.0.2)
project(turtle_motion)

## 查找catkin和我们用到的依赖（rospy和geometry_msgs）
find_package(catkin REQUIRED COMPONENTS
  rospy
  geometry_msgs
)

## 声明这个catkin包，因为包里面只有python代码，所以不用导出库
catkin_package()

## 把square_draw.py装到bin目录下，装好之后就可以用
## rosrun turtle_motion square_draw.py 直接运行了
catkin_install_python(PROGRAMS
  scripts/square_draw.py
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)
