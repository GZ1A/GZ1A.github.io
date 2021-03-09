---
# 常用定义
draft: false

title: "ScriptableObject 实例化"
date: 2020-10-22T12:05:34+09:00			# 创建时间
author: "昼阴夜阳"             				# 作者

# 分类和标签
categories: ["技术"]		            		# 分类
tags: ["Unity","ScriptableObject"]		    		# 标签
---

[论坛 | cloning of ScriptableObject](https://answers.unity.com/questions/39130/cloning-of-scriptableobject.html)

[文档 | Object.Instantiate](https://docs.unity3d.com/ScriptReference/Object.Instantiate.html)

想要实例化一个 ScriptableObject，从而原本的基础上动态修改，然而中文讨论完全搜不出来相关的...

真要查问题害得看英文区。最后调用了基类 `Object` 的实例化方法。

```c#
MyScriptableObject clone = Object.Instantiate(original) as MyScriptableObject;
```



