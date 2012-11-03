//
//  AppDelegate.m
//  GDB Flee
//
//  Created by Michael Weisman on 2012-10-25.
//  Copyright (c) 2012 Michael Weisman. All rights reserved.
//

#import "AppDelegate.h"
#import "InputSettingsViewController.h"

@implementation AppDelegate {
    NSString *gdbPath;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    [self processFile:filename];
    return YES;
}

- (void)processFile:(NSString *)file {
    NSURL *filePath = [NSURL URLWithString:file];
    
    NSXPCConnection *fileCheckConnection = [[NSXPCConnection alloc] initWithServiceName:@"com.mweisman.OGRService"];
    fileCheckConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OGR)];
    fileCheckConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OGRProgress)];
    fileCheckConnection.exportedObject = self;
    [fileCheckConnection resume];
    
    id <OGR> ogrCheckAgent = [fileCheckConnection remoteObjectProxyWithErrorHandler:^(NSError *err) {
        // Since we're updating the UI, we must do this work on the main thread
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle: @"OK"];
            [alert setMessageText: @"An Unkown error occurred while scanning this file. Please try again."];
            [alert setAlertStyle: NSWarningAlertStyle];
            
            [alert runModal];
            
            [NSApp endSheet:_progressPanel];
            [_progressPanel orderOut:self];
            [fileCheckConnection invalidate];
        }];
    }];
    
    [ogrCheckAgent driverForFileAtLocation:[filePath path] reply:^(OGRResponse *ogrr){
        if ([ogrr.response isEqualToString:@"FileGDB"]) {
            _inputFile.stringValue = [[filePath pathComponents] lastObject];
            gdbPath = file;
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSAlert *badFileAlert = [NSAlert alertWithMessageText:@"Invalid File Geodatabase"
                                                        defaultButton:@"OK"
                                                      alternateButton:nil
                                                          otherButton:nil
                                            informativeTextWithFormat:@"%@", ogrr.response];
                [badFileAlert runModal];
            }];
        }
        [fileCheckConnection invalidate];
    }];
}


- (IBAction)free:(id)sender {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    NSOpenPanel *shpSavePanel = [NSOpenPanel openPanel];
    [savePanel setExtensionHidden:NO];
    NSString *ogrFormat = nil;
    if ([[_formatSelector titleOfSelectedItem] isEqualToString:@"Shapefile"]) {
        ogrFormat = @"ESRI Shapefile";
        [shpSavePanel setCanChooseDirectories:YES];
        [shpSavePanel setCanCreateDirectories:YES];
        [shpSavePanel setCanChooseFiles:NO];
    } else if ([[_formatSelector titleOfSelectedItem] isEqualToString:@"GeoJSON"]) {
        ogrFormat = @"GeoJSON";
        [savePanel setAllowedFileTypes:@[@"json"]];
        [savePanel setNameFieldStringValue:[NSString stringWithFormat:@"%@.json", _inputFile.stringValue]];
    } else if ([[_formatSelector titleOfSelectedItem] isEqualToString:@"KML"]) {
        ogrFormat = @"KML";
        [savePanel setAllowedFileTypes:@[@"kml"]];
        [savePanel setNameFieldStringValue:[NSString stringWithFormat:@"%@.kml", _inputFile.stringValue]];
    } else if ([[_formatSelector titleOfSelectedItem] isEqualToString:@"PostGIS Dump"]) {
        ogrFormat = @"PGDump";
        [savePanel setAllowedFileTypes:@[@"sql"]];
        [savePanel setNameFieldStringValue:[NSString stringWithFormat:@"%@.sql", _inputFile.stringValue]];
    }
    
    NSInteger savePanelReturn;
    NSString *saveLoc = nil;
    if ([ogrFormat isEqualToString:@"ESRI Shapefile"]) {
        savePanelReturn = [shpSavePanel runModal];
        if (savePanelReturn == NSOKButton) {
            saveLoc = [[shpSavePanel directoryURL] path];
        } else {
            return;
        }
    } else {
        savePanelReturn = [savePanel runModal];
        if (savePanelReturn == NSFileHandlingPanelOKButton) {
            saveLoc = [[savePanel URL] path];
        } else {
            return;
        }
    }
    
    [NSApp beginSheet:_progressPanel modalForWindow:_window modalDelegate:self didEndSelector:nil contextInfo:nil];
    [[NSApplication sharedApplication] beginSheet:_progressPanel modalForWindow:_window modalDelegate:self didEndSelector:nil contextInfo:nil];
    [_progressPanel.progessBar startAnimation:nil];
    [_progressPanel.statusLabel setStringValue:[NSString stringWithFormat:@"Converting %@ to %@",_inputFile.stringValue, ogrFormat]];
    [_progressPanel.progessBar setIndeterminate:NO];
    [_progressPanel.progessBar setDoubleValue:0.0];
    
    NSXPCConnection *convertConnection = [[NSXPCConnection alloc] initWithServiceName:@"com.mweisman.OGRService"];
    convertConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OGR)];
    convertConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OGRProgress)];
    convertConnection.exportedObject = self;
    [convertConnection resume];
    
    id <OGR> ogrConversionAgent = [convertConnection remoteObjectProxyWithErrorHandler:^(NSError *err) {
        // Since we're updating the UI, we must do this work on the main thread
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle: @"OK"];
            [alert setMessageText: @"An Unkown error occurred while scanning this file. Please try again."];
            [alert setAlertStyle: NSWarningAlertStyle];
            
            [alert runModal];
            
            [NSApp endSheet:_progressPanel];
            [_progressPanel orderOut:self];
            [convertConnection invalidate];
        }];
    }];
    
    [ogrConversionAgent convertFileAtLocation:gdbPath toFormat:ogrFormat toLocation:saveLoc reply:^(OGRResponse *ogrr){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            [notification setTitle:@"Conversion Complete"];
            [notification setInformativeText:[NSString stringWithFormat:@"%@ has been converted to %@", _inputFile.stringValue, ogrFormat]];
            [notification setDeliveryDate:[NSDate date]];
            [notification setSoundName:NSUserNotificationDefaultSoundName];
            NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
            [center setDelegate:self];
            [center scheduleNotification:notification];
            [NSApp endSheet:_progressPanel];
            [_progressPanel orderOut:self];
        }];
        [convertConnection invalidate];
    }];
}

- (IBAction)moreInfo:(id)sender {
    NSOpenPanel *gdbOpenPanel = [NSOpenPanel openPanel];
    [gdbOpenPanel setCanChooseFiles:NO];
    [gdbOpenPanel setCanChooseDirectories:YES];
    [gdbOpenPanel setAllowsMultipleSelection:NO];
    [gdbOpenPanel setPrompt:@"Open"];
    NSInteger panelReturn = [gdbOpenPanel runModal];
    if (panelReturn == NSOKButton) {
        [self processFile:[[gdbOpenPanel URL] path]];
    }
}

- (IBAction)showOptions:(id)sender {
    if (_optionsButton.state == NSOnState) {
        [_popover showRelativeToRect:[_optionsButton bounds] ofView:_optionsButton preferredEdge:NSMaxYEdge];
    } else {
        [_popover close];
    }

}

#pragma mark OGRProgress
- (void)setProgress:(double)progress {
    [_progressPanel.progessBar setDoubleValue:progress];
}
- (void)setLayerName:(NSString *)name {
    [_progressPanel.statusLabel setStringValue:[NSString stringWithFormat:@"Processing Layer %@", name]];
}

#pragma mark notification center handler
-(void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    //Remove the notification
    [center removeDeliveredNotification:notification];
}

@end
