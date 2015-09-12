#被遗忘的dispatch\_sync

##dispatch\_async和dispatch\_sync

初学iOS开发时，忘记把更新UI操作放入主线程总是很容易的一件事，发生过很多当时认为很不科学的灵异事件，惊呼怎么这么奇怪，也为此吃过不少苦头。

因此我们谨记: **UI更新必须放在主线程**

```objc
dispatch_async(dispatch_get_main_queue(), ^{ /* 更新UI */ })
```
并且与之搭配的必然是dispatch\_async（UI更新与dispatch\_async更配哦）。并且不知不觉中形成习惯，变得不那么爱思考了，谁让dispatch\_async这么人见人爱呢? 如果说dispatch\_async是一位美丽的公主，那dispatch\_sync则像一只丑小鸭，被人遗忘在角落里的那一只。

最近在做一个项目有即时通讯功能，重构聊天详情页面时遇到了一个BUG，它的具体情形是这样的：
>当用户打开应用，如果在同时(很短的时间内)都收到离线消息和在线消息，有些离线消息或在线消息将会不被显示。

实现大致是这样的：接收消息时，会将消息与时间标签（如果有）的数组插入到dataSource，然后再更新相应的Section的UI，调用到的insertMessage函数代码实现大致如下：

``` objc
- (void)insertMessage:(Message *)message
{
	disaptch_async(messageQueue, ^{ // messageQueue为串行队列

		/* (1) */
		// 待插入的消息列表
		NSArray *messages = @[<NSString> /* 时间标签(如果有) */, message];

		// 得到要更新的Section的IndexSet (2)
		NSIndexSet *sections = @[weakSelf.dataSource.count, ..., weakSelf.dataSource.count + messages.count - 1];

		/* (3) */
		dispatch_async(dispatch_get_main_queue(), ^{

			[weakSelf.tableView beginUpdates];
			// 新信息数组 插入到 dataSource
			[weakSelf.dataSource addObjectsFromArray:messages];
			// (4)
			// 将数据源更新到tableView
			[weakSelf.tableView insertSections:sections withRowAnimation:UITableViewRowAnimationNone];

			[weakSelf.tableView endUpdates];

		});
	});
}
```

经过细读代码，最后找到了问题所在。发现在插入消息A时在代码(2)处构造了sections#A，在代码(2)处block还未完成时，这时又插入消息B，此时由于dataSource的大小还未发现变化，生成的sections#B 与sections#A 的indexSet发生了重叠，使得刷新用到的indexSet少于要刷新的部分，导致部分消息不能显示。

既然已经发生了问题的所在就好办了。为了解决这个问题，有多种方法，其中一种方法是可以将代码(1)中的生成sections的代码搬到tableView中的beginUpdates与endUpdates中间的(3)处；另一种方法是将(2)处的**dispatch\_async**改为**dispatch\_sync**，这样就是在必须要等到当前消息插入并且更新UI完成后才会插入下一条消息，肯定就不会再出现重叠的问题了。

##dispatch\_sync死锁问题

在上一部分，讲述了使用dispatch_sync带来的好处，它非常明显；同样的，如果使用不当，更会带来严重的问题。

**在queue A中dispatch\_sync一个block到queue A，将会导致死锁。**

比如在main queue中执行以下代码:

```objc
dispatch_sync(dispatch_get_main_queue(), ^{});
```

将导致主线程死锁，分析如下：
当代码执行到此条语句时，会阻塞主队列直到block中的任务完成；但由于主队列是FIFO的，必须要完成当前的任务才能去执行block中的任务；从而造成了死锁，将会永远地等待下去。

为了防止在主线程发生这种事情，可以使用诸如**dispatch\_sync\_main\_safe**这样自定义的函数，如下所示:

```objc
void dispatch_sync_main_safe(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}
```

##总结
在使用dispatch\_sync时，固然要小心谨慎以防止死锁，但也不能因噎废食，在适当的场景下dispatch\_sync还是非常有必要的；除了本文中提及的场景外，在一些处理sqlite数据库的操作、网络下载（如AFNetworking）中，使用dispatch\_sync都会带来很大的便利。




