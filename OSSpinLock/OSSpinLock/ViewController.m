//
//  ViewController.m
//  Lock
//
//  Created by Sun on 2020/1/17.
//  Copyright © 2020 sun. All rights reserved.
//

#import "ViewController.h"
#import <libkern/OSAtomic.h>

/**
 OSSpinLock叫做”自旋锁”, 等待锁的线程会处于忙等（busy-wait）状态，一直占用着CPU资源,
 所以可能造成优先级反转的问题：
 线程1优先级别高于线程2
 线程2先执行该段被锁修饰的代码，但是没有执行完毕。这时候线程1来执行该段代码，由于线程1级别高，所以CPU的资源会一直分配给线程1，此时线程2又没有解锁，造成死锁
 */

/**
 如果两个操作不能同时进行，两个操作加的锁必须是同一个；
 加锁可以阻止一段代码被再次执行的原理是：在执行该段代码的时候会判断该锁是否已经被锁，如果已经被锁, 那么就要等待，直到该锁被打开以后才能再次执行该段代码
 */

@interface ViewController ()
// 钱数
@property (nonatomic, assign) int money;
// 票数
@property (nonatomic, assign) int ticketsCount;
// 锁1
@property (nonatomic, assign) OSSpinLock lock;
// 锁2
@property (nonatomic, assign) OSSpinLock lock1;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化锁1
    self.lock = OS_SPINLOCK_INIT;
    // 初始化锁2
    self.lock1 = OS_SPINLOCK_INIT;
    
    // 存取钱
//    [self moneyTest];
    // 卖票
    [self ticketTest];
}

/**
 举例1：存取钱演示
 */
- (void)moneyTest {
    // 本来有100万
    self.money = 100;
    // 全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    // 全局队列；不阻塞；新的子线程
    // 存钱
    dispatch_async(queue, ^{
        for (int i = 0; i < 10; i++) {
            [self saveMoney];
        }
    });
    // 全局队列；不阻塞；新的子线程
    // 取钱
    dispatch_async(queue, ^{
        for (int i = 0; i < 10; i++) {
            [self drawMoney];
        }
    });
}

/**
 存钱
 */
- (void)saveMoney {
    // 加锁
    OSSpinLockLock(&_lock);
    
    int oldMoney = self.money;
    sleep(.2);
    oldMoney += 50;
    self.money = oldMoney;
    NSLog(@"存了50元，剩余%d钱, 线程在 %@", _money, [NSThread currentThread]);
    
    // 解锁
    OSSpinLockUnlock(&_lock);
}
/**
 取钱
 */
- (void)drawMoney {
    // 加锁
    OSSpinLockLock(&_lock);
    
    int oldMoney = self.money;
    sleep(.2);
    oldMoney -= 50;
    self.money = oldMoney;
    NSLog(@"取了50元，剩余%d钱, 线程在 %@", _money, [NSThread currentThread]);
    
    // 解锁
    OSSpinLockUnlock(&_lock);
    
}

/**
  举例2：买票演示
 */
- (void)ticketTest {
    // 原来一共有15张票
    self.ticketsCount = 15;
    // 全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    // 全局队列；不阻塞；新的子线程
    // 子线程卖票5张
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self saleTicket];
        }
    });
    // 子线程卖票5张
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self saleTicket];
        }
    });
    // 子线程卖票5张
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self saleTicket];
        }
    });
}

/**
 卖一张票
 */
- (void)saleTicket {
    
//    // 如果这么写，意思是如果没有加锁，那么加锁，执行代码。如果有加锁，则不再执行该段代码，继续向下执行。
//    if (OSSpinLockTry(&_lock)) {
//        int oldTicketsCount = self.ticketsCount;
//           sleep(.2);
//           oldTicketsCount--;
//           self.ticketsCount = oldTicketsCount;
//           NSLog(@"剩余%d张票, 线程在 %@", oldTicketsCount, [NSThread currentThread]);
//
//           // 解锁
//           OSSpinLockUnlock(&_lock);
//    }
    
    // 上锁
    OSSpinLockLock(&_lock);
    
    int oldTicketsCount = self.ticketsCount;
    sleep(.2);
    oldTicketsCount--;
    self.ticketsCount = oldTicketsCount;
    NSLog(@"剩余%d张票, 线程在 %@", oldTicketsCount, [NSThread currentThread]);
    
    // 解锁
    OSSpinLockUnlock(&_lock);
    
}


@end
