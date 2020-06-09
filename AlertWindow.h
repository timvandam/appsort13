@interface AlertWindow : UIWindow
+(BOOL)alertShowing;
-(void)showAlert;
-(void)createAlert;

@property UIViewController* uv;
@property UIAlertController* alert;
@end