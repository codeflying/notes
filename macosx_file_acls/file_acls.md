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
-rw-r--r--+ 1 xxx  staff  571  2 16 20:30 main.go
-rw-r--r--@ 1 xxx  staff  571  2 26 16:02 solution.c
```

可以看到main.go中的@已经变成了+了，清掉了attribute, 但是还是不能修改文件，于是困惑了。于是只能继续跟踪下去，这个+号又代表什么呢。查资料得到+表示有设置ACLs，有访问控制权限，可以通过ls的-le选项查看

```shell
~/Documents/leetcode/1_two_sum » ls -lae main.go
-rw-r--r--+ 1 xxx  staff  571  2 16 20:30 main.go
 0: group:everyone deny write,delete,append,writeattr,writeextattr,chown
```

终于找到了不能修改的原因了，使用 chmod -R -N 对所有拷贝过来的文件夹操作一遍，终于可以快乐的使用电脑了。


## Others

一般来说我们直接使用RWX三种权限在USER,GROUP,OTHER下的权限使用就可以了，为什么还要设置这个ACLs呢?
举个例子:

假设你在 macOS上创建了两个用户，分别有不同的用户设置，并且经常操作某一个目录比如 /Users/Shared/screencasts
如果只是做一般的读操作，只要把这两个用户放在同一个组即可。但是如果你使用某一个登陆用户(A)在该目录下新建新的文件与目录，那么你就要对它进行chmod操作，才能让你在另一个用户(B)下才能不使用sudo进行操作，并且每新建一个目录和文件都要chmod一次，非常麻烦。这个时候ACLs就有用武之地了。

这时只要对 /Users/Shared/screencasts 目录作以下操作就可以了

```shell
$ chmod -R +a "group:staff allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit" /Users/Shared/screencasts
```

通过inherit，这样之后，就可以愉快地在两个用户之间切换了。

