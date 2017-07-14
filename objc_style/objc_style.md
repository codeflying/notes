# 代码风格与规范

## 文件布局

按下面类别进行分块，每块之间空两行

* #import or @import
* @class or @protocol reference
* const defines
* @interface / @implement

## @interface
其中interface内部布局如下所示, 要实现的protocol新起一行，每一个占一行； 分块按属性，类方法，实例方法排序，每块之间空一行。其中具体的排版按以下方式。
```objc
@interface Person : NSObject
<Protocol1,
Protocol2>

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, assign) Gender gender;
@property (nonatomic, assign) NSInteger age;

+ (instancetype)personWithFirstName:(NSString *)name lastName:(NSString *)lastName gender:(Gender)gender age:(NSInteger)age;

- (NSString *)fullName;
```

## 语法
函数与基本语句语法如下所示，

```objc

    - (type)func 
    {

    }

    + (type2)func2
    {

    }

    if (condition1 && condition2) {
        statements
    }

    switch (var):
    case type1: {
        statements1;
        break;
    }
    case type2: {
        statements2;
        break;
    }
    default:
    break;

    for ( x in xs) {

    }

    while (condition1 || condition2) {

    }
```

## ViewController 及其子类代码布局
布局按以下顺序进行：
* #pragma mark - Life Cycle
* #pragma mark - Delegate
* #pragma mark - Event Response
* #pragma mark - Private
* #pragma mark - Getter and Setter
将Getter/Setter放在最后是为了将主要逻辑放在文件的前面。

## 能不放到 ViewController里的尽量不放在到ViewController
由于ViewController都是跟具体的业务逻辑相关，重用的可能性非常低。如果将能不放在ViewController的逻辑移出到其它地方，一个是便于重用与测试，二个以解决ViewController臃肿后期不好维护的问题。

