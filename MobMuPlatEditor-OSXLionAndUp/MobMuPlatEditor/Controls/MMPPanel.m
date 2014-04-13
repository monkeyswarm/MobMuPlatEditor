//
//  MMPPanel.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 1/4/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//

#import "MMPPanel.h"

@implementation MMPPanel

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.address=@"/myPanel";
                
        imageView = [[NSImageView alloc]init];
        [imageView setWantsLayer:YES];
        [imageView setImageScaling:NSScaleToFit];
        [self addSubview:imageView];
        
        //if we try to load an image and it isn't found, show this
        textField = [[NSTextField alloc]initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        textField.backgroundColor=[NSColor clearColor];
        [textField setEditable:NO];
        [textField setBordered:NO];
        [textField setStringValue:@"file not found"];
        [textField setHidden:YES];
        [imageView addSubview:textField];
        
        
        [self setColor:self.color];
        [self setFrame:frame];
        [self addHandles];
    }
    
    return self;
}

-(void)setImagePath:(NSString*)imagePath{
    _imagePath=imagePath;//could be relative OR absolute
   //this is called on startup/load before there is a fileURL, so wait to actually change image!
}

-(void)loadImage{
    [self changeImage:_imagePath];
}

-(void)changeImage:(NSString*)newImagePath{
    //printf("\n change image, file path = %s, filename: %s",[[[self.editingDelegate fileURL] path] cString], [_imagePath cString] );
    NSString* constructedRelativePath = [[[[self.editingDelegate fileURL] path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:newImagePath];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:newImagePath]){
        [imageView setImage:[[NSImage alloc]initWithContentsOfFile:newImagePath] ];
        textField.hidden=YES;
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:constructedRelativePath]){
        [imageView setImage:[[NSImage alloc]initWithContentsOfFile:constructedRelativePath] ];
        textField.hidden=YES;
    }
    
    else{
        [imageView setImage:nil];
        textField.hidden=NO;
    }

}

-(void)setFrame:(NSRect)frameRect{
    [super setFrame:frameRect];
    [imageView setFrameSize:CGSizeMake(frameRect.size.width, frameRect.size.height)];
    [textField setFrameSize:CGSizeMake(frameRect.size.width, frameRect.size.height)];
}

-(void)setColor:(NSColor *)color{
    [super setColor:color];
    imageView.layer.backgroundColor=[MMPControl CGColorFromNSColor:color];
}


-(void)setShouldPassTouchesUndoable:(NSNumber*)inVal{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setShouldPassTouchesUndoable:) object:[NSNumber numberWithBool:self.shouldPassTouches]];
  [self setShouldPassTouches:[inVal boolValue]];
}

//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
//it does not respond to "set" anything
-(void)receiveList:(NSArray *)inArray{
    //new image
    if([inArray count]==2 &&[[inArray objectAtIndex:0] isEqualToString:@"image"]  ){
        [self changeImage:[inArray objectAtIndex:1]];
    }
    //turn highlight color on or off with "highlight 0/1"
    else if([inArray count]==2 &&[[inArray objectAtIndex:0] isEqualToString:@"highlight"]){
        int val = [[inArray objectAtIndex:1] intValue];//0,1
        if(val>0)imageView.layer.backgroundColor=[MMPControl CGColorFromNSColor:self.highlightColor];
        else imageView.layer.backgroundColor=[MMPControl CGColorFromNSColor:self.color];
    }
}

//coder for copy/paste

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    if(self.imagePath)[coder encodeObject:self.imagePath forKey:@"imagePath"];
  [coder encodeObject:[NSNumber numberWithBool:self.shouldPassTouches] forKey:@"passTouches"];
}

- (id)initWithCoder:(NSCoder *)coder {
    
    if(self=[super initWithCoder:coder]){
        if([coder decodeObjectForKey:@"imagePath"]){
            [self setImagePath:[coder decodeObjectForKey:@"imagePath"]];
            [self loadImage];
        }
      self.shouldPassTouches = [[coder decodeObjectForKey:@"passTouches"] boolValue];
      
    }
    return self;
}


@end
