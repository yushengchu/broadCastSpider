#### 简介

基于Tensorflow + BroadCast Extension实时获取并识别iOS设备屏幕内容



#### 系统要求

iOS11或以上版本



#### 什么是BroadCast Upload Extension?

BroadCast Upload Extension在iOS10的时候推出，用于系统录屏的插件。



#### 客户端流程

![image-20191118165847233.png](https://upload-images.jianshu.io/upload_images/688404-76322d0ab91f6caf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 架构

![image-20191118151036879.png](https://upload-images.jianshu.io/upload_images/688404-36556c48fd3bb9ff.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 如何使用

1. 编译真机运行

2. 点击界面中间录屏按钮

3. 在弹出的控制中心页面选择`BroadCastExtension`点击开始录屏

4. 打开微信，查看Xcode控制台输出，会实时打印当前界面的识别情况

   

#### 使用效果

![](https://user-gold-cdn.xitu.io/2019/11/20/16e892447b56f552?w=480&h=313&f=gif&s=5177059)

![通讯录页面识别度77%](https://user-gold-cdn.xitu.io/2019/11/20/16e8922645120857?w=1000&h=831&f=jpeg&s=127127)

![发现页面识别度97%](https://user-gold-cdn.xitu.io/2019/11/20/16e89226709b18d1?w=1000&h=722&f=jpeg&s=102135)

可以看到，在模型训练好的情况下，实时录屏的识别度是非常高的，配合服务端OCR可以获取任何出现在屏幕上的内容。

