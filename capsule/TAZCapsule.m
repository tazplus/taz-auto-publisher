// TAZ Capsule — overlay ترويجي يُحقن بأي تطبيق (بدون Substrate/hooks → لا كراش)
// بوابة أول تشغيل (cold launch) + أيقونة عائمة قابلة للسحب + نافذة مصغّرة.
#import <UIKit/UIKit.h>
#import "logo_b64.h"

#pragma mark - إعدادات وألوان
#define CH_URL    @"https://t.me/taz_plus"
#define SITE_URL  @"https://tazplus-sa.com"
#define K_SEEN    @"taz_gate_seen_v1"

static UIColor* C(int r,int g,int b,CGFloat a){ return [UIColor colorWithRed:r/255. green:g/255. blue:b/255. alpha:a]; }
#define C_DEEP    C(7,10,20,1)
#define C_NAVY    C(16,26,52,1)
#define C_ORANGE  C(255,106,18,1)
#define C_ORANGE2 C(233,89,0,1)
#define C_AMBER   C(202,160,121,1)
#define C_FG      C(237,241,252,1)
#define C_MUTED   C(150,160,196,1)

static BOOL gPending = NO;

#pragma mark - خلفية الشبكة النيون
@interface TAZGrid : UIView @end
@implementation TAZGrid
- (instancetype)initWithFrame:(CGRect)f{ if((self=[super initWithFrame:f])){ self.opaque=NO; self.backgroundColor=UIColor.clearColor; } return self; }
- (void)drawRect:(CGRect)rect{
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
  // تدرّج قطري (كحلي أعلى → أسود عميق)
  NSArray *cols = @[(id)C_NAVY.CGColor,(id)C_DEEP.CGColor];
  CGFloat locs[] = {0,1};
  CGGradientRef gr = CGGradientCreateWithColors(cs,(__bridge CFArrayRef)cols,locs);
  CGPoint c = CGPointMake(rect.size.width/2, rect.size.height*0.30);
  CGContextDrawRadialGradient(ctx,gr,c,0,c,rect.size.height*0.95,kCGGradientDrawsAfterEndLocation);
  CGGradientRelease(gr); CGColorSpaceRelease(cs);
  // شبكة خطوط خفيفة برتقالية
  CGContextSetLineWidth(ctx,1);
  CGContextSetStrokeColorWithColor(ctx, C(255,120,40,0.09).CGColor);
  CGFloat step=26;
  for(CGFloat x=0;x<=rect.size.width;x+=step){ CGContextMoveToPoint(ctx,x,0); CGContextAddLineToPoint(ctx,x,rect.size.height); }
  for(CGFloat y=0;y<=rect.size.height;y+=step){ CGContextMoveToPoint(ctx,0,y); CGContextAddLineToPoint(ctx,rect.size.width,y); }
  CGContextStrokePath(ctx);
}
@end

#pragma mark - الكبسولة
@interface TAZCapsule : NSObject
+ (instancetype)shared;
- (void)trigger;
@end

@implementation TAZCapsule {
  UIWindow *_gateWin, *_floatWin, *_popWin;
  UIButton *_confirmBtn;
  BOOL _joined;
}
+ (instancetype)shared { static TAZCapsule *s; static dispatch_once_t t; dispatch_once(&t,^{ s=[TAZCapsule new]; }); return s; }

// إقلاع آمن: +load بعد تجهيز الأطر، بلا وصول UIKit مبكر، مع حماية كاملة
+ (void)load{
  @autoreleasepool{
    gPending=YES;
    [[NSNotificationCenter defaultCenter] addObserverForName:@"UIApplicationDidBecomeActiveNotification"
      object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n){
        if(gPending){ gPending=NO;
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.7*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
            @try{ [[TAZCapsule shared] trigger]; }@catch(__unused NSException *e){}
          });
        }
      }];
  }
}

