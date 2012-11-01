//
//  OGRAgent.h
//  GDB Flee
//
//  Created by Michael Weisman on 2012-10-25.
//  Copyright (c) 2012 Michael Weisman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Interfaces.h"
#import <ogr_api.h>
#import <cpl_error.h>

@interface OGRAgent : NSObject <NSXPCListenerDelegate, OGR>

void ogrErrHandler(CPLErr eErrClass, int err_no, const char *msg);

@end
