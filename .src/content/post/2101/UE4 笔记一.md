---
# 常用定义
draft: false

title: "UE4 笔记 （一） 导引"
date: 2021-01-21T00:18:54+08:00			# 创建时间
author: "昼阴夜阳"             				# 作者

# 分类和标签
categories: ["技术"]		            		# 分类
tags: ["UE4"]		    		# 标签

---

# 材质编辑器界面操作基础

## 参考

[文档 | 材质表达式参考文档](https://docs.unrealengine.com/zh-CN/RenderingAndGraphics/Materials/ExpressionReference/index.html)

[博客 | 材质节点大全](https://blog.csdn.net/zhangxiaofan666/article/details/93604724)

[UE4 官方文档](https://docs.unrealengine.com/zh-CN/index.html)

[官方教程平台](https://www.unrealengine.com/zh-CN/onlinelearning-courses)

[文档 | 材质编辑器参考](https://docs.unrealengine.com/zh-CN/RenderingAndGraphics/Materials/Editor/index.html)

![image-20210125034915035](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/01/image-20210125034915035.png)

## 概念

使用材质表达式节点网络，构建定制化材质着色器（Shaders）。材质表达式节点：用以定义材质的代码或代码集可视化脚本节点。以此创建可修改属性的实例化材质（Instance Material），改变材质外观与行为事件。

每个从材质都有`基础材质节点`，网络最终与基础材质节点上的引脚连接。还有`表达式节点 `和`函数节点`。表达式节点中又有代表了向材质实例公开的属性的`参数节点`。

![image-20210125035616784](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/01/image-20210125035616784.png)

 **材质域（Material Domain）：**定义材质类型

## 节点操作

### 基本操作

* 图表中鼠标右键 / 材质图表右侧控制板 / 按住热键并左键单击 创建新节点

* ctrl + w 复制

* 拖动 连接引脚

* 在细节面板进行修改

* Shift双击引脚：标记引线。

  ●Alt单击引脚：断开该引脚所有连接。

  ●Ctrl+B：在内容浏览器中查找。

  ●空格：刷新表达式预览。

## 描述和注释

每个材质节点包含一个 **描述（Desc）** 属性 **右键** 或者通过面板来设置

![image-20210125044700895](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210125044700895.png)

（选中多个节点后）按C 创建 `注释节点`，并且可在细节中设置颜色、字体大小等

![image-20210125044956251](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/02/image-20210125044956251.png)