- (UIWindowScene*)scene{
  UIApplication *app = UIApplication.sharedApplication;
  for (UIScene *s in app.connectedScenes)
    if ([s isKindOfClass:UIWindowScene.class] && s.activationState==UISceneActivationStateForegroundActive) return (UIWindowScene*)s;
  for (UIScene *s in app.connectedScenes)
    if ([s isKindOfClass:UIWindowScene.class]) return (UIWindowScene*)s;
  return nil;
}
- (UIImage*)logo{
  NSData *d=[[NSData alloc] initWithBase64EncodedString:@TAZ_LOGO_B64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
  UIImage *i=[UIImage imageWithData:d scale:3.0];
  return i;
}
- (void)open:(NSString*)u{
  NSURL *url=[NSURL URLWithString:u]; if(!url) return;
  [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}

#pragma mark بناء زر
- (UIButton*)btn:(NSString*)title kind:(int)kind{ // 0 primary, 1 ghost, 2 confirm
  UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
  [b setTitle:title forState:UIControlStateNormal];
  b.titleLabel.font=[UIFont systemFontOfSize:15 weight:UIFontWeightBold];
  b.layer.cornerRadius=15; b.clipsToBounds=YES;
  b.translatesAutoresizingMaskIntoConstraints=NO;
  [b.heightAnchor constraintEqualToConstant:50].active=YES;
  if(kind==0){
    b.backgroundColor=C_ORANGE; [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.layer.shadowColor=C_ORANGE.CGColor; b.layer.shadowOpacity=0.5; b.layer.shadowRadius=14; b.layer.shadowOffset=CGSizeMake(0,8); b.clipsToBounds=NO;
  } else if(kind==1){
    b.backgroundColor=C(255,255,255,0.05); [b setTitleColor:C_FG forState:UIControlStateNormal];
    b.layer.borderWidth=1; b.layer.borderColor=C(255,255,255,0.12).CGColor;
  } else {
    b.backgroundColor=C(14,26,18,1); [b setTitleColor:C(127,230,166,1) forState:UIControlStateNormal];
    b.layer.borderWidth=1; b.layer.borderColor=C(47,174,106,0.35).CGColor;
    [b setTitleColor:C(127,230,166,0.4) forState:UIControlStateDisabled];
  }
  return b;
}
- (UILabel*)label:(NSString*)t size:(CGFloat)s weight:(UIFontWeight)w color:(UIColor*)col{
  UILabel *l=[UILabel new]; l.text=t; l.textColor=col; l.font=[UIFont systemFontOfSize:s weight:w];
  l.numberOfLines=0; l.textAlignment=NSTextAlignmentCenter; l.translatesAutoresizingMaskIntoConstraints=NO;
  return l;
}

#pragma mark البوابة
- (void)trigger{ // تُنادى عند cold launch (أول ظهور)
  if(_gateWin||_popWin) return;
  UIWindowScene *sc=[self scene]; if(!sc){ return; }
  BOOL first = ![NSUserDefaults.standardUserDefaults boolForKey:K_SEEN];
  _joined=NO;

  _gateWin=[[UIWindow alloc] initWithWindowScene:sc];
  _gateWin.windowLevel=UIWindowLevelAlert+1000;
  UIViewController *vc=[UIViewController new];
  UIView *root=vc.view; root.backgroundColor=UIColor.clearColor;

  TAZGrid *bg=[[TAZGrid alloc] initWithFrame:root.bounds];
  bg.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  [root addSubview:bg];
  // خط نيون علوي
  UIView *neon=[UIView new]; neon.backgroundColor=C_ORANGE; neon.translatesAutoresizingMaskIntoConstraints=NO;
  neon.layer.shadowColor=C_ORANGE.CGColor; neon.layer.shadowOpacity=0.9; neon.layer.shadowRadius=8; neon.layer.shadowOffset=CGSizeZero;
  [root addSubview:neon];

  UIImageView *iv=[[UIImageView alloc] initWithImage:[self logo]];
  iv.contentMode=UIViewContentModeScaleAspectFit; iv.translatesAutoresizingMaskIntoConstraints=NO;
  [iv.heightAnchor constraintEqualToConstant:64].active=YES;

  UILabel *title=[self label:@"مطوّر بواسطة TAZ PLUS" size:18 weight:UIFontWeightHeavy color:C_FG];
  UILabel *promo=[self label:@"تابع قناتنا واستمتع بآلاف التطبيقات المعدّلة والحصرية." size:14 weight:UIFontWeightRegular color:C(185,194,216,1)];
  UILabel *gate=[self label:@"— تابع القناة لمواصلة استخدام التطبيق —" size:11 weight:UIFontWeightSemibold color:C_AMBER];

  UIButton *ch=[self btn:@"قناة التليجرام" kind:0]; [ch addTarget:self action:@selector(joinTap) forControlEvents:UIControlEventTouchUpInside];
  UIButton *site=[self btn:@"الموقع الرسمي" kind:1]; [site addTarget:self action:@selector(siteTap) forControlEvents:UIControlEventTouchUpInside];
  _confirmBtn=[self btn:@"لقد انضممت للقناة" kind:2]; _confirmBtn.enabled=NO;
  [_confirmBtn addTarget:self action:@selector(confirmTap) forControlEvents:UIControlEventTouchUpInside];

  UILabel *rights=[self label:@"جميع الحقوق محفوظة © TAZ PLUS" size:10 weight:UIFontWeightRegular color:C(92,106,138,1)];

  UIStackView *st=[[UIStackView alloc] initWithArrangedSubviews:@[iv,title,promo,gate,ch,site,_confirmBtn,rights]];
  st.axis=UILayoutConstraintAxisVertical; st.alignment=UIStackViewAlignmentFill; st.spacing=11;
  st.translatesAutoresizingMaskIntoConstraints=NO;
  [st setCustomSpacing:16 afterView:iv];
  [st setCustomSpacing:15 afterView:gate];
  [st setCustomSpacing:18 afterView:_confirmBtn];
  [root addSubview:st];

  [NSLayoutConstraint activateConstraints:@[
    [st.centerYAnchor constraintEqualToAnchor:root.centerYAnchor],
    [st.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:26],
    [st.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-26],
    [neon.topAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.topAnchor constant:6],
    [neon.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
    [neon.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
    [neon.heightAnchor constraintEqualToConstant:1.5],
  ]];

  if(!first){ // ✕ صغير يمين (يظهر بعد أول مرة)
    UIButton *x=[UIButton buttonWithType:UIButtonTypeSystem];
    [x setTitle:@"✕" forState:UIControlStateNormal]; [x setTitleColor:C_MUTED forState:UIControlStateNormal];
    x.titleLabel.font=[UIFont systemFontOfSize:15]; x.translatesAutoresizingMaskIntoConstraints=NO;
    x.backgroundColor=C(255,255,255,0.06); x.layer.cornerRadius=15; x.layer.borderWidth=1; x.layer.borderColor=C(255,255,255,0.14).CGColor;
    [x addTarget:self action:@selector(closeGate) forControlEvents:UIControlEventTouchUpInside];
    [root addSubview:x];
    [NSLayoutConstraint activateConstraints:@[
      [x.topAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.topAnchor constant:14],
      [x.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-16],
      [x.widthAnchor constraintEqualToConstant:30],[x.heightAnchor constraintEqualToConstant:30],
    ]];
  }

  _gateWin.rootViewController=vc; _gateWin.hidden=NO;
  root.alpha=0; [UIView animateWithDuration:0.4 animations:^{ root.alpha=1; }];
}
- (void)joinTap{ [self open:CH_URL]; _joined=YES; _confirmBtn.enabled=YES;
  [UIView animateWithDuration:0.2 animations:^{ self->_confirmBtn.backgroundColor=C(18,36,26,1); }]; }
- (void)siteTap{ [self open:SITE_URL]; }
- (void)confirmTap{ if(_joined){ [self dismissGate]; } }
- (void)closeGate{ [self dismissGate]; }
- (void)dismissGate{
  [NSUserDefaults.standardUserDefaults setBool:YES forKey:K_SEEN];
  UIWindow *w=_gateWin; _gateWin=nil;
  [UIView animateWithDuration:0.32 animations:^{ w.rootViewController.view.alpha=0; } completion:^(BOOL f){ w.hidden=YES; }];
  [self showFloat];
}

#pragma mark الأيقونة العائمة
- (void)showFloat{
  if(_floatWin){ _floatWin.hidden=NO; return; }
  UIWindowScene *sc=[self scene]; if(!sc) return;
  CGFloat sz=56; CGRect b=UIScreen.mainScreen.bounds;
  _floatWin=[[UIWindow alloc] initWithWindowScene:sc];
  _floatWin.windowLevel=UIWindowLevelAlert+900;
  _floatWin.frame=CGRectMake(16, b.size.height-170, sz, sz);
  UIViewController *vc=[UIViewController new]; vc.view.backgroundColor=UIColor.clearColor;
  UIView *dot=[[UIView alloc] initWithFrame:CGRectMake(0,0,sz,sz)];
  dot.backgroundColor=C(10,16,32,1); dot.layer.cornerRadius=sz/2;
  dot.layer.borderWidth=2; dot.layer.borderColor=C(255,255,255,0.10).CGColor;
  dot.layer.shadowColor=C_ORANGE.CGColor; dot.layer.shadowOpacity=0.5; dot.layer.shadowRadius=12; dot.layer.shadowOffset=CGSizeMake(0,6);
  UIImageView *iv=[[UIImageView alloc] initWithImage:[self logo]];
  iv.contentMode=UIViewContentModeScaleAspectFit; iv.frame=CGRectMake(9,sz/2-9,sz-18,18);
  [dot addSubview:iv]; [vc.view addSubview:dot];
  UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
  UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(floatTap)];
  [dot addGestureRecognizer:pan]; [dot addGestureRecognizer:tap];
  _floatWin.rootViewController=vc; _floatWin.hidden=NO;
  _floatWin.transform=CGAffineTransformMakeScale(0.4,0.4); _floatWin.alpha=0;
  [UIView animateWithDuration:0.35 animations:^{ self->_floatWin.transform=CGAffineTransformIdentity; self->_floatWin.alpha=1; }];
}
- (void)pan:(UIPanGestureRecognizer*)g{
  CGPoint t=[g translationInView:nil];
  CGRect f=_floatWin.frame; CGRect b=UIScreen.mainScreen.bounds;
  CGFloat nx=f.origin.x+t.x, ny=f.origin.y+t.y;
  nx=MAX(6,MIN(b.size.width-f.size.width-6,nx));
  ny=MAX(50,MIN(b.size.height-f.size.height-40,ny));
  _floatWin.frame=CGRectMake(nx,ny,f.size.width,f.size.height);
  [g setTranslation:CGPointZero inView:nil];
}
- (void)floatTap{ [self showPopup]; }

#pragma mark النافذة المصغّرة
- (void)showPopup{
  if(_popWin) return;
  UIWindowScene *sc=[self scene]; if(!sc) return;
  _floatWin.hidden=YES;
  _popWin=[[UIWindow alloc] initWithWindowScene:sc];
  _popWin.windowLevel=UIWindowLevelAlert+1100;
  UIViewController *vc=[UIViewController new]; UIView *root=vc.view;
  root.backgroundColor=C(4,6,12,0.62);
  UITapGestureRecognizer *bgtap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePopup)];
  [root addGestureRecognizer:bgtap];

  UIView *card=[UIView new]; card.translatesAutoresizingMaskIntoConstraints=NO;
  card.backgroundColor=C(15,23,48,1); card.layer.cornerRadius=22; card.clipsToBounds=YES;
  card.layer.borderWidth=1; card.layer.borderColor=C(255,255,255,0.12).CGColor;
  [root addSubview:card];
  TAZGrid *bg=[TAZGrid new]; bg.translatesAutoresizingMaskIntoConstraints=NO; [card addSubview:bg];

  UIImageView *iv=[[UIImageView alloc] initWithImage:[self logo]];
  iv.contentMode=UIViewContentModeScaleAspectFit; iv.translatesAutoresizingMaskIntoConstraints=NO;
  [iv.heightAnchor constraintEqualToConstant:52].active=YES;
  UILabel *title=[self label:@"مطوّر بواسطة TAZ PLUS" size:15 weight:UIFontWeightHeavy color:C_FG];
  UILabel *promo=[self label:@"تابع قناتنا واستمتع بآلاف التطبيقات المعدّلة والحصرية." size:12 weight:UIFontWeightRegular color:C(185,194,216,1)];
  UILabel *gate=[self label:@"— تابع القناة لمواصلة استخدام التطبيق —" size:10 weight:UIFontWeightSemibold color:C_AMBER];
  UIButton *ch=[self btn:@"قناة التليجرام" kind:0]; [ch addTarget:self action:@selector(joinTap) forControlEvents:UIControlEventTouchUpInside];
  UIButton *site=[self btn:@"الموقع الرسمي" kind:1]; [site addTarget:self action:@selector(siteTap) forControlEvents:UIControlEventTouchUpInside];
  UILabel *rights=[self label:@"جميع الحقوق محفوظة © TAZ PLUS" size:9 weight:UIFontWeightRegular color:C(92,106,138,1)];

  UIStackView *st=[[UIStackView alloc] initWithArrangedSubviews:@[iv,title,promo,gate,ch,site,rights]];
  st.axis=UILayoutConstraintAxisVertical; st.alignment=UIStackViewAlignmentFill; st.spacing=10;
  st.translatesAutoresizingMaskIntoConstraints=NO;
  [st setCustomSpacing:14 afterView:gate];
  [card addSubview:st];

  UIButton *x=[UIButton buttonWithType:UIButtonTypeSystem];
  [x setTitle:@"✕" forState:UIControlStateNormal]; [x setTitleColor:C_MUTED forState:UIControlStateNormal];
  x.titleLabel.font=[UIFont systemFontOfSize:14]; x.translatesAutoresizingMaskIntoConstraints=NO;
  x.backgroundColor=C(255,255,255,0.06); x.layer.cornerRadius=13;
  [x addTarget:self action:@selector(closePopup) forControlEvents:UIControlEventTouchUpInside];
  [card addSubview:x];

  [NSLayoutConstraint activateConstraints:@[
    [card.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],
    [card.centerYAnchor constraintEqualToAnchor:root.centerYAnchor],
    [card.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:26],
    [card.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-26],
    [bg.topAnchor constraintEqualToAnchor:card.topAnchor],[bg.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
    [bg.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],[bg.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
    [st.topAnchor constraintEqualToAnchor:card.topAnchor constant:18],
    [st.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
    [st.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
    [st.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
    [x.topAnchor constraintEqualToAnchor:card.topAnchor constant:10],[x.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:12],
    [x.widthAnchor constraintEqualToConstant:26],[x.heightAnchor constraintEqualToConstant:26],
  ]];
  _popWin.rootViewController=vc; _popWin.hidden=NO;
  card.transform=CGAffineTransformMakeScale(0.94,0.94); root.alpha=0;
  [UIView animateWithDuration:0.32 animations:^{ root.alpha=1; card.transform=CGAffineTransformIdentity; }];
}
- (void)closePopup{
  UIWindow *w=_popWin; _popWin=nil;
  [UIView animateWithDuration:0.28 animations:^{ w.rootViewController.view.alpha=0; } completion:^(BOOL f){ w.hidden=YES; }];
  [self showFloat];
}
@end

// (الإقلاع صار عبر +load أعلاه — بدون constructor مبكر يسبّب الكراش)
