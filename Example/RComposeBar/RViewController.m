/**
 RViewController.m
 The MIT License (MIT)
 Created by Rajeev Prasad on 11/6/16.
 Copyright © 2016 Rajeev Prasad <rjeprasad@gmail.com>. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */


#import "RViewController.h"
#import <RComposeBar/RComposeBar.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreLocation/CoreLocation.h>

@interface ChatCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel *lblMessage;
@property (nonatomic, strong) IBOutlet UIImageView *imbView;
@property (nonatomic, assign) BOOL myBubble;
@end
@implementation ChatCell
-(void)setMyBubble:(BOOL)myBubble {
    _myBubble = myBubble;
    UIImage *img = nil;
    if (myBubble) {
        img = [UIImage imageNamed:@"bubble_right"];
    } else {
        img = [UIImage imageNamed:@"bubble_left"];
    }
    _imbView.image = [img resizableImageWithCapInsets:UIEdgeInsetsMake(15, 30, 15, 30) resizingMode:UIImageResizingModeStretch];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}
@end

@interface RViewController () <RComposeBarDelegate, RComposeBarDataSource, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate>
#pragma mark properties needed for compose bar
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *toolbarHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottom;
@property (strong, nonatomic) RComposeBar *composeBar;
@property (strong, nonatomic) NSMutableArray *composeBarItems;
#pragma mark other properties
@property (strong, nonatomic) IBOutlet UITableView *table;
@property (strong, nonatomic) NSMutableArray *chatList;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLGeocoder *geocorder;
@property (strong, nonatomic) NSString *currentLocation;
@end

static NSString *kText = @"text";
static NSString *kMine = @"mine";

@implementation RViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _composeBarItems = [[NSMutableArray alloc] init];
    [self setupComposeBar];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameDidChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    _chatList = [[NSMutableArray alloc] init];
    [self setInitialChats];
}

-(void)setInitialChats {
    [_chatList addObject:@{kText : @"Hello", kMine : @(0)}];
    [_chatList addObject:@{kText : @"Hi, how are you?", kMine : @(1)}];
    [_chatList addObject:@{kText : @"Zup", kMine : @(1)}];
    [_chatList addObject:@{kText : @"Im fine, Hw r u? :)", kMine : @(0)}];
    [_chatList addObject:@{kText : @"I am playing pokemon go, its fantastic. you should try it too. may be we can get to gether sometime and play :P ", kMine : @(0)}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark setup compose bar
-(void)setupComposeBar {
    if (!_composeBar) {
        _composeBar = [[RComposeBar alloc] initWithContainer:_toolbar delegate:self];
        _composeBar.delegate = self;
        _composeBar.dataSource = self;
        // _composeBar.sendTitle = @"Post";
        _composeBar.leftButtonImage = [UIImage imageNamed:@"more"];
        [_composeBar setRightButtonWithTag:1 image:[UIImage imageNamed:@"mic"] backToKBImage:[UIImage imageNamed:@"kb"]];
        // [_composeBar setRightButtonWithTag:AUDIO_RECORDER text:@"Mic" backToKBYText:@"KB"];
        _composeBar.maxHeight = 200;
        _composeBar.placeholder = @"whats on your mind";
    } else {
        // _composeBar may have some text typed earlier
        _toolbarHeight.constant = [_composeBar getCurrentHeight];
    }
}

#pragma mark RComposeBarDelegate - required
-(void)composeBarSendDidTapped:(NSString *)text {
    [_chatList addObject:@{kText : text, kMine : @(1)}];
    [_table reloadData];
}

-(void)composeBarHeightDidChange:(CGFloat)height {
    _toolbarHeight.constant = height;
}

#pragma mark RComposeBarDelegate - optional
-(void)composeBarLeftButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openPicker:UIImagePickerControllerSourceTypeCamera];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openPicker:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Current Location" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setCurrentLocation];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)composeBarRightButtomTapped:(NSInteger)tag {
    if (tag == 1) {
        [_composeBar resignFirstResponder];
    }
}

-(void)composeBarDidClear {
    [_composeBarItems removeAllObjects];
    _currentLocation = nil;
}

-(void)composeBarLocationSelected {
    [self showMessage:[NSString stringWithFormat:@"Locarion selected - %@\nOpen in map view", _currentLocation]];
}

-(void)composeBarTextDidChanged:(NSString *)text {
    
}

-(void)deleteComposeBarItemAtIndex:(NSInteger)index {
    [_composeBarItems removeObjectAtIndex:index];
}

- (void) selecteComposeBarItemAtIndex:(NSInteger)index {
    id item = _composeBarItems[index];
    if ([item isKindOfClass:[UIImage class]]) {
        [self showMessage:@"Image selected - sholud open"];
    } else if ([item isKindOfClass:[NSURL class]]) {
        NSURL *url = (NSURL *)item;
        if ([[url pathExtension] isEqualToString:@"mp4"]) {
            [self showMessage:@"Video selected - sholud start playing"];
        } else if ([[url pathExtension] isEqualToString:@"m4a"]) {
            [self showMessage:@"Audio selected - shold start playing"];
        }
    }
}

-(void)deleteComposeBarLocation {
    _currentLocation = nil;
}

