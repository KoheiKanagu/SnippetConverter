//  Copyright (c) 2014年 KoheiKanagu. All rights reserved.

#import "ConvertCCPtoDash.h"

@implementation ConvertCCPtoDash


-(id)initWithDashDBDir:(NSString *)dash_dir CCPDBDir:(NSString *)ccp_dir
{
    self = [super init];
    if(self){
        if([self loadDashDB:dash_dir]){
            if([self loadCCPDB:ccp_dir]){
                return self;
            }
        }
    }
    return nil;
}


-(BOOL)loadDashDB:(NSString *)dir
{
    if(sqlite3_open([dir UTF8String], &Dash_DB) == SQLITE_OK){
        self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"open %@\n", dir]];
        return YES;
    }
    self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"error open %@\n", dir]];
    return NO;
}

-(void)closeDashDB
{
    sqlite3_close(Dash_DB);
}


-(BOOL)loadCCPDB:(NSString *)dir
{
    if(sqlite3_open([dir UTF8String], &CCP_DB) == SQLITE_OK){
        self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"open %@\n", dir]];
        return YES;
    }
    self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"error open %@\n", dir]];
    return NO;
}

-(void)closeCCPDB
{
    sqlite3_close(CCP_DB);
}



-(void)convertCCPLiblaryToDash
{
    [self getCCPLiblary];
    [self closeCCPDB];
    
    self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"======== start insert to Dash library ========\n"]];
    
    for(NSDictionary *object in CCP_DB_Array){
        NSInteger sid = [self executeSQL_Dash_insertSnippets:object];
        
        for(NSString *tag in [[object objectForKey:@"ZTAG"] componentsSeparatedByString:@","]){
            if(!tag.length){
                continue;
            }
            NSInteger tid = [self executeSQL_Dash_insertTags:tag];
            
            [self executeSQL_Dash_insertTagsindex:tid
                                              sid:sid];
        }
    }
    [self closeDashDB];
    self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"======== end insert to Dash library ========\n"]];
}



#pragma mark - Dash

-(void)executeSQL_Dash_insertTagsindex:(NSInteger )tid sid:(NSInteger )sid
{
    NSString *query = [NSString stringWithFormat:@"INSERT INTO tagsIndex(tid, sid)\nVALUES (%ld, %ld);", tid, sid];
    
    if([self executeSQL:Dash_DB
                   stmt:&Dash_stmt
                  query:query]){
        sqlite3_step(Dash_stmt);
    }else{
        self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"error_executeSQL_Dash_insertTagsindex\n"]];
    }
}

-(NSInteger)executeSQL_Dash_insertTags:(NSString *)tag
{
    NSInteger tid = [self executeSQL_Dash_searchTags:tag];
    if(tid == -1){
        tid = [self executeSQL_Dash_getMAX:@"tid"
                                      from:@"tags"]+1;
        NSString *query = [NSString stringWithFormat:@"INSERT INTO tags(tid, tag)\nVALUES(%ld, \'%@\');", tid, tag];
        if(![self executeSQL:Dash_DB
                        stmt:&Dash_stmt
                       query:query]){
            self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"error_executeSQL_Dash_insertTags"]];
        }
        sqlite3_step(Dash_stmt);
    }
    return tid;
}


-(NSInteger)executeSQL_Dash_searchTags:(NSString *)tag
{
    NSString *query = [NSString stringWithFormat:@"SELECT tid\nFROM tags\nWHERE tag == \'%@\';", tag];
    
    if([self executeSQL:Dash_DB
                   stmt:&Dash_stmt
                  query:query]){
        sqlite3_step(Dash_stmt);
        
        char *charTid = (char *)sqlite3_column_text(Dash_stmt, 0);
        if(charTid){
            return [[NSString stringWithUTF8String:charTid] intValue];
        }
    }else{
        self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"error_executeSQL_Dash_searchTags\n"]];
    }
    return -1;
}


-(NSInteger)executeSQL_Dash_insertSnippets:(NSDictionary *)source
{
    NSInteger maxSID = [self executeSQL_Dash_getMAX:@"sid"
                                               from:@"snippets"];
    if(maxSID == -1){
        return -1;
    }
    NSString *ZNAME = [source objectForKey:@"ZNAME"];
    NSString *query = [NSString stringWithFormat:@"INSERT INTO snippets(sid, title, body, syntax, usageCount)\nVALUES(%ld, \'%@\', \'%@\', \'%@\', 0);", maxSID+1, ZNAME, [source objectForKey:@"ZCODE"], [source objectForKey:@"ZLANGUAGE"]];
    
    if([self executeSQL:Dash_DB
                   stmt:&Dash_stmt
                  query:query]){
        sqlite3_step(Dash_stmt);
    }else{
        self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"error_executeSQL_Dash_insertSnippet\n"]];
        return -1;
    }
    return maxSID+1;
}


