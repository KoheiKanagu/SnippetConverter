//  Copyright (c) 2014年 KoheiKanagu. All rights reserved.

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface ConvertCCPtoDash : NSObject
{
    sqlite3 *CCP_DB;
    sqlite3_stmt *CCP_stmt;
    NSMutableArray *CCP_DB_Array;
    
    sqlite3 *Dash_DB;
    sqlite3_stmt *Dash_stmt;
}

-(id)initWithDashDBDir:(NSString *)dash_dir CCPDBDir:(NSString *)ccp_dir;
-(void)convertCCPLiblaryToDash;

@property NSTextView *logTextView;

@end
