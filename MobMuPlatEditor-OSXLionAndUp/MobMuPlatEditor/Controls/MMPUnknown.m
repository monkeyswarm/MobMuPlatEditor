//
//  MMPUnknown.m
//  MobMuPlatEditor
//
//  Created by Daniel Iglesia on 1/12/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPUnknown.h"

@implementation MMPUnknown

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setWantsLayer:YES];
        self.layer.backgroundColor = [[NSColor darkGrayColor]CGColor];
        
        warningLabel = [[NSTextField alloc] initWithFrame:self.bounds];
        //[warningLabel setWantsLayer:YES];
       // [warningLabel alignCenter:nil];
        warningLabel.textColor = [NSColor whiteColor];
        //warningLabel.layer.backgroundColor = [NSColor darkGrayColor]];
        [warningLabel setEditable:NO];
       // warningLabel.numberOfLines = -1;
        //warningLabel.font = [UIFont systemFontOfSize:12];
        [warningLabel setBackgroundColor:[NSColor darkGrayColor]];
       [self addSubview:warningLabel];
        
        [self addHandles];
    }
    return self;
}

-(void)setBadName:(NSString*)badName{
    _badName = badName;
    [warningLabel setStringValue: [NSString stringWithFormat:@"interface object %@ not found", badName] ];
}

-(void)setFrame:(NSRect)frameRect{
    [super setFrame:frameRect];
    [warningLabel setFrame:self.bounds];
}

//copy/paste
- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.badName forKey:@"badName"];
	[coder encodeObject:self.badGUIDict forKey:@"badGUIDict"];
  
}

- (id)initWithCoder:(NSCoder *)coder {
  if(self=[super initWithCoder:coder]){
    [self setBadName:[coder decodeObjectForKey:@"badName"]];
    [self setBadGUIDict:[coder decodeObjectForKey:@"badGUIDict"]];
  }
  return self;
}


@end