-(NSInteger)executeSQL_Dash_getMAX:(NSString *)columnName from:(NSString *)tableName
{
    NSString *query = [NSString stringWithFormat:@"SELECT MAX(%@)\nFROM %@;", columnName, tableName];
    
    if([self executeSQL:Dash_DB
                   stmt:&Dash_stmt
                  query:query]){
        sqlite3_step(Dash_stmt);
        return sqlite3_column_int(Dash_stmt, 0);
    }else{
        self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"error_executeSQL_Dash_getMAX\n"]];
    }
    return -1;
}





#pragma mark - CCP

-(void)getCCPLiblary
{
    self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"======== start analyze of CCP library ========\n"]];

    CCP_DB_Array = [self executeSQL_CCP_getSnippetDetails];
    [self executeSQL_CCP_setZLANGfullName:CCP_DB_Array];
    
    self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"======== end analyze of CCP library ========\n"]];
}

-(void)executeSQL_CCP_setZLANGfullName:(NSMutableArray *)array
{
    for(int i=0; i<array.count; i++){
        NSMutableDictionary *dic = [[NSMutableDictionary alloc]initWithDictionary:array[i]];
        int ZLANGUAGE = [[dic objectForKey:@"ZLANGUAGE"] intValue];
        
        NSString *query = [NSString stringWithFormat:@"SELECT ZNAME\nFROM ZLANGUAGES\nWHERE Z_PK == %d;", ZLANGUAGE];
        if([self executeSQL:CCP_DB
                       stmt:&CCP_stmt
                      query:query]){
            while(sqlite3_step(CCP_stmt) == SQLITE_ROW){
                NSString *lang = [NSString stringWithUTF8String:(char *)sqlite3_column_text(CCP_stmt, 0)];
                [dic setObject:lang
                        forKey:@"ZLANGUAGE"];
                [array replaceObjectAtIndex:i
                                 withObject:dic];
            }
        }else{
            self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"error_executeSQL_CCP_setZLANGfullName\n"]];
            return;
        }
    }
}


-(NSMutableArray *)executeSQL_CCP_getSnippetDetails
{
    NSString *query = @"SELECT ZNAME, ZCODE, ZTAGS, ZLANGUAGE\nFROM `ZSNIPPET`;";
    NSMutableArray *array = [[NSMutableArray alloc]init];
    
    if([self executeSQL:CCP_DB
                   stmt:&CCP_stmt
                  query:query]){
        while(sqlite3_step(CCP_stmt) == SQLITE_ROW){
            
            NSString *ZNAME = @"";
            char *tmp = (char *)sqlite3_column_text(CCP_stmt, 0);
            if(tmp){
                ZNAME = [NSString stringWithUTF8String:tmp];
            }
            
            NSString *ZCODE = @"";
            tmp = (char *)sqlite3_column_text(CCP_stmt, 1);
            if(tmp){
                ZCODE = [NSString stringWithUTF8String:tmp];
            }
            
            NSString *ZTAG = @"";
            tmp = (char *)sqlite3_column_text(CCP_stmt, 2);
            if(tmp){
                ZTAG = [NSString stringWithUTF8String:tmp];
            }
            
            NSNumber *ZLANGUAGE = [NSNumber numberWithInt:sqlite3_column_int(CCP_stmt, 3)];
            
            NSDictionary *object = @{@"ZNAME":ZNAME, @"ZCODE":ZCODE, @"ZTAG":ZTAG, @"ZLANGUAGE":ZLANGUAGE};
            [array addObject:object];
            
            self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"name : %@, tag : %@\n", ZNAME, ZTAG]];
        }
    }else{
        self.logTextView.string = [self.logTextView.string stringByAppendingString:[NSString stringWithFormat:@"error_executeSQL_CCP_getSnippetDetails\n"]];
        return nil;
    }
    return array;
}



#pragma mark - common

-(BOOL)executeSQL:(sqlite3 *)db stmt:(sqlite3_stmt **)stmt query:(NSString *)query
{
    int result = sqlite3_prepare_v2(db,
                                    [query UTF8String],
                                    -1,
                                    stmt,
                                    NULL);
    if(result == SQLITE_OK){
        return true;
    }else{
        return false;
    }
}

@end
