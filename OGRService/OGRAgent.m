//
//  OGRAgent.m
//  GDB Flee
//
//  Created by Michael Weisman on 2012-10-25.
//  Copyright (c) 2012 Michael Weisman. All rights reserved.
//

#import "OGRAgent.h"

const char *ogrErrMsg;

@implementation OGRAgent

// OGR Error handler
void ogrErrHandler(CPLErr eErrClass, int err_no, const char *msg) {
    ogrErrMsg = msg;
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    // This method will be called by the NSXPCListener. It gives the delegate an opportunity to configure and accept (or reject) a new incoming connection.
    
    // The connection is created, but unconfigured and suspended. We will finish configuring it here, resume it, and return YES.
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OGR)];
    
    // This object instance is both the delegate and the singleton implementation of the Agent protocol. Another common pattern may be to create a new object to serve as the exportedObject for each new connection.
    newConnection.exportedObject = self;
    
    // Setup remote obect to allow call back into main app
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OGRProgress)];

    
    // Allow messages to be received.
    [newConnection resume];
    
    // Allow access to the active connection by agent methods
    _xpcConnection = newConnection;
    
    return YES;
}
- (void)driverForFileAtLocation:(NSString *)fileLocation reply:(void (^)(OGRResponse *))reply {
    OGRResponse *response = [OGRResponse new];
    response.response = @"test";
    //reply(response);
    OGRRegisterAll();
    CPLSetErrorHandler(ogrErrHandler);
    
    // Open FileGDB
    OGRDataSourceH gdb_ds = OGROpen([fileLocation cStringUsingEncoding:NSUTF8StringEncoding], FALSE, NULL);
    if(gdb_ds == NULL) {
        response.response = [NSString stringWithCString:ogrErrMsg encoding:NSUTF8StringEncoding];
        response.callWasSuccess = NO;
        OGRCleanupAll();
        reply(response);
    }
    OGRSFDriverH driverh = OGR_DS_GetDriver(gdb_ds);
    response.response = [NSString stringWithCString:OGR_Dr_GetName(driverh) encoding:NSUTF8StringEncoding];
    response.callWasSuccess = YES;
    OGR_DS_Destroy(gdb_ds);
    OGRCleanupAll();
    reply(response);
}

- (void)convertFileAtLocation:(NSString *)fileLocation toFormat:(NSString *)format toLocation:(NSString *)outLocation reply:(void (^)(OGRResponse *ogrr))reply {
    static char *ogrEncoding = "ENCODING=UTF-8";
    OGRResponse *response = [OGRResponse new];
    OGRRegisterAll();
    CPLSetErrorHandler(ogrErrHandler);
    
    // Open FileGDB
    OGRDataSourceH gdb_ds = OGROpen([fileLocation cStringUsingEncoding:NSUTF8StringEncoding], FALSE, NULL);
    if(gdb_ds == NULL) {
        response.response = [NSString stringWithFormat:@"Could not open %@", fileLocation];
        response.callWasSuccess = NO;
        OGRCleanupAll();
        reply(response);
    }
    
    // Setup the output
    OGRSFDriverH out_driver = OGRGetDriverByName([format cStringUsingEncoding:NSUTF8StringEncoding]);
    if(out_driver == NULL) {
        response.response = [NSString stringWithFormat:@"%@ driver not found", format];
        response.callWasSuccess = NO;
        OGRCleanupAll();
        reply(response);
    }
    
    OGRDataSourceH out_ds = OGR_Dr_CreateDataSource(out_driver, [outLocation cStringUsingEncoding:NSUTF8StringEncoding], NULL);
    if(out_ds == NULL) {
        response.response = @"Could not create output dataset";
        response.callWasSuccess = NO;
        OGRCleanupAll();
        reply(response);
    }
    
    // Copy FileGDB layers (aka tables/feature classes) into output layers
    int iLyr;
    for (iLyr = 0; iLyr < OGR_DS_GetLayerCount(gdb_ds); iLyr++) {
        OGRLayerH layer = OGR_DS_GetLayer(gdb_ds, iLyr);
        OGRFeatureDefnH fd = OGR_L_GetLayerDefn(layer);
        
        OGRLayerH out_layer = OGR_DS_CreateLayer(out_ds, OGR_L_GetName(layer),
                                                 OGR_L_GetSpatialRef(layer), OGR_L_GetGeomType(layer), &ogrEncoding);
        
        int iField;
        for(iField = 0; iField < OGR_FD_GetFieldCount(fd); iField++) {
            OGR_L_CreateField(out_layer, OGR_FD_GetFieldDefn(fd, iField), TRUE);
        }
        
        OGRFeatureH feat;
        OGR_L_ResetReading(layer);
//        OGR_L_GetFeatureCount(<#OGRLayerH#>, <#int#>)
        while((feat = OGR_L_GetNextFeature(layer)) != NULL ) {
            OGRFeatureH feature = OGR_F_Clone(feat);
            OGR_L_CreateFeature(out_layer, feature);
            OGR_F_Destroy(feat);
            OGR_F_Destroy(feature);
        }
    }
    OGR_DS_Destroy(gdb_ds);
    OGR_DS_Destroy(out_ds);
    OGRCleanupAll();
    
    response.response = @"";
    response.callWasSuccess = YES;
    reply(response);
}


@end
