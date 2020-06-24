//
//  secondAgreementController.m
//  Coffee
//
//  Created by 安建伟 on 2019/9/11.
//  Copyright © 2019 杭州轨物科技有限公司. All rights reserved.
//

#import "secondAgreementController.h"

@interface secondAgreementController () <UITextViewDelegate>

@property (nonatomic, strong) UIImageView *headerImage;
@property (nonatomic, strong) UIScrollView *secondAgreementScrollView;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation secondAgreementController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.layer.backgroundColor = [UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1].CGColor;
    _secondAgreementScrollView = [self secondAgreementScrollView];
    [self setNavItem];
}

#pragma mark - LazyLoad

- (void)setNavItem{
    self.navigationItem.title = LocalString(@"用户协议和隐私政策");
}

- (UIScrollView *)secondAgreementScrollView{
    if (!_secondAgreementScrollView) {
        // 1.创建UIScrollView
        _secondAgreementScrollView  = [[UIScrollView alloc] init];
        _secondAgreementScrollView.frame = CGRectMake(0, 0, ScreenWidth,ScreenHeight); // frame中的size指UIScrollView的可视范围
        _secondAgreementScrollView.backgroundColor = [UIColor clearColor];
        _secondAgreementScrollView.delegate = self;
        _secondAgreementScrollView.clipsToBounds = YES;
        _secondAgreementScrollView.canCancelContentTouches = YES;
        _secondAgreementScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        // 设置内容大小
        _secondAgreementScrollView.contentSize = CGSizeMake(ScreenWidth,132/HScale + ScreenHeight + getRectNavAndStatusHight);
        // 是否分页
        _secondAgreementScrollView.pagingEnabled = NO;//这里很重要，因为设置为YES会出现滑动不流畅
        // 提示用户,Indicators flash
        [_secondAgreementScrollView flashScrollIndicators];
        
        // 是否同时运动,lock
        _secondAgreementScrollView.directionalLockEnabled = YES;
        _secondAgreementScrollView.bouncesZoom = NO;
        _secondAgreementScrollView.scrollEnabled = YES;
        
        [self.view addSubview:_secondAgreementScrollView];
        
        _headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_logo"]];
        [_secondAgreementScrollView addSubview:_headerImage];
        [_headerImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(140/WScale, 112/HScale));
            make.centerX.equalTo(self.secondAgreementScrollView.mas_centerX);
            make.top.equalTo(self.secondAgreementScrollView.mas_top).offset(20/HScale);
        }];
        
        _textView = [[UITextView alloc] init];
        _textView.frame = CGRectMake(0, 132/HScale, ScreenWidth,ScreenHeight);
        _textView.contentSize = CGSizeMake(ScreenWidth,ScreenHeight);
        _textView.backgroundColor = [UIColor clearColor];
        _textView.text = LocalString(@"在您注册成为爱趣焙用户的过程中，您需要完成我们的注册流程并通过点击同意的形式在线签署以下协议，请您务必仔细阅读、充分理解协议中的条款内容后再点击同意。点击同意即表示您已阅读并同意《爱趣焙用户注册协议及软件许可使用协议》与《隐私政策》。\n\n隐私政策\n\n我们向您承诺\n本隐私政策规定了爱趣焙及关联公司（下文简称“我们”）如何收集、使用、披露、处理和保护您在使用我们的产品和服务时通过爱趣焙APP提供给我们的信息。若我们要求您提供某些信息，以便在使用爱趣焙产品和服务时验证您的身份，我们将严格遵守本隐私政策和/或我们的用户条款与条件来使用这些信息。\n本隐私政策在制定时充分考虑到您的需求；您全面了解我们的个人资料收集和使用惯例，而且确信自己最终能控制提供给爱趣焙的所有个人信息，这一点至关重要。\n在这项隐私政策中，“个人信息”所指通过有关特定个人的信息，或者与爱趣焙能够访问的其他关于该人的信息相结合后，能够直接或间接识别该人的所有数据。此类个人信息包括但不限于您提供或上传的信息和设备信息。\n通过使用爱趣焙产品和服务或其他符合使用法律的操作，即表示您已阅读并接受本隐私和政策中所述之所有条款，包括我们定期做出的任何更改。未遵守使用法律，包括本地数据保护法律，我们将会对于特定类别的个人数据的处理征求您的明确同意。另外，我们承诺遵照适用法律（包括您所在地的数据保护法律）来保护您的个人信息的隐私、机密和安全。同时我们承诺确保我们的全体员工和代理商履行这些义务。最后，我们所希望的就是为我们的用户带来最好的体验。");
        _textView.textAlignment = NSTextAlignmentLeft;
        _textView.textColor = [UIColor blackColor];
        _textView.font = [UIFont boldSystemFontOfSize:14];
        _textView.dataDetectorTypes = UIDataDetectorTypeAll;
        // 禁止编辑.设置为只读，不再能输入内容
        _textView.editable = NO;
        //禁止选择.禁止选中文本，此时文本也禁止编辑
        _textView.selectable = NO;
        _textView.scrollEnabled = NO;
        // 设置可以对选中的文字加粗。选中文字时可以对选中的文字加粗
        _textView.allowsEditingTextAttributes = YES;
        _textView.delegate = self;
        _textView.adjustsFontForContentSizeCategory = YES;
        //文字滑动到底部
        CGPoint offset = _textView.contentOffset;
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
            [self.textView setContentOffset: offset];
        }];
        [self textViewDidChange:_textView];
        [self.secondAgreementScrollView addSubview:_textView];
    }
    return _secondAgreementScrollView;
}

- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    textView.frame = newFrame;
    _secondAgreementScrollView.contentSize = CGSizeMake(ScreenWidth,200/HScale + newSize.height);
}

@end
