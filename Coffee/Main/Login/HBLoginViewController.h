//
//  LoginViewController.h
//  Coffee
//
//  Created by 杭州轨物科技有限公司 on 2018/9/20.
//  Copyright © 2018年 杭州轨物科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HBLoginViewController : UIViewController

@property (nonatomic) BOOL isAutoLogin;
@property (nonatomic, strong) NSString *numPassword;
@end

NS_ASSUME_NONNULL_END
