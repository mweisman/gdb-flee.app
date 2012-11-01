//
//  Interfaces.h
//  GDB Flee
//
//  Created by Michael Weisman on 2012-10-25.
//  Copyright (c) 2012 Michael Weisman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OGRResponse.h"

@protocol OGR

-(void)driverForFileAtLocation:(NSString *)fileLocation
      reply:(void (^)(OGRResponse *ogrr))reply;

- (void)convertFileAtLocation:(NSString *)fileLocation
                     toFormat:(NSString *)format
                   toLocation:(NSString *)outLocation
            reply:(void (^)(OGRResponse *ogrr))reply;

@end
