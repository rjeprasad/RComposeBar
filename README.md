# RComposeBar

[![CI Status](http://img.shields.io/travis/Rajeev%20Prasad/RComposeBar.svg?style=flat)](https://travis-ci.org/Rajeev Prasad/RComposeBar)
[![Version](https://img.shields.io/cocoapods/v/RComposeBar.svg?style=flat)](http://cocoapods.org/pods/RComposeBar)
[![License](https://img.shields.io/cocoapods/l/RComposeBar.svg?style=flat)](http://cocoapods.org/pods/RComposeBar)
[![Platform](https://img.shields.io/cocoapods/p/RComposeBar.svg?style=flat)](http://cocoapods.org/pods/RComposeBar)

## RComposeBar
`RComposeBar` is a userfriendly chat message compose bar to compose any type of messages. `RComposeBar` provides more flexibilty to user to use the compose bar with any information/data wanted in composing.


## Requirements
- Xcode 7.3 or higher
- iOS 8.0 or higher
- ARC


## Installation

RComposeBar is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RComposeBar'
```

## Usage

First import RComposebar to your class `#import <RComposeBar/RComposeBar.h>`

Then you can setup RComposeBar withing your class.

Set global properties to keep composeBar and container of the compose bar.
We have placed a ToolBar at the bottom of the screen to put compose bar in it.

```objective-c
@property (strong, nonatomic) RComposeBar *composeBar; // RComposeBaee
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;  // Any view to hold the compose bar (UIToolbar is used here)
```

This container view (toolbar) height doesnt need to adjust manually with the growth of the tool bar. But if you wanna remove the default animation of the chaging of autoLayout values, you may add an IBOutlet and set the height value manually on relevant delegate method. 

```objective-c
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *toolbarHeight;
```

Then instantiate and setup compose bar

```objective-c
_composeBar = [[RComposeBar alloc] initWithContainer:_toolbar delegate:self];
// _composeBar.delegate = self;
_composeBar.dataSource = self;
// _composeBar.sendTitle = @"Post"; // change button text
_composeBar.leftButtonImage = [UIImage imageNamed:@"more"];
[_composeBar setRightButtonWithTag:1 image:[UIImage imageNamed:@"mic"] backToKBImage:[UIImage imageNamed:@"kb"]];
// [_composeBar setRightButtonWithTag:AUDIO_RECORDER text:@"Mic" backToKBYText:@"KB"]; // text instead of an image
_composeBar.maxHeight = 200; // max height that compose bar can grow
_composeBar.placeholder = @"whats on your mind";
```

Then implement mandetory delegate methods of `RComposeBarDelegate`, that required to work compose bar smoothly
RComposeBarDelegate (required)

```objective-c
-(void)composeBarSendDidTapped:(NSString *)text {
    // this method will called with send button tapped (only if textbox text available)
    [_chatList addObject:@{kText : text, kMine : @(1)}];
    [_table reloadData];
}

-(void)composeBarHeightDidChange:(CGFloat)height {
    // optional - layout engine will animate this change - if you wanna remove animation add this
    _toolbarHeight.constant = height; 
}
```

RComposeBarDelegate (optional)

```objective-c
- (void) composeBarLeftButtonTapped {
    /** Left button tapped */
}

- (void) composeBarRightButtomTapped:(NSInteger)tag {
    /** Right button tapped (only when textbox is empty)*/
    /** Tag can be used to identify the purpose of the right button - can be used for multiple purposses */
}

- (void) composeBarLocationSelected {
    /** Location selected */
}

- (void) composeBarTextDidChanged:(NSString *)text {
    /** Text value changed in compose bar */
}

- (void) deleteComposeBarItemAtIndex:(NSInteger)index {
    /** Item at index should be deleted */
}

- (void) selecteComposeBarItemAtIndex:(NSInteger)index {
    /** Item at index is selected */
}

- (void) deleteComposeBarLocation {
    /** Location should be deleted */
}

- (void) composeBarDidClear {
    /** Clear data triggred - you should cleat location and item data */
}
```

Then implement optional `RComposeBarDataSource`


```objective-c
- (NSInteger) numberOfItemsInComposeBar {
    /** Number of items in item container */
}

- (UIImage *) imageForComposeBarItemAtIndex:(NSInteger)index {
    /** Image item at index at item container
    @return thumbnail image for item (image/video etc) must not be nil */
}

- (NSString *) locationInComposeBar {
    /** Location string to display on compose bar */
    // location will be hidden when not set or returns nil
}
```

Please see the example project for more information

## Customization

Most of the visible UI settings can be customizable to suit your needs and to match the theme colors of your app.
See inline dicumentioan of the `RComposeBar.h` file

e.g. some sample customization properties

```objective-c
_composeBar.topLineColor = [UIColor lightGrayColor];
_composeBar.bottomLineColor = [UIColor lightGrayColor];
_composeBar.textBoxBorderColor = [UIColor redColor];
_composeBar.font =  = [UIFont systemFontOfSize:20];
```

## Screenshots

![alt tag](https://github.com/rjeprasad/RComposeBar/blob/master/Example/Screenshots/one.png)

![alt tag](https://github.com/rjeprasad/RComposeBar/blob/master/Example/Screenshots/two.png)

![alt tag](https://github.com/rjeprasad/RComposeBar/blob/master/Example/Screenshots/three.png)

## Github

[https://github.com/rjeprasad/RComposeBar](https://github.com/rjeprasad/RComposeBar)

## Author

Rajeev Prasad, rjeprasad@gmail.com

## License

RComposeBar is available under the MIT license.

Copyright © 2016 Rajeev Prasad.

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
