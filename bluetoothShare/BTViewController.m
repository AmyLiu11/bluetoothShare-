//
//  BTViewController.m
//  bluetoothShare
//
//  Created by wu on 12-9-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "BTViewController.h"

#define packetsize 8192

NSString* const ACFileTransferFileSentNotification = @"ACFileTransferFileSent";
NSString* const ACFileTransferFileBeganNotification = @"ACFileTransferFileBegan";
NSString* const ACFileTransferFileReceivedNotification = @"ACFileTransferFileReceived";
NSString* const ACFileTransferFileFailedNotification = @"ACFileTransferFileFailed";
NSString* const ACFileTransferPacketSentNotification = @"ACFileTransferPacketSent";
NSString* const ACFileTransferPacketReceivedNotification = @"ACFileTransferPacketReceived";
NSString* const ACFileTransferPacketFailedNotification = @"ACFileTransferPacketFailed";
NSString* const ACFileTransferAvailabilityChangedNotification = @"ACFileTransferAvailabilityChanged";
NSString* const ACFileTransferUpdatedPeersNotification = @"ACFileTransferUpdatedPeers";


typedef enum {
	kServer,
	kClient
}network;

typedef enum {
    kStateStart,
    kStateTransfering,
    kStateFinished
}states;

typedef enum{
    kPacketAlert,
    kPacketData
}packetType;


@interface BTViewController ()
@end

@implementation BTViewController
@synthesize currentSession;
@synthesize alertView;
@synthesize peerStatus;
@synthesize shareStatus;
@synthesize transferAlert;
@synthesize receiveAlert;
@synthesize sharePeerId;
@synthesize contents;
@synthesize packets;
@synthesize fileName;
@synthesize packetIndex;
@synthesize videoWriteHandle;
@synthesize moviePlayer;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // Listen for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileSent:) name:ACFileTransferFileSentNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileBegan:) name:ACFileTransferFileBeganNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileReceived:) name:ACFileTransferFileReceivedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePacketSent:) name:ACFileTransferPacketSentNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePacketReceived:) name:ACFileTransferPacketReceivedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileFailed:) name:ACFileTransferFileFailedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePacketFailed:) name:ACFileTransferPacketFailedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdatedPeers:) name:ACFileTransferUpdatedPeersNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAvailabilityChanged:) name:ACFileTransferAvailabilityChangedNotification object:self];
    
    assemblyLine = [[NSMutableDictionary alloc] init];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

-(NSString*)makeUUID {
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	NSString* uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
	[uuidString autorelease];
	CFRelease(uuid);
	return uuidString;
}

- (NSString *)downloadDirectory{
    return [[FileHelper getLibraryPath] stringByAppendingPathComponent:@"Caches/Media"];
}

-(void)disconnect {
	[self.currentSession disconnectFromAllPeers];
	[self.currentSession setDataReceiveHandler:nil withContext:nil];
}

- (IBAction)connectBtnPressed:(id)sender {
    self.shareStatus = kStateStart;
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"是否进行蓝牙传输？" message:@"视频信息" delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"连接", nil];
    self.alertView = alert;
    [alert show];
    [alert release];
}


-(void)startPick
{
    GKPeerPickerController * picker;
    picker = [[GKPeerPickerController alloc] init]; // note: picker is released in various picker delegate methods when picker use is done.
	picker.delegate = self;
    picker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
	[picker show];
}


- (void) alertView:(UIAlertView *)alertview   clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && self.shareStatus == kStateStart) {
        [self.alertView dismissWithClickedButtonIndex:1 animated:YES];
        [self startPick];
    }
    else if(buttonIndex == 1 && self.shareStatus == kStateTransfering)
    {
        if (self.peerStatus == kServer)
        {
            [NSThread detachNewThreadSelector:@selector(beginToSendData) toTarget:self withObject:nil];
        }
        else if (self.peerStatus == kClient)
        {
            NSLog(@"waiting data to come in......");
        }
    }
    else if (buttonIndex == 1 && self.shareStatus == kStateFinished&& self.peerStatus == kClient)
    {
        NSString * myFilePath = [NSString stringWithFormat:@"%@/%@/%@.mp4", [self downloadDirectory],@"k0011d8u52n" , @"k0011d8u52n"];
        NSString * dirPath = [NSString stringWithFormat:@"%@/%@", [self downloadDirectory],@"k0011d8u52n"];
        
        if ( ![FileHelper fileIsExistWithPath:myFilePath]) 
        {
            [FileHelper createDirWithPath:dirPath];
            [FileHelper createFileWithPath:myFilePath];
        }
        NSFileHandle * fileHandle  =  [NSFileHandle fileHandleForWritingAtPath:myFilePath];
        [fileHandle seekToEndOfFile];
        self.videoWriteHandle = fileHandle;
        NSData * videoData =  [[assemblyLine objectForKey:key]   objectForKey:@"data"];
        [self.videoWriteHandle writeData:videoData];
        NSLog(@"written %llu to disk ",[self.videoWriteHandle offsetInFile]);
        [assemblyLine removeObjectForKey:key];
        
        if ([FileHelper fileIsExistWithPath:myFilePath]) {
            self.moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:myFilePath]];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinishedCallback:)
                                                         name:MPMoviePlayerPlaybackDidFinishNotification
                                                       object:[self.moviePlayer moviePlayer]];
            
            [self.view addSubview:self.moviePlayer.view];
            
            MPMoviePlayerController *player = [self.moviePlayer moviePlayer];
            [player play];
        }
    }
}


