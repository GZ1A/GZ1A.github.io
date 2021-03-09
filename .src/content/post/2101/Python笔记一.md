---
# 常用定义
draft: false

title: "Python 笔记 语法基础"
date: 2020-12-27T20:13:03+08:00			# 创建时间
author: "昼阴夜阳"             				# 作者

# 分类和标签
categories: ["技术"]		            		# 分类
tags: ["Python"]		    		# 标签

---

## 语法基础

### 数据类型

#### 数字 Number

用于存储数值的，不可改变的数据类型（改变等于分配一个新对象）

```python
int1, int2, int3 = 13, -0o10, 0x6A  # 0o 8进制 0x16进制
float1, float2 = 2e-98, 450.0
complex1, complex2 = -.01 + 2.3E+45j, 0J  # 顺序无关，可以省略，有j就行
```

#### 字符串 String

**用 ' '/" "/''' '''/""" """ 标识**

由数字、字母、下划线组成的一串字符。其中文档字符串可以用于函数注释及文档测试

```python
s1, s2, s3 = 'abcdef', "123456", \
             """__some__
__long__
__text__"""
print(s3)

# s3 输出
# __some__
# __long__
# __text__

def func(para):
    """
    function for test
    
    Example:
    >>> func(para)
    1
    """
    return 1
```

##### 基本操作

* `s1 + s2` 直接组合
* `s1 * 2` 两个 s1 组合

##### 截取

 ![image-20210111030248820](https://gitee.com/GZ1A/image-hosting/raw/master/blog/2021/01/image-20210111030248820.png)

分成 3 部分

[ [**头下标** = 最前端 `0`] : [**尾下标** = 最后端 `n`] : [截取字符步长= 正向逐个 `1` ] ]

方便记忆，左闭右开`[front : end)`

```python
s_cd, s_def, s_fedcba = s1[-4:-2], s1[3:], s1[::-1]
```

[博客 | python逆序截取](https://blog.csdn.net/win_turn/article/details/52998912)

#### 列表 List

**用 [] 标识**

python 最通用的复合数据类型，支持字符，数字，字符串甚至可以包含列表

```python
aLargeList = [345, 'bcd', [1.0, 'aSmallList']]
```

##### 操作

和字符串类似

#### 元组 Tuple

**用 () 标识**

元组类似列表，但不能二次赋值，相当于一个初始化后就只读的列表。

#### 字典 Dictionary

**用 {}  标识**

列表是有序的对象集合，字典是无序的对象集合。字典通过键来存取元素，而不是通过偏移。

```python
myDict = {'initContent':('aTuple',21)}
myDict['oneText'] = 'This is some text'
myDict['List01'] = ['err', 17]
```

直接 print 输出全部键值对

#### 数据类型转换

使用目标类型构造函数

```python
str(x)
list(s)
...
```

## 运算符

### 算术运算符

```python
# +-*/
11 % 5 == 1	# 取余
11 // 5 == 2	# 取整除
11 ** 5 == 161051	#幂
```

### 逻辑运算符

```python
x and y # 如果 x 为False,返回 x(False),否则返回 y 的计算值
		# True and 5 == 3
x or y	# 如果 x 非False,返回 x 的值,否则返回 y 的计算值
		# "err" or 0 == "err"
not x	# 返回 True/False
```

### 赋值运算符

python中会为每个出现的对象分配内存，哪怕他们的值完全相等（注意是相等不是相同），而赋值就是传递引用

## 流程控制

### 条件语句

```python
if <expression>:
    <suite>
else if <expression>:
    <suite>
else:
    <suite>
```

* python 没有 switch ，用 elif 实现多个条件判断

### 循环语句

#### for / while / else

```python
# while 循环,条件循环
while <expression>:
    <suite>
else:	# 当循环条件为 false 而跳出时执行
    <suite>
```

```python
# for 循环,适合遍历序列（列表、字符串）
for <iterating_var> in <sequence>:
    <suite>
else:	# 当循环条件为 false （完成遍历，正常跳出） 时执行
    <suite>

# 通过序列索引迭代
for index in range(len(aTinyList)):
	# do something
    print aTinyList[index]
```

#### break / continue / pass

break : 停止最小封闭 for / while 循环

continue : 跳过当前循环剩余语句

pass : 占位用，不做事情，(通常防止空函数报错)













