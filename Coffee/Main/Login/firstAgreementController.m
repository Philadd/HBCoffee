//
//  firstAgreementController.m
//  Coffee
//
//  Created by 安建伟 on 2019/9/11.
//  Copyright © 2019 杭州轨物科技有限公司. All rights reserved.
//

#import "firstAgreementController.h"

@interface firstAgreementController ()<UIScrollViewDelegate,UITextViewDelegate>

@property (nonatomic, strong) UIImageView *headerImage;
@property (nonatomic, strong) UIScrollView *firstAgreementScrollView;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation firstAgreementController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.layer.backgroundColor = [UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1].CGColor;
    _firstAgreementScrollView = [self firstAgreementScrollView];
    [self setNavItem];
}

#pragma mark - LazyLoad

- (void)setNavItem{
    self.navigationItem.title = LocalString(@"用户协议和隐私政策");
}

- (UIScrollView *)firstAgreementScrollView{
    if (!_firstAgreementScrollView) {
        // 1.创建UIScrollView
        _firstAgreementScrollView  = [[UIScrollView alloc] init];
        _firstAgreementScrollView.frame = CGRectMake(0, 0, ScreenWidth,ScreenHeight - getRectNavAndStatusHight); // frame中的size指UIScrollView的可视范围
        _firstAgreementScrollView.backgroundColor = [UIColor clearColor];
        _firstAgreementScrollView.delegate = self;
        _firstAgreementScrollView.clipsToBounds = YES;
        _firstAgreementScrollView.canCancelContentTouches = YES;
        _firstAgreementScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        // 设置内容大小
        _firstAgreementScrollView.contentSize = CGSizeMake(ScreenWidth,132/HScale + ScreenHeight);
        // 是否分页
        _firstAgreementScrollView.pagingEnabled = NO;//这里很重要，因为设置为YES会出现滑动不流畅
        // 提示用户,Indicators flash
        [_firstAgreementScrollView flashScrollIndicators];
        
        // 是否同时运动,lock
        _firstAgreementScrollView.directionalLockEnabled = YES;
        _firstAgreementScrollView.bouncesZoom = NO;
        _firstAgreementScrollView.scrollEnabled = YES;
        
        [self.view addSubview:_firstAgreementScrollView];
        
        _headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_logo"]];
        [_firstAgreementScrollView addSubview:_headerImage];
        [_headerImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(140/WScale, 112/HScale));
            make.centerX.equalTo(self.firstAgreementScrollView.mas_centerX);
            make.top.equalTo(self.firstAgreementScrollView.mas_top).offset(20/HScale);
        }];
        
        _textView = [[UITextView alloc] init];
        _textView.frame = CGRectMake(0, 132/HScale, ScreenWidth,ScreenHeight);
        _textView.contentSize = CGSizeMake(ScreenWidth,ScreenHeight);
        _textView.backgroundColor = [UIColor clearColor];
        _textView.text = LocalString(@"在您注册成为爱趣焙用户的过程中，您需要完成我们的注册流程并通过点击同意的形式在线签署以下协议，请您务必仔细阅读、充分理解协议中的条款内容后再点击同意.点击同意即表示您已阅读并同意《爱趣焙用户注册协议及软件许可使用协议》与《隐私政策》。\n\n 用户注册协议及软件许可使用协议\n\n提示条款\n本软件许可使用协议（以下称“本协议”）由您与爱趣咖啡科技（宁波）有限公司（以下称“我们”）共同签署。在使用“爱趣焙”软件（以下称许可软件）之前，请您仔细阅读本协议，特别是免除或者限制责任的条款、法律适用和争议解决条款。免除或者限制责任的条款将以粗体标识，您需要重点阅读。如您对本协议有任何疑问，可向客服咨询。如果您同意接受本协议条款和条件的约束，您可下载安装使用许可软件。由于互联网高速发展，您与我们签署的本协议列明的条款并不能完整罗列并覆盖您与我们所有的权利与义务，现在的约定也不能保证完全符合未来发展的需求。如您使用许可软件，视为您同意上述协议。我们如修改本协议或其补充协议，协议条款修改后，请您仔细阅读并接受修改后的协议后再继续使用许可软件。如果用户不接受修改后的条款请立即停止使用此软件和服务，用户继续使用此软件和服务视为已接受了修改后的协议。\n\n一、定义\n1.1许可软件：是指由我们开发的，供您从下载平台下载，并仅限在相应系统手持移动端中安装、使用的软件系统，本软件及服务的所有权和运营权均归爱趣焙所有。\n1.2服务：本软件为使用该移动智能终端的用户提供绑定、操作智能产品等服务。\n二、软件授权及范围\n2.1爱趣焙就本软件给予用户一项个人的、不可转让、不可转授权以及非独占性的许可。\n2.2用户可以为非商业目的在单一台移动终端设备上安装、使用、显示、运行本软件，使用户不得为商业运营目的安装、使用、运行过程中释放任何到任何终端设备内存中的数据及本软件运行过程中客户端与服务器短的交互数据进行复制、更改、修改、挂接运行或创作任何衍生作品。如果需要进行商业性的销售、复制和散发，例如软件预装和捆绑，必须获得爱趣焙的书面授权和许可。\n三、软件的获取、安装、升级\n3.1用户应当按照爱趣焙的制定网站或指定方式下载安装本软件产品。谨防在非指定网站下载本软件，以免移动终端设备感染能破坏用户数据和获取用户隐私的恶意程序。如果用户从未经爱趣焙授权的第三方获取本软件或与本软件名称相同的安装程序，爱趣焙无法保证该软件能够正常使用，并对因此给您造成的损失不予负责。\n3.2用户必须选择与所安装终端设备相匹配的本软件版本，否则，由于软件与设备型号不相匹配所导致的任何软件问题、设备问题或损害，均由用户自行承担。\n3.3为了改善用户体验、完善服务内容，爱趣焙有权不时地为您提供本软件替换、修改、升级版本，也有权为替换、修改或升级收取费用，但将收费提前得征得您的同意。本软件为用户默认开通“升级提示”功能，视用户使用的软件版本差异，爱趣焙提供给用户自行选择是否需要开通此功能。软件新版本发布后，爱趣焙不保证旧版本软件的继续可用。\n四、使用规范\n4.1用户在遵守法律及本协议的前提下可依本协议使用本软件及服务，用户不得实施如下行为：\n4.1.1 删除本软件及其他副本上一切关于版本的信息，以及修改、删除或避开本软件为保护知识产权而设置的技术措施；\n4.1.2本软件进行反向工程，如反汇编、反编译或者其他试图获得本软件的源代码；\n4.1.3通过修改或伪造软件运行中的指令、数据、增加、删除、变动软件的功能或运行效果，或者将用于上述用途的软件、方法进行运营或向公众传播，无论这些行为是否为商业目的；\n4.1.4使用本软件进行任何危害网络安全的行为，包括但不限于：使用未经许可的数据或进入未经许可的服务器/账户；未经允许进入公众网络或者他人操作系统并删除、修改、增加存储信息；未经许可企图探查、扫描、测试本软件的系统或网络的弱点或其它实施破坏网络安全的行为；企图干涉、破坏本软件系统或网站的正常运行，故意传播恶意程序或病毒以及其他破坏干扰正常网络信息服务的行为；伪造TCP/IP数据包名称或部分名称；\n4.1.5用户通过非爱趣焙公司开发、授权或认可的第三方兼容软件、系统登入或使用本软件及服务，或制作、发布、传播上述工具；\n4.1.6未经爱趣焙书面同意，用户对软件及其中信息擅自实施包括但不限于下列行为：使用、出租、出借、复制、修改、链接、转载、汇编、发表、出版，建立镜像站点、擅自借助本软件发展与之有关的衍生产品、作品、服务、插件、外挂、兼容、互联等；\n4.1.7利用本软件发表、传送、传播、储存侵害他人知识产权、商业秘密等合法权利的内容；\n4.1.8利用本软件批量发表、传送、传播广告信息及垃圾信息；\n4.1.9其他以任何不合法的方式、为任何不合法的目的、或任何与本协议许可使用不一致的方式使用本软件和爱趣焙提供的其他服务。\n4.2信息发布规范\n4.2.1您可使用本软件发表属于您原创或您有权发表的观点看法、数据、文字、信息、用户名、图片、个人信息、音频、视频文件、链接等信息内容。您必须保证，您拥有您所上传信息内容的知识产权或已获得合法授权，您使用本软件及服务的任何行为未侵犯任何第三方之合法权益。\n4.2.2您在使用本软件时需遵守当地法律法规要求。\n4.2.3您在使用本软件时不得利用本软件从事以下行为，包括但不限于：\n4.2.3.1制作、复制、发布、传播、储存违反当地法律法规的内容；\n4.2.3.2发布、传送、传播、储存侵害他人名誉权、肖像权、知识产权、商业秘密等合法权利的内容；\n4.2.3.3虚构事实、隐瞒真相以误导、欺骗他人；\n4.2.3.4发表、传说、传播广告信息及垃圾信息；\n4.2.4未经爱趣焙许可，您不得在本软件中进行任何诸如发布广告、销售商品的商业行为。\n4.3您理解并同意\n4.3.1爱趣焙会对用户是否涉嫌违反上述使用规范做出认定，并根据认定结果中止、终止对您的使用许可或采取其他依本约定可采取的限制措施；\n4.3.2对于用户使用许可软件时发布的涉嫌违法或涉嫌侵犯他人合法权利或违反本协议的信息，爱趣焙会直接删除；\n4.3.3对于用户违反上述使用规范的行为对第三方造成损害的，您需要以自己的名字独立承担法律责任，并应确保爱趣焙免于因此产生损失或增加费用；\n4.3.4若用户违反有关法律规定或协议约定，使爱趣焙遭受损失，或遭到第三方的索赔，或收到行政管理机关的出发，用户应当赔偿爱趣焙因此造成的损失和（或）发生的费用，包括合理的律师费、调查取费用。\n\n五、服务风险及免责声明\n5.1用户必须自行配备移动终端设备上网，自行负担个人移动终端设备上网或第三方收取的通讯费、信息费等有关费用。\n5.2用户因第三方如通讯线路故障、技术问题、网络、移动终端设备故障、系统不稳定性及其他各种不可抗力原因而遭受的一切损失，爱趣焙及合作单位不承担责任。\n5.3本软件同大多数互联网软件一样，受包括但不限于用户原因、网络服务质量、社会环境等因素的差异影响，可能受到各种安全问题的侵扰，如他人利用用户的资料，造成现实生活中的骚扰；用户下载安装的其它软件或访问的其他网站中含有“特洛伊木马 ”等病毒，威胁到用户的终端设备信息和数据安全，继而影响本软件的正常使用等等。用户应加强信息安全及使用者资料的保护意识，要注意加强密码保护，以免遭致损失和骚扰。\n5.4因用户使用本软件或要求爱趣焙体哦概念股特定服务时，本软件可能会调用第三方系统或第三方软件支持用户的使用或访问，使用或访问的结果由该第三方提供给，爱趣焙不保证通过第三方系统或第三方软件支持实现的结果的安全性、准确性、有效性及其他不确定的风险，由此若引发的任何争议及损害，爱趣焙不承担任何责任。\n5.5爱趣焙特别提请用户注意，爱趣焙为了保障公司业务发展和调整的自主权，爱趣焙公司拥有随时修改或中断服务而不需通知用户的权力，爱趣焙行使修改或中断服务的权力不需对用户或任何第三方负责。\n5.6除法律法规有明确规定外，我们将尽量最大努力确保软件及其所涉及的技术及信息安全、有效、准确、可靠，但受限于现有技术，用户理解爱趣焙不能对此进行担保。\n5.7由于用户因下述任一情况所引起或与此有关的人身伤害或附带的、间接的经济损害赔偿，包括但不限于利润损失、资料损失、业务中断的损害赔偿或其他商业损害赔偿或损失，需由用户自行承担：\n5.7.1使用或未能使用许可的软件；\n5.7.2第三方未经许可的使用软件或更改用户的数据；\n5.7.3用户使用软件进行的行为产生的费用及损失；\n5.7.4用户对软件的误解；\n5.7.5因非爱趣焙的原因引起的与软件有关的其他损失\n5.8用户与其他使用软件的用户之间通过软件进行的行为，因您受误导或欺骗而导致或可能导致的任何人身或经济上的伤害或损失，均由过错方依法承担所有责任。\n\n六、知识产权声明\n6.1爱趣焙是本软件的知识产权权利人，本软件 一切著作权、商标权、专利权、商业秘密等知识产权，以及与本软件相关的所有信息内容（包括但不限于文字、图片、音频、视频、图表、界面设计、版面框架、有关数据或电子文档等）均受您所在当地法律法规和相应的国际条约保护，爱趣焙享有上述知识产权。\n6.2未经爱趣焙书面同意，用户不得为任何商业或非商业目的自行或许可任何第三方实施、利用、转让上述知识产权，爱趣焙保留追究上述行为法律责任的权利。");
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
        [self.firstAgreementScrollView addSubview:_textView];
    }
    return _firstAgreementScrollView;
}
//UItextView自适应文本
- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    textView.frame = newFrame;
    _firstAgreementScrollView.contentSize = CGSizeMake(ScreenWidth,132/HScale + newSize.height);
}

@end
