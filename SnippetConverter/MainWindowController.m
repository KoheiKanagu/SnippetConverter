//  Copyright (c) 2014年 KoheiKanagu. All rights reserved.

#import "MainWindowController.h"


@implementation MainWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
    }
    return self;
}

-(IBAction)openDashLibButton:(id)sender
{
    NSString *home = [NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Dash/library.dash"];
    NSURL *url = [self openWithFileTypes:@[@"dash"] defaultDir:[NSURL fileURLWithPath:home]];
    
    if(url){
        [dashDirField setStringValue:[url path]];
    }
}


-(IBAction)openCCPLibButton:(id)sender
{
    NSString *home = [NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Code Collector Pro/Code_Collector.sql"];
    NSURL *url = [self openWithFileTypes:@[@"sql"] defaultDir:[NSURL fileURLWithPath:home]];

    if(url){
        [CCPDirField setStringValue:[url path]];
    }
}


-(NSURL *)openWithFileTypes:(NSArray *)types defaultDir:(NSURL *)url
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setResolvesAliases:NO];
    [panel setAllowedFileTypes:types];
    [panel setDirectoryURL:url];
    
    if([panel runModal] == NSOKButton){
        return [panel URL];
    }
    return nil;
}


-(IBAction)convertButton:(id)sender
{
    if(dashDirField.stringValue.length && CCPDirField.stringValue.length){
        c2d = [[ConvertCCPtoDash alloc]initWithDashDBDir:dashDirField.stringValue
                                                CCPDBDir:CCPDirField.stringValue];
        if(c2d){
            [progressIndicator startAnimation:nil];
            logViewer.string = @"";
            
            c2d.logTextView = logViewer;
            [c2d convertCCPLiblaryToDash];
        }else{
            logViewer.string = [logViewer.string stringByAppendingString:@"open error\n"];
            return;
        }
        logViewer.string = [logViewer.string stringByAppendingString:@"finish!\n"];
        [progressIndicator stopAnimation:nil];
        
        
        NSAlert *alert = [NSAlert alertWithMessageText:@"Finish!"
                                         defaultButton:@"閉じる"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        [alert beginSheetModalForWindow:self.window
                      completionHandler:nil];
    }
}



@end
