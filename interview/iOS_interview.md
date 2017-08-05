# iOS 面试

## 领域知识

### Objective-C 基础
如何访问并修改一个类的私有属性？

const NSString * 和 NSString *const 有什么区别

ARC下，不显式指定任何属性关键字时，默认的关键字都有哪些？

什么情况使用 weak 关键字，相比 assign 有什么不同？

这个写法会出什么问题： @property (copy) NSMutableArray *array;

IBOutlet连出来的视图属性为什么可以被设置成weak? 如果改成copy会怎么样？

下面的代码输出什么？具体原因是什么？
```objc
   @implementation Son : Father
   - (id)init
   {
       self = [super init];
       if (self) {
           NSLog(@"%@", NSStringFromClass([self class]));
           NSLog(@"%@", NSStringFromClass([super class]));
       }
       return self;
   }
   @end
```

简述KVO, KVC, NotificationCenter, Delegate, Block

简述Objective-C 中的内存管理机制

#### block 
block是为了解决什么问题而诞生的?具体有哪几种类型？

在block内如何修改block外部变量？

使用block时什么情况会发生引用循环，如何解决？

### Objective-C 异常与调试

lldb（gdb）常用的调试命令？

哪些情况下会产生BAD\_ACCESS错误？如何调试BAD\_ACCESS错误?

什么时候会报unrecognized selector的异常？

什么时候会用到Instruments

### GCD
GCD的队列（dispatch_queue_t）分哪两种类型？

dispatch\_barrier\_async的作用是什么？

苹果为什么要废弃dispatch_get_current_queue？

如何用GCD同步若干个异步调用？（如根据若干个url异步加载多张图片，然后在都下载完成后合成一张整图）

以下代码运行结果如何？具体原因是什么？
```objc
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"1");
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"2");
    });
    NSLog(@"3");
}
```

### 设计模式

在工作中常用的设计模式有哪些？

抽象工厂模式在Cocoa SDK的体现

### 业务能力

谈一谈AutoLayout, Mansory

怎么看xib与纯代码方式写UI？

什么时候应该使用xib, 什么时候使用storyboard

## 设计
大文件下载
设计一个无限滑动的slide show
 @autoreleasepool 在哪些情况下会用到，如何设计一个相同功能的实现

## Coding

按层换行打印一个二叉树的值

将一个32位长整型转换为点分式的IPv4地址
