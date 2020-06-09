#import <IconImageProcessing.h>

// TODO: Loop over all pixels, add to map with count of that color. Color should be within range X of another color for it to not be a new color
// Pick top 3 and pick the one with the highest saturation

@implementation UIImage (AppSort13)
-(uint)hue {
	CIImage* img = [[CIImage alloc] initWithImage: self];
	CIVector* extentVector = [CIVector
		vectorWithX:img.extent.origin.x
		Y:img.extent.origin.y
		Z:img.extent.size.width
		W:img.extent.size.height];

	CIFilter* filter = [CIFilter
		filterWithName:@"CIAreaMaximumAlpha" // CIAreaAverage CIAreaMaximum
		withInputParameters: @{
			@"inputImage": img,
			@"inputExtent": extentVector
		}];
	
	CIImage* outputImg = filter.outputImage;

	uint8_t rgba[4] = { 0, 0, 0, 0 };
	CIContext* context = [CIContext contextWithOptions:@{
		@"kCIContextWorkingColorSpace": [NSNull null]
	}];
	struct CGRect bounds;
	bounds.origin.x = 0;
	bounds.origin.y = 0;
	bounds.size.width = 1;
	bounds.size.height = 1;
	[context render:outputImg
		toBitmap:&rgba
		rowBytes:4
		bounds:bounds
		format:kCIFormatRGBA8
		colorSpace: nil];

	uint r = (uint) rgba[0];
	uint g = (uint) rgba[1];
	uint b = (uint) rgba[2];

	return [UIImage computeR:r G:g B:b];
}
+(uint)computeR:(uint8_t)R G:(uint8_t)G B:(uint8_t)B {
	uint result = 0;

	result += (R << 16);
	result += (G << 8);
	result += B;

	return result / (R+G+B);
}
@end