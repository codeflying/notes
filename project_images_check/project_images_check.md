# iOS 工程缺少或冗余图片检测

本文的原理是：分别得到使用到的图片名集合与存在的imageset集合，再对这两个集合进行比较。如果使用到的图片名不在imageset里，则表示缺少了此图片资源；反之如果imageset中的图片名没有被使用，则表示冗余。

## 查找使用的图片名
* 代码中使用的图片名
加载asset中的图片一般使用[UIImage imageNamed:@"imageName"]方法，都是在.m文件中，当然如果包含了C++相关的项目，可能存在.mm文件中。
```shell
find . -type f -name "*.m" -exec grep "imageNamed:@" {} \; | sed -n 's/^.*imageNamed:@"\([^"]*\)".*$/\1/p' > $imagenames
```
* 布局文件中使用的图片名
我的项目中布局文件既有xib，同时也存在storyboard文件，用文本编辑器打开查看，可以看到其格式为... image="xxx" ... ；于是很快可以通过find命令与sed命令提取出图片名
```shell
find . -name "*.storyboard" -or -name "*.xib" -exec grep "image=" {} \; | sed -n 's/^.*image=\"\([^"]*\)\".*$/\1/p' >> $imagenames
```
## 得到asset资源名
asset资源主要是以文件夹的方式组织的，形式如下:

>name.imageset  
>    |- Content.json  
>    |- name@2x.png  
>    |- name@3x.png  

于是可以通过find 命令与basename命令找出所有的imageset

```shell
find . -name "*.imageset" -exec basename {} ".imageset" \; >$imagesets
```

## 比较使用到的图片名与存在的图片名
通过前面的两个步骤，分别得到了使用到的图片名集合与存在的imageset集合，这两个集合分别输出到两个不同的文件当中。接下来，就要对这两个集合进行比较了，即某个集合中的图片名是否在另一个集合中，用到了awk脚本，这些awk脚本放在check_image.awk中。
文件中的具体代码如下：
```awk
NR==FNR{
    imagesets[$0] = 1;
}
NR>FNR{
    imagenames[$0] = 1;
}
END{
    for (name in imagenames) {
        if (imagesets[name] == 0) {
            print name, "not exist";
        }
    }
    for (set in imagesets) {
	if (set ~ /[0-9]/) {
            continue;
        }
        if (imagenames[set] == 0) {
            print set, "unnecessary";
        }
    }
}
```

## 总结

综上所述，可以得到整个脚本的代码如下所示，基本的check_image.awk就是上文的awk脚本文件。
```shell
#!/bin/sh
imagesets=/tmp/imagesets
imagenames=/tmp/imagenames
find . -name "*.imageset" -exec basename {} ".imageset" \; >$imagesets
find . -type f -name "*.m" -exec grep "imageNamed:@" {} \; | sed -n 's/^.*imageNamed:@"\([^"]*\)".*$/\1/p' > $imagenames
find . -name "*.storyboard" -or -name "*.xib" -exec grep "image=" {} \; | sed -n 's/^.*image=\"\([^"]*\)\".*$/\1/p' >> $imagenames

awk -f check_image.awk $imagesets $imagenames
```

> 不足之处：由于代码中存在由代码拼接的图片名，所以此方法检测到的冗余图片不一定是100%准确
