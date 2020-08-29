//
//  Parser.m
//  oc2mangoLib
//
//  Created by Jiang on 2019/4/24.
//  Copyright © 2019年 SilverFruity. All rights reserved.
//

#import "Parser.h"
#import "RunnerClasses.h"
@implementation CodeSource
- (instancetype)initWithFilePath:(NSString *)filePath{
    self = [super init];
    self.filePath = filePath;
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    self.source = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return self;
}
- (instancetype)initWithSource:(NSString *)source{
    self = [super init];
    self.source = source;
    return self;
}
@end
@implementation Parser

+ (instancetype)shared{
    static dispatch_once_t onceToken;
    static Parser * _instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [Parser new];
    });
    return _instance;
}
- (BOOL)isSuccess{
    return self.source && self.error == nil;
}
- (AST *)parseCodeSource:(CodeSource *)source{
    if (source.source == nil) {
        return nil;
    }
    self.error = nil;
    GlobalAst = [AST new];
    extern void yy_set_source_string(char const *source);
    extern void yyrestart (FILE * input_file );
    extern int yyparse(void);
    self.source = source;
    yy_set_source_string([source.source UTF8String]);
    if (yyparse()) {
        yyrestart(NULL);
        NSLog(@"\n----Error: \n  PATH: %@\n  INFO:%@",self.source.filePath,self.error);
    }
//#define ARCHIVE_TEST
#ifdef ARCHIVE_TEST
    NSString *filePath = @"/Users/jiang/Downloads/OCRunner/oc2mango/oc2mango/Output/BinaryPatch.txt";
    NSData *data = nil;
    uint32_t cursor = 0;
    ORPatchFile *file = [ORPatchFile new];
    _PatchNode *node = nil;

    file.nodes = GlobalAst.nodes;
    node = _PatchNodeConvert(file);

    //Serialization
    //TODO: 压缩，_ORNode结构体中不包含length字段.
    //TODO: 压缩，_ORNode结构体中不包含length字段.
    void *buffer = malloc(node->length);
    _PatchNodeSerialization(node, buffer, &cursor);
    data = [[NSData alloc] initWithBytes:buffer length:node->length];
    [data writeToFile:filePath atomically:NO];

    //Deserialization
    data = [[NSData alloc] initWithContentsOfFile:filePath];
    buffer = (void *)data.bytes;
    cursor = 0;
    node = _PatchNodeDeserialization(buffer, &cursor, node->length);

    file = _PatchNodeDeConvert(node);
    
    GlobalAst = [AST new];
    [GlobalAst merge:file.nodes];
#endif
    return GlobalAst;
}
- (AST *)parseSource:(NSString *)source{
    return [self parseCodeSource:[[CodeSource alloc] initWithSource:source]];
}

@end
