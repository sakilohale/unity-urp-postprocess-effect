# Blur 





- Gaussian Blur(GB) 

  ![image-20230801131220817](image\image-20230801131220817.png)

  ![image-20230801131231054](image\image-20230801131231054.png)

  

- Double Blur(DB)

  ![image-20230801131154607](image\image-20230801131154607.png)

  ![image-20230801131205895](image\image-20230801131205895.png)



- Kawase Blur(KB)

  ![image-20230801131308767](image\image-20230801131308767.png)

  ![image-20230801131338608](image\image-20230801131338608.png)

  

- Radial Blur(RB)

  ![image-20230801131439976](image\image-20230801131439976.png)

  ![image-20230801131448965](image\image-20230801131448965.png)

  

## 项目版本

unity 2021.3.10f1c2

urp 12.1.7(正常unity版本下的对应urp版本)



## 文件结构

文件夹名称代表模糊类型，里面共有一个材质，一个shader文件，以及两个C#脚本文件。

以GB举例：

![image-20230801125513400](image\image-20230801125513400.png)

其中，MyGBlur.cs为后处理脚本，GBVO为自定义后处理参数的Volume脚本，MyGBlur.shader为后处理shader，赋于GB_Mat上。



## 使用方法

只能在URP中使用，首先在使用的管线中添加对应的RenderFeature脚本，以GB为例，也就是MyGBlur.cs。

(一般在setting文件夹下，找到Renderer)

![image-20230801130322270](image\image-20230801130322270.png)

![image-20230801130349365](image\image-20230801130349365.png)

添加对应的Renderfeature脚本，随后将后处理材质赋予该脚本中的Mymat项：

![image-20230801130423205](image\image-20230801130423205.png)

在这里其实就可以正常使用该后处理效果了，但为了操作简便，可以使用Volume组件来优化用户的操作体验。

首先在场景中新建一个Global Volume：（Hierarchy窗口，鼠标右键，Volume->Global Volume）。

![image-20230801130724022](image\image-20230801130724022.png)

点击Profile选项右边的New，新建一个容器文件，然后会跳出一个Add Override，以GB为例，选择我们的GBVO。

![image-20230801130838623](image\image-20230801130838623.png)

![image-20230801130848680](image\image-20230801130848680.png)

这样一下，我们就可以在场景中直接调试后处理的效果了，包括是否生效该后处理，以及后处理相关的一些参数。

其他效果用法大同小异。

