---
# 常用定义
draft: false

title: "Python 笔记 函数"
date: 2021-01-05T22:08:53+08:00			# 创建时间
author: "昼阴夜阳"             				# 作者

# 分类和标签
categories: ["技术"]		            		# 分类
tags: ["Python"]		    		# 标签


---

## 函数

### 函数定义函数代码块以 **def** 关键词开头，后接函数标识符名称和圆括号**()**

- 任何传入参数和自变量必须放在圆括号中间。圆括号之间可以用于定义参数
- 函数的第一行语句可以使用文档字符串用于存放函数说明
- 函数内容以冒号起始，并缩进
- **return [表达式]** 结束函数，选择性地返回一个值给调用方。不带表达式的return相当于返回 None `<class 'NoneType'>`

```python
def functionname( parameters ):
   """函数_文档字符串"""
   <function_suite>
   return <expression>
```

### 参数传递

传递参数，就是对函数内新框架中的变量进行赋值。

python 中一切都是对象，而根据赋值方式不同能分成 `不可变(immutable)对象` 和 `可变(mutable)对象`

**strings tuples numbers** 是不可更改的对象，list dict 则是可以修改的对象。传递不可变对象时，类似 C++ 的值传递。否则类似引用传递。

### 参数类型

#### 默认参数

必须定义在所有非默认参数后

`para = "default_value"`

#### 不定长参数

最多只能有一个，如果放在其他参数前，进入后需要用关键词参数跳出这个参数（`para_name = value`）

声明时不会命名，可以变长

```python
def functionname([formal_args,] *var_args_tuple ):
   "函数_文档字符串"
   function_suite
   return [expression]
```

可以对 *var_args_tuple 进行遍历，从而逐个参数操作

### 引用外部库

模块(Module)，是一个 Python 文件，以 .py 结尾，包含了 Python 对象定义和Python语句。

#### 引入模块

在文件开头引入

`import module`

引入指定部分

`from modname import name,name... as nickname,...`

### 遍历文件夹

用 os 模块的 walk() 方法，在目录树中遍历。

```python
for root, dirs, files in os.walk("dir", topdown=False):
    for name in files:
        print(os.path.join(root, name))
    for name in dirs:
        print(os.path.join(root, name))
```

### 处理文件

内置 open 函数，创建文件对象并读入对应文件。然后使用 file 类的函数进行处理文件内容。

用 os 的函数处理文件本身信息

```python
fo = open("foo.txt", "a+")
fo.write("append some text\n")
fo.seek(0, 0)
print(fo.read())
fo.close()

newname = "foo_new.txt"
if(os.path.exists(newname)):
    os.remove("foo_new.txt")
os.rename("foo.txt", "foo_new.txt")
```

