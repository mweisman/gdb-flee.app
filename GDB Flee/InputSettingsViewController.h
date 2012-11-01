//
//  InputSettingsViewController.h
//  GDB Flee
//
//  Created by Michael Weisman on 2012-10-26.
//  Copyright (c) 2012 Michael Weisman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InputSettingsViewController : NSViewController
- (IBAction)close:(id)sender;
@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSTextField *typeLabel;
@property (weak) IBOutlet NSProgressIndicator *spinner;

@end
