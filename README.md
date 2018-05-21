#Classic Macintosh Bitmap Typography

This is a small set of Objective-C classes that can be used for parsing font data from the original Macintosh,
and for simple rendering of bitmap text using those fonts. 

This work formed the basis of [the article here](https://medium.com/@bzotto/hidden-sheep-and-mac-typography-archaeology-efce770da76c).

The `BitmapFont` class does the parsing into a usable object, and `SimpleBitmapRenderer` can use that to put some text on a canvas.

*NB*: This code is reasonably durable but was create to facilitate an academic exercise. 
It was not designed or written with performance or security concerns in mind, and if 
you want to use it for anything other than hacking on, please revise it accordingly.

###Usage

	// Load FONT resource containing Chicago:
	NSData * data = [NSData dataWithContentsOfFile:@"00012"]; 
	BitmapFont * font = [BitmapFont fontFromResourceData:data withResourceIdString:@"00012"];

	// Create a renderer
	SimpleBitmapRenderer * renderer = [[SimpleBitmapRenderer alloc] initWithSize:UIntSizeMake(300, 200)];

	// Write some text
	NSString * text = @"Hello.";
	[renderer renderString:text.macRomanString atOrigin:UIntPointMake(20, 20)];

	// Get a PNG out of it
	NSData * pngData = [renderer bitmapImageAsPNGDataWithScale:15 showingGrid:YES];
