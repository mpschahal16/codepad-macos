#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodePadScintillaView : NSView
@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy) NSString *lexerName;
@property(nonatomic, copy) NSArray<NSString *> *keywordSets;
@property(nonatomic, copy, nullable) void (^onChange)(NSString *text, NSInteger line, NSInteger column, BOOL modified);
- (void)selectRange:(NSRange)range;
- (NSRange)selection;
- (void)find:(NSString *)query backwards:(BOOL)backwards;
@end

NS_ASSUME_NONNULL_END
