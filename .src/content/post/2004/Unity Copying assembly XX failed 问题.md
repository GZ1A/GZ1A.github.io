---
# 常用定义
draft: false

title: "Unity Copying assembly XX failed 问题"
date: 2020-04-30T05:41:26+08:00					# 创建时间
author: "昼阴夜阳"             		# 作者

# 分类和标签
categories: ["技术"]		            # 分类
tags: ["Unity"]  						# 标签

---

遇到过好多次了，这次往 Unity 里导入 3DMax 模型的时候又遇到了这个问题。

> Copying assembly from 'TempUnity.VSCode.Editor.dll' to 'LibraryScriptAssembliesUnity.VSCode.Editor.dll' failed

## 原因

按参考链接最后的图中说的那样，主要考虑以下几种原因

* 文件正在使用，被锁定了无法复制
* 杀毒软件阻止了复制
* 路径过长

## 解决方案

点对点解决

* 关闭可能使用它的进程
* 关闭**杀毒软件**实时防护或者将 Unity 加入到信任名单
* 把项目移浅点...

然后 **保存退出重新启动 Unity** 一通操作，大概就能解决了。

## 参考链接

[知乎 | 无法拷贝Assembly-CSharp.dll](https://zhuanlan.zhihu.com/p/41383656) 

[博客 | Unity Copying assembly .... failed 错误解决](https://blog.csdn.net/hhfan3/article/details/84324615?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-1&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-1) 