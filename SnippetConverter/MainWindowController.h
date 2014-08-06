//  Copyright (c) 2014年 KoheiKanagu. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <sqlite3.h>

#import "ConvertCCPtoDash.h"

@interface MainWindowController : NSWindowController
{
    IBOutlet NSTextField *dashDirField;
    IBOutlet NSTextField *CCPDirField;
    IBOutlet NSTextView *logViewer;
    
    IBOutlet NSProgressIndicator *progressIndicator;
    
    ConvertCCPtoDash *c2d;
}


@end
