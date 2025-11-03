#import "BMWToneCurveFile.h"

@interface BMWToneCurveFile ()

@property (nonatomic, assign) short version;
@property (nonatomic, assign) short totalCurves;
@property (nonatomic, strong) NSArray *rgbCompositeCurvePoints;
@property (nonatomic, strong) NSArray *redCurvePoints;
@property (nonatomic, strong) NSArray *greenCurvePoints;
@property (nonatomic, strong) NSArray *blueCurvePoints;
@end

@implementation BMWToneCurveFile

- (id)initWithXHToneCurveFileData:(NSData *)data
{
    self = [super init];
    if (self != nil) {
        if (data.length == 0) {
                        return self;
        }

        Byte* rawBytes = (Byte*) [data bytes];
        _version = int16WithBytes(rawBytes);
        rawBytes += 2;

        _totalCurves = int16WithBytes(rawBytes);
        rawBytes += 2;

        NSMutableArray *curves = [NSMutableArray new];

        float pointRate = (1.0 / 255);
        // The following is the data for each curve specified by count above
        for (NSInteger x = 0; x < _totalCurves; x++)
        {
            unsigned short pointCount = int16WithBytes(rawBytes);
            rawBytes += 2;

            NSMutableArray *points = [NSMutableArray new];
            // point count * 4
            // Curve points. Each curve point is a pair of short integers where
            // the first number is the output value (vertical coordinate on the
            // Curves dialog graph) and the second is the input value. All coordinates have range 0 to 255.
            for (NSInteger y = 0; y < pointCount; y++)
            {
                unsigned short y = int16WithBytes(rawBytes);
                rawBytes += 2;
                unsigned short x = int16WithBytes(rawBytes);
                rawBytes += 2;
                [points addObject:[NSValue valueWithCGSize:CGSizeMake(x * pointRate, y * pointRate)]];
            }
            [curves addObject:points];
        }
        self.rgbCompositeCurvePoints = [curves objectAtIndex:0];
        self.redCurvePoints = [curves objectAtIndex:1];
        self.greenCurvePoints = [curves objectAtIndex:2];
        self.blueCurvePoints = [curves objectAtIndex:3];
    }
    return self;
}

unsigned short int16WithBytes(Byte* bytes)
{
    uint16_t result;
    memcpy(&result, bytes, sizeof(result));
    return CFSwapInt16BigToHost(result);
}

@end
