# GCD多线程系列之被遗忘的dispatch\_sync

## dispatch\_async和dispatch\_sync

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

经过细读代码，最后找到了问题所在。在插入消息A时在代码(2)处得出了待刷新的indexSet（记为sectionsA），如果在代码(3)处block还未完成时又插入消息B，此时由于dataSource数组大小还未发生改变，所以得到的新的待刷新indexSet(记为sectionsB)与之前得到的sectionsA的indexSet会有重叠，从而使得刷新用到的indexSet少于要刷新的部分，导致部分消息不能显示。

找到问题所在，可以说已经解决了问题的百分之九十。有多种方法可供选择，以下是我想到的两种办法：

1. 一种办法是可以将代码(2)中生成sections的代码搬到tableView中的beginUpdates与endUpdates中间的(4)处；
2. 另一种方法是将(3)处的**dispatch\_async**改为**dispatch\_sync**，这样就是在必须要等到当前消息插入并且更新UI完成后才会插入下一条消息，肯定就不会再出现重叠的问题了。

##dispatch\_sync使用场景

###AFNetworking

在AFNetworking中dataTask都是在一个串行队列url\_session\_manager\_creation\_queue()中创建的，如下代码所示：

```objc
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    __block NSURLSessionDataTask *dataTask = nil;
    dispatch_sync(url_session_manager_creation_queue(), ^{
        dataTask = [self.session dataTaskWithRequest:request];
    });

    [self addDelegateForDataTask:dataTask completionHandler:completionHandler];

    return dataTask;
}
```

我阅读上面的代码之后马上产生了如下疑问
>1. 为什么dataTask的创建要在一个串行队列中进行呢？
>2. 为什么要使用dispatch\_sync而不是dispatch\_async呢？

关于问题1的确让人感到费解，直接创建不就可以吗？经过查找资料发现《Effective Objective-C 2.0》中的`Item 41: Prefer Dispatch Queues to Locks for Synchronization`，把串行队列当同步锁来用，这种作法主要是为了保证程序运行的线程安全，难道`dataTaskWithRequest`方法是非线程安全的？从iOS的文档中没找到相应描述，也没有源码可查，只能暂时按下心中的疑虑。

问题2比较好解释，由于需要在创建dataTask之后，还要对它进行一些其它的操作并返回，所以此时必须使用dispatch\_sync, 而不是dispatch\_async。


##dispatch\_sync死锁问题

在之前的部分，讲述了使用dispatch_sync带来的好处，它非常明显；同样的，如果使用不当，更会带来严重的问题。

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


