//
//  OGRResponse.m
//  GDB Flee
//
//  Created by Michael Weisman on 2012-10-25.
//  Copyright (c) 2012 Michael Weisman. All rights reserved.
//

#import "OGRResponse.h"

@implementation OGRResponse

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        // NSSecureCoding requires that we specify the class of the object while decoding it, using the decodeObjectOfClass:forKey: method.
        _response = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"OGRResponse"];
    }
    return self;
}

// Because this class implements initWithCoder:, it must also return YES from this method.
+ (BOOL)supportsSecureCoding { return YES; }

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_response forKey:@"OGRResponse"];
}


@end
