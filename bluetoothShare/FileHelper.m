//
//  FileHelper.m
//  QQMusicForIphoneDemo
//
//  Created by jordenwu-Mac on 10-8-20.
//  Copyright 2010 tencent.com. All rights reserved.
//
#import "FileHelper.h"

@implementation FileHelper
@synthesize fileManager;

static FileHelper *shareFileHelperInstance = nil;
+(FileHelper*)shareFileHelper 
{
	@synchronized(self){
		if (shareFileHelperInstance == nil) {
			shareFileHelperInstance = [[FileHelper alloc] init];
		}
	}
	return shareFileHelperInstance;
}

-(void) dealloc
{
	[fileManager release];
	[super dealloc];
}

-(NSFileManager *) fileManager
{
	if(fileManager == nil)
	{
		fileManager = [[NSFileManager alloc]init];
	}
	return fileManager;
}

+(NSString*)getFullFilePath:(NSString*)filePath
{
	return [[FileHelper getDocumentsPath] stringByAppendingPathComponent:filePath];
}

//文件是否存在
+(BOOL)fileIsExistWithPath:(NSString *)filePath
{
	return [[FileHelper shareFileHelper].fileManager fileExistsAtPath:filePath];
}
//创建单一文件
+(BOOL)createFileWithPath:(NSString *)filePath
{
	return [[FileHelper shareFileHelper].fileManager createFileAtPath:filePath contents:nil attributes:nil];
}
//删除单一文件
+(BOOL)deleteFileWithPath:(NSString *)filePath
{
	return [[FileHelper shareFileHelper].fileManager removeItemAtPath:filePath error:NULL];
}
//创建目录
+(BOOL)createDirWithPath:(NSString *)dirPath
{   
	return [[FileHelper shareFileHelper].fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
}
// 目录是否存在
+(BOOL)dirIsExistWithPath:(NSString *)dirPath
{   
	BOOL isDir=YES;
	return [[FileHelper shareFileHelper].fileManager fileExistsAtPath:dirPath isDirectory:&isDir];
}
// 删除目录
+(BOOL)deleteDirWithPath:(NSString *)dirPath
{  
	return [[FileHelper shareFileHelper].fileManager removeItemAtPath:dirPath error:NULL];
}

// 获得程序目录的Documents目录路径
+(NSString *)getDocumentsPath
{   
	NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return (NSString *)[paths objectAtIndex:0];
}
// 获得程序目录的Library目录路径
+(NSString *)getLibraryPath
{   
	NSArray *paths=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);	
	return (NSString *)[paths objectAtIndex:0];
}
// 获得程序临时目录路径
+(NSString *)getTmpPath
{   
	NSString *path=NSTemporaryDirectory();
	return path;
}

+(unsigned long long)getFileSizeWithPath:(NSString*)filePath
{
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
	return (unsigned long long)[[attributes objectForKey:NSFileSize] unsignedLongLongValue];
}

+(unsigned long long)getFileSystemFreeSize{
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSTemporaryDirectory() error:nil];
	return (unsigned long long)[[attributes objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
}

+(void)moveFile:(NSString*)file ToNewFile:(NSString*)newFile
{
	[[FileHelper shareFileHelper].fileManager moveItemAtPath:file toPath:newFile error:nil];
}

+(void)copyFile:(NSString*)file ToNewFile:(NSString*)newFile
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	[[FileHelper shareFileHelper].fileManager copyItemAtPath:file toPath:newFile error:nil];
	[pool release];
}
@end
