//
//  PhoneVerifyCell.m
//  Coffee
//
//  Created by 杭州轨物科技有限公司 on 2018/9/19.
//  Copyright © 2018年 杭州轨物科技有限公司. All rights reserved.
//

#import "PhoneVerifyCell.h"

@implementation PhoneVerifyCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self) {
        if (!_codeTF) {
            _codeTF = [[UITextField alloc] init];
            _codeTF.backgroundColor = [UIColor clearColor];
            _codeTF.placeholder = LocalString(@"请输入验证码");
            _codeTF.font = [UIFont fontWithName:@"Arial" size:16.0f];
            _codeTF.textColor = [UIColor colorWithHexString:@"222222"];
            //_codeTF.borderStyle = UITextBorderStyleRoundedRect;
            _codeTF.keyboardType = UIKeyboardTypeNumberPad;
            _codeTF.clearButtonMode = UITextFieldViewModeWhileEditing;
            _codeTF.autocorrectionType = UITextAutocorrectionTypeNo;
            _codeTF.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            //设置为YES时文本会自动缩小以适应文本窗口大小.默认是保持原来大小,而让长文本滚动
            _codeTF.adjustsFontSizeToFitWidth = YES;
            //设置自动缩小显示的最小字体大小
            _codeTF.minimumFontSize = 11.f;
            [_codeTF addTarget:self action:@selector(textFieldTextChange:) forControlEvents:UIControlEventEditingChanged];
            [self.contentView addSubview:_codeTF];
            
            [_codeTF mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(200/WScale, 30/HScale));
                make.centerY.equalTo(self.contentView.mas_centerY);
                make.left.equalTo(self.contentView.mas_left).offset(18/WScale);
            }];
        }
        if (!_verifyBtn) {
            _verifyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [_verifyBtn setTitle:LocalString(@"获取验证码") forState:UIControlStateNormal];
            [_verifyBtn.titleLabel setFont:[UIFont systemFontOfSize:13.f]];
            [_verifyBtn setTitleColor:[UIColor colorWithHexString:@"4778CC"] forState:UIControlStateNormal];
            [_verifyBtn addTarget:self action:@selector(getVerifyCode) forControlEvents:UIControlEventTouchUpInside];
            _verifyBtn.layer.borderWidth = 0.5;
            _verifyBtn.layer.borderColor = [UIColor colorWithHexString:@"4778CC"].CGColor;
            _verifyBtn.layer.cornerRadius = 14.f;
            [self.contentView addSubview:_verifyBtn];
            
            [_verifyBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(90/WScale, 28/HScale));
                make.right.equalTo(self.contentView.mas_right).offset(-15/WScale);
                make.centerY.equalTo(self.contentView.mas_centerY);
            }];
        }
    }
    return self;
}

-(void)textFieldTextChange:(UITextField *)textField{
    if (self.TFBlock) {
        self.TFBlock(textField.text);
    }
}

- (void)getVerifyCode{
    if (self.BtnBlock) {
        BOOL result = self.BtnBlock();
        if (result) {
            [self openCountdown];
        }
    }
}

//开始倒计时
-(void)openCountdown{
    
    __block NSInteger time = 59; //倒计时时间
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
    
    dispatch_source_set_event_handler(_timer, ^{
        
        if(time <= 0){ //倒计时结束，关闭
            
            dispatch_source_cancel(_timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //设置按钮的样式
                [self.verifyBtn setTitle:@"重新发送" forState:UIControlStateNormal];
                [_verifyBtn sizeToFit];
                //[self.verifyBtn setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
                //[_verifyBtn setButtonStyleWithColor:[UIColor blackColor] Width:1.f cornerRadius:5.f];
                self.verifyBtn.userInteractionEnabled = YES;
            });
            
        }else{
            
            int seconds = time % 60;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //设置按钮显示读秒效果
                [self.verifyBtn setTitle:[NSString stringWithFormat:@"%2ds", seconds] forState:UIControlStateNormal];
                [_verifyBtn sizeToFit];
                //[self.verifyBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                //[_verifyBtn setButtonStyleWithColor:[UIColor lightGrayColor] Width:1.f cornerRadius:5.f];
                self.verifyBtn.userInteractionEnabled = NO;
            });
            time--;
        }
    });
    dispatch_resume(_timer);
}

@end
