//
//  main.m
//  OGRService
//
//  Created by Michael Weisman on 2012-10-25.
//  Copyright (c) 2012 Michael Weisman. All rights reserved.
//

#include <Foundation/Foundation.h>
#import "OGRAgent.h"

int main(int argc, const char *argv[])
{
    // An XPCService should use this singleton instance of serviceListener. It is preconfigured to listen on the name advertised by this XPCService's Info.plist.
    NSXPCListener *listener = [NSXPCListener serviceListener];
    
    // Create the delegate of the listener.
    OGRAgent *ogrAgent = [OGRAgent new];
    listener.delegate = ogrAgent;
    
    // Calling resume on the serviceListener does not return. It will wait for incoming connections using CFRunLoop or a dispatch queue, as appropriate.
    [listener resume];
	return 0;
}