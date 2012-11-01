//
//  AppDelegate.m
//  GDB Flee
//
//  Created by Michael Weisman on 2012-10-25.
//  Copyright (c) 2012 Michael Weisman. All rights reserved.
//

#import "AppDelegate.h"
#import "Interfaces.h"
#import "InputSettingsViewController.h"

@implementation AppDelegate {
    id <OGR> _ogrAgent;
    NSString *gdbPath;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    _connection = [[NSXPCConnection alloc] initWithServiceName:@"com.mweisman.OGRService"];
    _connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OGR)];
    [_connection resume];
    
    // Get a proxy object from the connection. This object implements the Agent protocol and calls the supplied error handling block if something goes wrong when a message with a reply is sent.
    _ogrAgent = [_connection remoteObjectProxyWithErrorHandler:^(NSError *err) {
        // Since we're updating the UI, we must do this work on the main thread
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle: @"OK"];
            [alert setMessageText: @"An Unkown error occurred. Please try again."];
            [alert setAlertStyle: NSWarningAlertStyle];
            
            [alert runModal];
            
            [NSApp endSheet:_progressPanel];
            [_progressPanel orderOut:self];
        }];
    }];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    [self processFile:filename];
    return YES;
}

- (void)processFile:(NSString *)file {
    NSURL *filePath = [NSURL URLWithString:file];
    [_ogrAgent driverForFileAtLocation:[filePath path] reply:^(OGRResponse *ogrr){
        if ([ogrr.response isEqualToString:@"FileGDB"]) {
            _inputFile.stringValue = [[filePath pathComponents] lastObject];
            gdbPath = file;
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSAlert *badFileAlert = [NSAlert alertWithMessageText:@"Invalid File Geodatabase"
                                                        defaultButton:@"OK"
                                                      alternateButton:nil
                                                          otherButton:nil
                                            informativeTextWithFormat:@"%@ is not a valid File Geodatabase", file];
                [badFileAlert runModal];
            }];
        }
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
    [_ogrAgent convertFileAtLocation:gdbPath toFormat:ogrFormat toLocation:saveLoc reply:^(OGRResponse *ogrr){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [NSApp endSheet:_progressPanel];
            [_progressPanel orderOut:self];
        }];
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

@end
