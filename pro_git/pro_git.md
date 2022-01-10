# Git高级功能与使用

## git submodule 合并到主工程
Git项目仓库中在之前引入了submodule，但在使过一段时间后发现：

原先的步骤
* 在主Repo中发动并提交

=>

* 先在submodule中的改动提交，然后再在主repo中提交

每次改动的复杂度是原先的2倍了。

由于主Repo中分了很多分支，导致submodule也分了多个分支来匹配主仓库的分支，使用起来很麻烦，于是决定去除submodule。那如果去掉submodule，将代码直接加入到主工程好了。于是引出了接下来的这个问题：

**那有没有办法将代码合到主工程，并保留历史记录呢？**

答案是有的，主要有以下几个步骤:

* 将.gitmodules和.git/config中的 ${sub} submodule 相关配置删除
* 重写 ${sub} submodule所有的历史提交记录，将这些历史记录中文件添加一个 ${path}的前缀，确保合并后文件路径正确
* 将submodule合并到主Repo并提交

这里比较麻烦的是第二点，如何重写历史。

Git官方提供了一个脚本git filter-branch命令，但这个命令使用起来比较复杂，个人推荐使用[git-filter-repo](https://github.com/newren/git-filter-repo)，使用使用简单多了。

如果再想偷个懒，可以使用一个叫[git-submodule-rewrite](https://github.com/jeremysears/scripts/blob/master/bin/git-submodule-rewrite)的脚本，非常方便

## 化解冲突：merge与rebase的ours和theirs

merge与rebase冲突时，它们的ours和theirs相反

* git rebase

当开发协作过程中，要保持分支干净整洁，就少不了要使用rebase.
当在分支B执行命令git rebase A时，ours指的是分支A的代码， theirs指的是分支B的代码
如何需要保留B分支的代码时，应该使用git checkout --theirs file_name

* git merge

当在分支B执行命令git merge B时，ours批的是B分支的代码，theirs批的是分支A的代码
如何需要保留B分支的代码时，应该使用git checkout --ours file_name

## 修改本地多个提交的顺序
当你有多个提交(时间先后分支为 A, B, C, D)时, 这个时候你想交换B,C两个提交

git rebase -i A
```
pick B
pick C
pick D
```

改变为
```
pick C
pick B
pick D
```

再次提交就可以了
