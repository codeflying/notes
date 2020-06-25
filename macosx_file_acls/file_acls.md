# macOS ACLs

## 引子

前两天想体验一下macOS Big Sur, 就将电脑升级，使用后发现还有很多BUG，于是又折腾降级的事。为了防止失败数据，用TimeMachine作了个备份，过程很艰辛，但终于降级成功，然后再手动把数据从TimeMachine里Copy到macOS Catalina中。
但问题马上来了，在使用的过程中，发现拷贝过来的文件夹下不能新建文件，拷贝过来的文件不能修改，除非使用sudo.


## 定位问题

```shell
~/Documents/leetcode/1_two_sum » ls -l
total 16
-rw-r--r--@ 1 xxx  staff  571  2 16 20:30 main.go
-rw-r--r--@ 1 xxx  staff  571  2 26 16:02 solution.c

```
发现权限是644，owner可以写文件，百思不得其解中...

然后突然发现权限 -rw-r--r--@ 这个最后是一个'@'，这是个什么东东，查了一下，表示文件额外添加的attribute，会不会是这个原因呢？

```shell
~/Documents/leetcode/1_two_sum » xattr main.go
com.apple.metadata:_kTimeMachineNewestSnapshot
com.apple.metadata:_kTimeMachineOldestSnapshot
```

发现多出了跟TimeMachine相关的两个attr，会不会是这两个导致的呢，使用 'xattr -c' 命令清除attribute后，查看一下
```shell
~/Documents/leetcode/1_two_sum » ls -l
total 16
-rw-r--r--+ 1 guavakid  staff  571  2 16 20:30 main.go
-rw-r--r--@ 1 guavakid  staff  571  2 26 16:02 solution.c
```

可以看到main.go中的@已经变成了+了，困惑了，这个+号又代表什么呢。查资料得到+表示有设置ACLs，有访问控制权限，可以通过ls的-le选项查看

```shell
~/Documents/leetcode/1_two_sum » ls -lae main.go
-rw-r--r--+ 1 guavakid  staff  571  2 16 20:30 main.go
 0: group:everyone deny write,delete,append,writeattr,writeextattr,chown
```

终于找到了不能修改的原因了，使用 chmod -N -R 对所有拷贝过来的文件夹操作一遍，终于可以快乐的使用电脑了。