-(void)movieFinishedCallback:(NSNotification*)aNotification{
    NSString * dirPath = [NSString stringWithFormat:@"%@/%@", [self downloadDirectory],@"k0011d8u52n"];
	MPMoviePlayerController *player = [aNotification object];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:player];
	[player stop];
    [player.view removeFromSuperview];
    [FileHelper  deleteDirWithPath:dirPath];
}


-(void)beginToSendData
{
    NSString * myFilePath = [NSString stringWithFormat:@"%@/%@/%@.mp4", [self downloadDirectory],@"k0011d8u52n" , @"k0011d8u52n"];
    self.contents = [NSMutableData dataWithContentsOfFile:myFilePath];
    self.fileName = @"k0011d8u52n";

    [self makePacketAndSendToPeer];
}



-(void)makePacketAndSendToPeer
{
    NSString * md5code = [self.contents md5];
    sendSize = 0;
    self.packetIndex = [NSNumber numberWithInt:0];
    NSMutableArray * pacArr = [NSMutableArray array];
    NSString* uuid = [self makeUUID];
    if(self.shareStatus == kStateTransfering)
    {
        while (fileSize > packetsize) 
        {
            NSInteger packIndex = [self.packetIndex intValue];
            packIndex++;
            self.packetIndex = [NSNumber numberWithInt:packIndex];
            NSRange range = NSMakeRange(sendSize, packetsize);
            NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
                               self.packetIndex,@"index",
                               uuid, @"uuid",
                               md5code, @"md5",
                               self.fileName, @"filename",
                               [self.contents subdataWithRange:range], @"data",
                               [NSNumber numberWithInt:self.contents.length], @"total",
                               [NSNumber numberWithInt:range.location], @"start",
                               [NSNumber numberWithInt:range.length], @"length", nil];
            NSData* packet = [NSPropertyListSerialization dataWithPropertyList:d format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
            [pacArr addObject:packet];
            fileSize -= packetsize;
            sendSize += packetsize;
        }
        NSInteger packIndex = [self.packetIndex intValue];
        packIndex++;
        self.packetIndex = [NSNumber numberWithInt:packIndex];
        NSRange range = NSMakeRange(sendSize, fileSize);
        NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
                           self.packetIndex,@"index",
                           uuid, @"uuid",
                           md5code, @"md5",
                           self.fileName, @"filename",
                           [self.contents subdataWithRange:range], @"data",
                           [NSNumber numberWithInt:self.contents.length], @"total",
                           [NSNumber numberWithInt:range.location], @"start",
                           [NSNumber numberWithInt:range.length], @"length", nil];
        NSData* packet = [NSPropertyListSerialization dataWithPropertyList:d format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
        [pacArr addObject:packet];
        self.packets = [NSArray arrayWithArray:pacArr];
        
        [self sendNetworkPacket:self.currentSession packetID:kPacketData withPacketArr:self.packets];
    }
}



#pragma mark GKPeerPickerControllerDelegate Methods


- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type {
	GKSession *session = [[GKSession alloc] initWithSessionID:@"bluetoothShare" displayName:nil sessionMode:GKSessionModePeer]; //displayname is device name
	return [session autorelease]; // peer picker retains a reference, so autorelease ours so we don't leak.
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session
{
    self.sharePeerId = peerID;
    
	self.currentSession = session; // retain
	self.currentSession.delegate = self;
    self.currentSession.available = YES;
	[self.currentSession setDataReceiveHandler:self withContext:NULL];
	
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
	[picker autorelease];
}

- (void)invalidateSession:(GKSession *)session {
	if(session != nil) {
		[session disconnectFromAllPeers];
		session.available = NO;
		[session setDataReceiveHandler: nil withContext: NULL];
		session.delegate = nil;
	}
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker {
	// Peer Picker automatically dismisses on user cancel. No need to programmatically dismiss.
    
	// autorelease the picker.
	picker.delegate = nil;
    [picker autorelease];
	
	// invalidate and release game session if one is around.
	if(self.currentSession != nil)	{
		[self invalidateSession:self.currentSession];
		self.currentSession = nil;
	}
	
}

#pragma mark GKSessionDelegate Methods

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    self.alertView = nil;
    NSString *message = [NSString stringWithFormat:@"无法与 %@ 建立连接", [session displayNameForPeer:peerID]];
    if (state == GKPeerStateDisconnected) {
      /*  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"失去连接" message:message delegate:self cancelButtonTitle:@"退出" otherButtonTitles:nil];
        self.alertView = alert;
        [alert show];
        [alert release];*/
        [[JBInfoBarManager sharedManager] initInfoBarWithFrame:CGRectMake(0, 460, 320, 20)];
        [self.view addSubview:[[JBInfoBarManager sharedManager] infoBar]];
        [[JBInfoBarManager sharedManager]  showInfoBarWithMessage:message];  
        [NSTimer scheduledTimerWithTimeInterval:5.0 target:[JBInfoBarManager sharedManager] selector:@selector(hideInfoBar) userInfo:nil repeats:NO];
    }
    else if(state == GKPeerStateConnected)
    {
        [[JBInfoBarManager sharedManager] initInfoBarWithFrame:CGRectMake(0, 460, 320, 20)];
        [self.view addSubview:[[JBInfoBarManager sharedManager] infoBar]];
        [[JBInfoBarManager sharedManager]  showInfoBarWithMessage:@"connected!"];
        [NSTimer scheduledTimerWithTimeInterval:5.0 target:[JBInfoBarManager sharedManager] selector:@selector(hideInfoBar) userInfo:nil repeats:NO];
        
        NSString * myFilePath = [NSString stringWithFormat:@"%@/%@/%@.mp4", [self downloadDirectory],@"k0011d8u52n" , @"k0011d8u52n"];
        self.shareStatus = kStateTransfering;
        self.peerStatus = kServer;
        if ([FileHelper fileIsExistWithPath:myFilePath]) {
            self.peerStatus = kServer;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"已连接" message:@"开始传输数据?" delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"传输",nil];
            self.alertView = alert;
            [alert show];
            [alert release];
        }
        else
        {
            self.shareStatus = kStateTransfering;
            self.peerStatus = kClient;
        }
    }
}

#pragma mark Data Send/Receive Methods

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context
{
    if(self.shareStatus == kStateTransfering && self.peerStatus == kClient)
    { 
        NSDictionary* packet = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:nil];
        if(packet == nil) { return; }
        
        // Notify that we received a packet
        [[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferPacketReceivedNotification object:self userInfo:packet];
        
        key = [NSString stringWithFormat:@"%@_%@", peer, [packet objectForKey:@"uuid"]];
        
        NSMutableDictionary* received = [assemblyLine objectForKey:key];
        if(received == nil) {
            int size = [[packet objectForKey:@"total"] intValue];
            NSMutableData* data = [NSMutableData dataWithCapacity:size];
            data.length = size;
            received = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        peer, @"peer",
                        [packet objectForKey:@"md5"], @"md5",
                        [packet objectForKey:@"uuid"], @"uuid",
                        [packet objectForKey:@"filename"], @"filename",
                        [NSNumber numberWithInt:0], @"bytes",
                        data, @"data", nil];
            [assemblyLine setObject:received forKey:key];
            [[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferFileBeganNotification object:self userInfo:received];
        }
        [[received objectForKey:@"data"] replaceBytesInRange:NSMakeRange([[packet objectForKey:@"start"] intValue], [[packet objectForKey:@"length"] intValue]) withBytes:[(NSData*)[packet objectForKey:@"data"] bytes]];
        
        totalBytes = [[received objectForKey:@"bytes"] intValue] + [[packet objectForKey:@"length"] intValue];
        [received setObject:[[NSNumber numberWithInt:totalBytes] copy] forKey:@"bytes"];
        NSLog(@"Received %d of %d bytes", totalBytes, [[packet objectForKey:@"total"] intValue]);
        
        [assemblyLine setObject:received forKey:key];
        
        [self performSelectorOnMainThread:@selector(updateReceiveProgress:) withObject:packet waitUntilDone:YES];
        
        if(totalBytes >= [[packet objectForKey:@"total"] intValue]) {
            
            // Check to make sure the data was received properly
            if([[packet objectForKey:@"md5"] isEqualToString:[[received objectForKey:@"data"] md5]]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferFileReceivedNotification object:self userInfo:received];
                self.shareStatus = kStateFinished;
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferFileFailedNotification object:self userInfo:received];
            }
          
        }
    }
}



