//
//  NSMutableArray+Common.m
//  gleadSmart
//
//  Created by 杭州轨物科技有限公司 on 2019/5/25.
//  Copyright © 2019年 杭州轨物科技有限公司. All rights reserved.
//

#import "NSMutableArray+Common.h"
#import "DeviceModel.h"

@implementation NSMutableArray (Common)

- (void)updateOrAddDeviceModel:(DeviceModel *)device{
    BOOL isExist = NO;
    for (DeviceModel *existDevice in self) {
        if ([existDevice.sn isEqualToString:device.sn]) {
            isExist = YES;
        }
    }
    if (!isExist) {
        [self addObject:device];
    }
}

@end
