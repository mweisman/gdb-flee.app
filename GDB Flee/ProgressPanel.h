//
//  ProgressPanel.h
//  GDB Flee
//
//  Created by Michael Weisman on 2012-10-31.
//  Copyright (c) 2012 Michael Weisman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProgressPanel : NSPanel

@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSProgressIndicator *progessBar;

@end