#pragma mark RComposeBarDataSource - optional
- (NSInteger)numberOfItemsInComposeBar {
    return _composeBarItems.count;
}

- (UIImage *)imageForComposeBarItemAtIndex:(NSInteger)index {
    id item = _composeBarItems[index];
    if ([item isKindOfClass:[UIImage class]]) {
        return (UIImage*)item;
    } else if ([item isKindOfClass:[NSURL class]]) {
        NSURL *url = (NSURL *)item;
        if ([[url pathExtension] isEqualToString:@"mp4"]) {
            return [self getVideoThumbnail:url];
        } else if ([[url pathExtension] isEqualToString:@"m4a"]) {
            return [UIImage imageNamed:@"audio_item"];
        }
    }
    return [UIImage imageNamed:@"empty_item"];
}

-(NSString *)locationInComposeBar {
    return _currentLocation;
}

#pragma mark general
-(void)setCurrentLocation {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        [_locationManager requestWhenInUseAuthorization];
    }
    if (!_geocorder){
        _geocorder = [[CLGeocoder alloc] init];
    }
    [_locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (locations.count > 0) {
        CLLocation *loc = locations.firstObject;
        if (loc != nil) {
            [_geocorder reverseGeocodeLocation:loc completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                for(CLPlacemark *place in placemarks) {
                    if (place.addressDictionary[@"FormattedAddressLines"]) {
                        NSArray *array = place.addressDictionary[@"FormattedAddressLines"];
                        NSMutableString *mString = [NSMutableString string];
                        for (NSString *line in array) {
                            [mString appendString:line];
                            [mString appendString:@" "];
                        }
                        self.currentLocation = mString;
                        [_composeBar reloadComposeBar];
                        break;
                    }
                }
            }];
        }
        [_locationManager stopUpdatingLocation];
    }
}

-(void)openPicker:(UIImagePickerControllerSourceType)source {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
    imagePickerController.sourceType = source;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:NO completion:nil];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [_composeBarItems addObject:image];
        [_composeBar reloadComposeBar];
        
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        if (!videoURL) videoURL =  (NSURL *)info[UIImagePickerControllerReferenceURL];
        
        NSString *tempPath = NSTemporaryDirectory();
        NSString *videoOutputPath = [tempPath stringByAppendingPathComponent:@"video.mov"];
        
        // File conversion
        AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
        if (!avAsset) avAsset = [AVURLAsset assetWithURL:videoURL];
        
        NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
        
        if ([compatiblePresets containsObject:AVAssetExportPreset1920x1080]) {
            AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetPassthrough];
            exportSession.outputURL = [NSURL URLWithString:videoOutputPath];
            exportSession.outputFileType = AVFileTypeMPEG4;
            
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                switch ([exportSession status]) {
                        
                    case AVAssetExportSessionStatusFailed:
                        NSLog(@"Export failed: %@", [exportSession error]);
                        [_composeBarItems addObject:videoURL];
                        [_composeBar reloadComposeBar];
                        break;
                        
                    case AVAssetExportSessionStatusCancelled:
                        NSLog(@"Export cancelled.");
                        break;
                        
                    case AVAssetExportSessionStatusCompleted:
                        [_composeBarItems addObject:videoOutputPath];
                        [_composeBar reloadComposeBar];
                        break;
                    default:
                        break;
                }
            }];
        }
        
    }
}

-(UIImage *)getVideoThumbnail:(NSURL *)url {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    NSError *error = NULL;
    CMTime time = CMTimeMake(1, 1);
    CGImageRef refImg = [generateImg copyCGImageAtTime:time actualTime:NULL error:&error];
    UIImage *frameImage= [[UIImage alloc] initWithCGImage:refImg];
    if (frameImage) {
        return frameImage;
    } else {
        return [UIImage imageNamed:@"empty_video_image"];
    }
}

#pragma mark keyboard notification
- (void)keyboardFrameDidChange:(NSNotification *)notification {
    CGRect keyboardEndFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardBeginFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] integerValue];
    UIViewAnimationCurve animationCurve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect keyboardFrameEnd = [self.view convertRect:keyboardEndFrame toView:nil];
    CGRect keyboardFrameBegin = [self.view convertRect:keyboardBeginFrame toView:nil];
    
    CGFloat heightChange =(keyboardFrameBegin.origin.y - keyboardFrameEnd.origin.y);
    CGFloat height = keyboardBeginFrame.size.height;
    
    if (ABS(heightChange) > 1) {
        CGFloat kbheight = height;
        if (height != heightChange) {
            kbheight = height + heightChange;
        }
        [self animateKeyboard:kbheight duration:animationDuration curve:animationCurve];
    }
}

-(void) animateKeyboard:(CGFloat)height duration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    _toolbarBottom.constant = height;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
    
    [UIView commitAnimations];
}

#pragma mark UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _chatList.count;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *chat = _chatList[indexPath.row];
    ChatCell *cell = nil;
    if ([chat[kMine] boolValue]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell" forIndexPath:indexPath];
        cell.myBubble= YES;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"OtherCell" forIndexPath:indexPath];
        cell.myBubble= NO;
    }
    cell.lblMessage.text = chat[kText];
    return cell;
}

#pragma mark support metods
-(void)showMessage:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
