//
//  AppDelegate.h
//  GDB Flee
//
//  Created by Michael Weisman on 2012-10-25.
//  Copyright (c) 2012 Michael Weisman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProgressPanel.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *inputFile;
@property (weak) IBOutlet NSPopUpButton *formatSelector;
@property (weak) IBOutlet NSButton *goButton;
@property NSXPCConnection *connection;
@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSButton *inputInfoButton;
@property (unsafe_unretained) IBOutlet ProgressPanel *progressPanel;
@property (weak) IBOutlet NSButton *optionsButton;


- (IBAction)free:(id)sender;
- (IBAction)moreInfo:(id)sender;
- (IBAction)showOptions:(id)sender;
- (void)processFile:(NSString *)file;
@end
