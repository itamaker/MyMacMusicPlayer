//
//  MainWindowController.m
//  MyMusicPlayer
//
//  Created by isaced on 13-7-21.
//  Copyright (c) 2013年 isaced. All rights reserved.
//

#import "MainWindowController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MusicTools.h"

@interface MainWindowController () <NSDraggingDestination>

@property (weak) IBOutlet NSImageView *backgroundImageView;
@property (weak) IBOutlet NSSlider *progressSlider;

@property (strong) AVAudioPlayer* player;
@property (strong) NSMutableArray *musicArray;

//@property (strong) filteringOptions;
@end

@implementation MainWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Title Bar
    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.styleMask |= NSFullSizeContentViewWindowMask;
    
    // Window Style
    NSColor *windowBackgroundColor = [NSColor colorWithRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:1.0];
    [self.window setBackgroundColor: windowBackgroundColor];
    self.window.movableByWindowBackground = YES;
    
    // Drag and drop
    [self.window registerForDraggedTypes:@[NSFilenamesPboardType]];
    [self.backgroundImageView unregisterDraggedTypes];
    
//        [NSImage imageTypes]
    //    @{NSPasteboardURLReadingContentsConformToTypesKey: }
    
    //init Array
    self.musicArray = [[NSMutableArray alloc] init];
    
    //初始音量
    [self.player setVolume: 0.5];
    
    //选择表格中第一行
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
    [self.tableView selectRowIndexes:indexSet byExtendingSelection:NO];
    

}


//上一首
- (IBAction)previousAction:(id)sender {

}

//下一首
- (IBAction)nextAction:(id)sender {
    
}

//播放
- (IBAction)playAction:(id)sender {
    if (self.musicArray.count > 0) {
        //初始化
        NSDictionary *musicDic = self.musicArray.firstObject;
        NSData *musicData = [NSData dataWithContentsOfURL:[NSURL URLWithString:musicDic[@"url"]]];
        self.player = [[AVAudioPlayer alloc] initWithData:musicData error:nil ];
        [self.player play];
    }else{
        NSLog(@"列表中没有歌曲！");
    }
}


- (IBAction)addMusicToListAction:(id)sender {
    
    //初始化 NSOpenPanel
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    //只能选择文件
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    
    //允许多选
    [openDlg setAllowsMultipleSelection:YES];
    
    NSArray *urlArray;
    
    //打开
    if ([openDlg runModal] == NSOKButton) {
        urlArray = [openDlg URLs];
    }
    
    //分析
    for (NSURL *url in urlArray) {
        NSDictionary *dic = [self openFile:url];
        [self.musicArray addObject:dic];
    }
    
    [self.tableView reloadData];
}

- (NSDictionary *)openFile:(NSURL *)url {

    NSDictionary *ID3Dic = [MusicTools readMusicInfoForFile:url];

    NSString *name = ID3Dic[@"title"];
    NSString *artist = ID3Dic[@"artist"];
    NSString *time = ID3Dic[@"approximate duration in seconds"];

    NSDictionary *dic = @{@"name":name,@"artist":artist,@"time":time,@"url":[url absoluteString]};
    return dic;
}

//音量调节 - Slider
- (IBAction)soundVolumeSliderChangeAction:(id)sender {
    NSSlider *slider = (NSSlider *)sender;
    [self.player setVolume:slider.doubleValue];
}
    
//Tableview
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    NSDictionary *musicDic = self.musicArray[row];

    if( [tableColumn.identifier isEqualToString:@"number"] ){
        cellView.textField.stringValue = [NSString stringWithFormat:@"%ld",row];
    }else if ([tableColumn.identifier isEqualToString:@"name"]){
        cellView.textField.stringValue = musicDic[@"name"];
    }else if ([tableColumn.identifier isEqualToString:@"time"]){
        cellView.textField.stringValue = [NSString stringWithFormat:@"%d:%.2d",[musicDic[@"time"] intValue] / 60,[musicDic[@"time"] intValue] % 60];
    }
    
    return cellView;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.musicArray count];
}


#pragma mark <NSDraggingDestination>

- (BOOL)shouldAllowDrag:(id<NSDraggingInfo>)draggingInfo {
    BOOL canAccept = NO;
    NSPasteboard *pasteBoard = [draggingInfo draggingPasteboard];
    if ([pasteBoard canReadObjectForClasses:@[[NSURL class]] options:nil]) {
        canAccept = YES;
    }
    return canAccept;
}

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender{
    return NSDragOperationGeneric;
}

-(void)draggingExited:(id<NSDraggingInfo>)sender{

}

-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender{
    return [self shouldAllowDrag:sender];
}

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender{
    NSPasteboard *pasteBoard = [sender draggingPasteboard];
    NSArray *urls = [pasteBoard readObjectsForClasses:@[[NSURL class]] options:nil];
    NSLog(@"Drag and drop : %@",urls);
    
    NSURL *url = [urls firstObject];
    if (url) {
        NSDictionary *dic = [self openFile:url];
        self.TitleTextField.stringValue = [NSString stringWithFormat:@"%@ - %@",dic[@"name"],dic[@"artist"]];
        [self.musicArray addObject:dic];
    }
    
    return YES;
}

@end