-(void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withPacketArr:(NSArray*)packetsArr 
{
    if (self.shareStatus == kStateTransfering && self.peerStatus == kServer)
    {
        for (NSData *packet in packetsArr) 
        {
            NSDictionary* packetD = [NSPropertyListSerialization propertyListWithData:packet options:0 format:NULL error:nil];
            NSError * error = nil;
            [self.currentSession sendData:packet toPeers:[NSArray arrayWithObject:self.sharePeerId] withDataMode:GKSendDataReliable error:&error];
            if(error != nil) 
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferPacketFailedNotification object:self userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
            } 
            else 
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferPacketSentNotification object:self];
                [self performSelectorOnMainThread:@selector(updateTransferProgress:) withObject:packetD waitUntilDone:YES];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferFileSentNotification object:self];
    }
}

- (void)updateTransferProgress:(NSDictionary*)infoDic
{
    NSString * mes = [NSString stringWithFormat:@"size:%d",[(NSNumber*)[infoDic objectForKey:@"total"] intValue]];
    fileSize = [[infoDic objectForKey:@"total"] intValue];
    double  pNum = ((float)fileSize / (float)packetsize);
    NSNumber* numberOfPackets = [NSNumber numberWithInt:(int)ceil(pNum)];
    if (self.peerStatus == kServer && self.shareStatus == kStateTransfering) 
    {
        if (!self.transferAlert) {
            self.transferAlert = [[AGAlertViewWithProgressbar alloc] initWithTitle:@"正在发送" message: mes   delegate:self cancelButtonTitle:@"中止" otherButtonTitles:nil];
            [self.transferAlert show];
        }
        [self.transferAlert setProgress:[(NSNumber*)[infoDic objectForKey:@"index"] intValue]  withRange:[numberOfPackets intValue]];       
        if (self.transferAlert.progress == [numberOfPackets intValue])
        {
            [self.transferAlert hide];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"传输完成" message:@"视频信息" delegate:self cancelButtonTitle:@"退出" otherButtonTitles:nil];
            self.transferAlert = nil;
            transferAlert = nil;
            [alert show];
            [alert release];
        }
    }
}


- (void)updateReceiveProgress:(NSDictionary*)infoDic{
    if(self.peerStatus == kClient && self.shareStatus == kStateTransfering)
    {
        int totalSize = [[infoDic objectForKey:@"total"] intValue];
        double  pNum = ((float)totalSize / (float)packetsize);
        NSNumber* numberOfPackets = [NSNumber numberWithInt:(int)ceil(pNum)];
        NSString * mes = [NSString stringWithFormat:@"size:%d",totalSize];
        if (!self.receiveAlert) {
            self.receiveAlert = [[AGAlertViewWithProgressbar alloc] initWithTitle:@"正在接收" message: mes delegate:self cancelButtonTitle:@"中止" otherButtonTitles:nil];
            [self.receiveAlert show];
        }
        int packetTime = [(NSNumber*)[infoDic objectForKey:@"index"] intValue];
        [self.receiveAlert setProgress: packetTime   withRange: [numberOfPackets intValue]];
        if (self.receiveAlert.progress == [numberOfPackets intValue])
        {
            self.shareStatus = kStateFinished;
            [self.receiveAlert hide];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"接收完成" message:@"视频信息" delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"打开",nil];
            self.receiveAlert = nil;
            [receiveAlert release];
            self.alertView = alert;
            [alert show];
            [alert release];
        }
    }
}

#pragma mark -
#pragma mark Handle Notifications

-(void)handleFileSent:(NSNotification*)notification {
    NSLog(@"File Sent %@\n", self.fileName); 
}

-(void)handleFileBegan:(NSNotification*)notification {
    NSLog(@"File Began\n"); 
}

-(void)handleFileReceived:(NSNotification*)notification {
    NSLog(@"File Received\n"); 
}

-(void)handleFileFailed:(NSNotification*)notification {
	NSLog(@"File Failed\n"); 
}

-(void)handlePacketSent:(NSNotification*)notification {
	NSLog(@"Packet Sent\n"); 
}

-(void)handlePacketReceived:(NSNotification*)notification {
	NSLog(@"Packet Received\n"); 
}

-(void)handlePacketFailed:(NSNotification*)notification {
    NSLog(@"Packet Failed\n"); 
}



-(void)dealloc
{
    self.currentSession = nil;
    self.alertView = nil;
    self.contents = nil;
    self.packets = nil;
    self.fileName = nil;
    self.packetIndex = nil;
    self.videoWriteHandle = nil;
    self.moviePlayer = nil;
    [currentSession release];
    [alertView release];
    [contents release];
    [packets release];
    [fileName release];
    [packetIndex release];
    [videoWriteHandle release];
    [moviePlayer release];
    
    [super dealloc];
}

@end

@implementation NSData (MD5)
-(NSString*)md5 {
    unsigned char result[16];
    CC_MD5(self.bytes, self.length, result);
    return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];
}

@end



