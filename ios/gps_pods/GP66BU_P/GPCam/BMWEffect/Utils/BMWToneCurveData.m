#import "BMWToneCurveData.h"
#import "BMWToneCurveFile.h"
#import "BMWGLUtils.h"

@interface BMWToneCurveData()
{
    GLuint toneCurveTexture;
    GLubyte *toneCurveByteArray;
    NSArray *_redCurve, *_greenCurve, *_blueCurve, *_rgbCompositeCurve;
}

@property(readwrite, nonatomic, copy) NSArray *redControlPoints;
@property(readwrite, nonatomic, copy) NSArray *greenControlPoints;
@property(readwrite, nonatomic, copy) NSArray *blueControlPoints;
@property(readwrite, nonatomic, copy) NSArray *rgbCompositeControlPoints;

@end

@implementation BMWToneCurveData

@synthesize rgbCompositeControlPoints = _rgbCompositeControlPoints;
@synthesize redControlPoints = _redControlPoints;
@synthesize greenControlPoints = _greenControlPoints;
@synthesize blueControlPoints = _blueControlPoints;

- (void)dealloc
{
    if (toneCurveByteArray) {
        free(toneCurveByteArray);
    }
    BMWMLogD(@"GPCam", @"BMWToneCurveData dealloc");
}

- (id)initWithACVData:(NSData *)data
{
    if (!(self = [super init])) {
        return nil;
    }
    toneCurveByteArray = calloc(256 * 4, sizeof(GLubyte));

    BMWToneCurveFile* curve = [[BMWToneCurveFile alloc] initWithXHToneCurveFileData:data];
    
    [self setRgbCompositeControlPoints:curve.rgbCompositeCurvePoints];
    [self setRedControlPoints:curve.redCurvePoints];
    [self setGreenControlPoints:curve.greenCurvePoints];
    [self setBlueControlPoints:curve.blueCurvePoints];
        
    return self;
}

- (GLubyte *)textureData{
    return toneCurveByteArray;
}

- (id)initWithName:(NSString*)curveFilename
{
   NSString *bundlePath = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"CCameraLib.bundle/acv"];
    NSString *filePath = [bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.acv",curveFilename]];

    return [self initWithACVURL:[NSURL fileURLWithPath:filePath]];
}

- (id)initWithACVURL:(NSURL*)curveFileURL
{
    NSData* fileData = [NSData dataWithContentsOfURL:curveFileURL];
    return [self initWithACVData:fileData];
}

- (void)setRgbCompositeControlPoints:(NSArray *)newValue
{
    _rgbCompositeControlPoints = [newValue copy];
    _rgbCompositeCurve = [self getPreparedSplineCurve:_rgbCompositeControlPoints];
    
    [self updateToneCurveTexture];
}

- (void)setRedControlPoints:(NSArray *)newValue;
{
    _redControlPoints = [newValue copy];
    _redCurve = [self getPreparedSplineCurve:_redControlPoints];
    
    [self updateToneCurveTexture];
}

- (void)setGreenControlPoints:(NSArray *)newValue
{
    _greenControlPoints = [newValue copy];
    _greenCurve = [self getPreparedSplineCurve:_greenControlPoints];
    
    [self updateToneCurveTexture];
}

- (void)setBlueControlPoints:(NSArray *)newValue
{
    _blueControlPoints = [newValue copy];
    _blueCurve = [self getPreparedSplineCurve:_blueControlPoints];
    
    [self updateToneCurveTexture];
}

#pragma mark Curve calculation

- (NSArray *)getPreparedSplineCurve:(NSArray *)points
{
    if (points && [points count] > 0)
    {
        // Sort the array.
        NSArray *sortedPoints = [points sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            float x1 = [(NSValue *)a CGPointValue].x;
            float x2 = [(NSValue *)b CGPointValue].x;
            return x1 > x2;
        }];
        
        // Convert from (0, 1) to (0, 255).
        NSMutableArray *convertedPoints = [NSMutableArray arrayWithCapacity:[sortedPoints count]];
        for (int i=0; i<[points count]; i++) {
            CGPoint point = [[sortedPoints objectAtIndex:i] CGPointValue];
            point.x = point.x * 255;
            point.y = point.y * 255;
            [convertedPoints addObject:[NSValue valueWithCGPoint:point]];
        }
        
        
        NSMutableArray *splinePoints = [self splineCurve:convertedPoints];
        
        // If we have a first point like (0.3, 0) we'll be missing some points at the beginning
        // that should be 0.
        CGPoint firstSplinePoint = [[splinePoints objectAtIndex:0] CGPointValue];
        
        if (firstSplinePoint.x > 0) {
            for (int i=firstSplinePoint.x; i >= 0; i--) {
                CGPoint newCGPoint = CGPointMake(i, 0);
                [splinePoints insertObject:[NSValue valueWithCGPoint:newCGPoint] atIndex:0];
            }
        }
        
        // Insert points similarly at the end, if necessary.
        CGPoint lastSplinePoint = [[splinePoints lastObject] CGPointValue];
        
        if (lastSplinePoint.x < 255) {
            for (int i = lastSplinePoint.x + 1; i <= 255; i++) {
                CGPoint newCGPoint = CGPointMake(i, 255);
                [splinePoints addObject:[NSValue valueWithCGPoint:newCGPoint]];
            }
        }
        
        // Prepare the spline points.
        NSMutableArray *preparedSplinePoints = [NSMutableArray arrayWithCapacity:[splinePoints count]];
        for (int i=0; i<[splinePoints count]; i++)
        {
            CGPoint newPoint = [[splinePoints objectAtIndex:i] CGPointValue];
            CGPoint origPoint = CGPointMake(newPoint.x, newPoint.x);
            
            float distance = sqrt(pow((origPoint.x - newPoint.x), 2.0) + pow((origPoint.y - newPoint.y), 2.0));
            
            if (origPoint.y > newPoint.y)
            {
                distance = -distance;
            }
            
            [preparedSplinePoints addObject:[NSNumber numberWithFloat:distance]];
        }
        
        return preparedSplinePoints;
    }
    
    return nil;
}


- (NSMutableArray *)splineCurve:(NSArray *)points
{
    NSMutableArray *sdA = [self secondDerivative:points];
    
    // [points count] is equal to [sdA count]
    NSInteger n = [sdA count];
    if (n < 1)
    {
        return nil;
    }
    double sd[n];
    
    // From NSMutableArray to sd[n];
    for (int i=0; i<n; i++)
    {
        sd[i] = [[sdA objectAtIndex:i] doubleValue];
    }
    
    
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:(n+1)];
    
    for(int i=0; i<n-1 ; i++)
    {
        CGPoint cur = [[points objectAtIndex:i] CGPointValue];
        CGPoint next = [[points objectAtIndex:(i+1)] CGPointValue];
        
        for(int x=cur.x;x<(int)next.x;x++)
        {
            double t = (double)(x-cur.x)/(next.x-cur.x);
            
            double a = 1-t;
            double b = t;
            double h = next.x-cur.x;
            
            double y= a*cur.y + b*next.y + (h*h/6)*( (a*a*a-a)*sd[i]+ (b*b*b-b)*sd[i+1] );
            
            if (y > 255.0)
            {
                y = 255.0;
            }
            else if (y < 0.0)
            {
                y = 0.0;
            }
            [output addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        }
    }
    
    // The above always misses the last point because the last point is the last next, so we approach but don't equal it.
    [output addObject:[points lastObject]];
    return output;
}

- (NSMutableArray *)secondDerivative:(NSArray *)points
{
    const NSInteger n = [points count];
    if ((n <= 0) || (n == 1))
    {
        return nil;
    }
    
    double matrix[n][3];
    double result[n];
    matrix[0][1]=1;
    // What about matrix[0][1] and matrix[0][0]? Assuming 0 for now (Brad L.)
    matrix[0][0]=0;
    matrix[0][2]=0;
    
    for(int i=1;i<n-1;i++)
    {
        CGPoint P1 = [[points objectAtIndex:(i-1)] CGPointValue];
        CGPoint P2 = [[points objectAtIndex:i] CGPointValue];
        CGPoint P3 = [[points objectAtIndex:(i+1)] CGPointValue];
        
        matrix[i][0]=(double)(P2.x-P1.x)/6;
        matrix[i][1]=(double)(P3.x-P1.x)/3;
        matrix[i][2]=(double)(P3.x-P2.x)/6;
        result[i]=(double)(P3.y-P2.y)/(P3.x-P2.x) - (double)(P2.y-P1.y)/(P2.x-P1.x);
    }
    
    // What about result[0] and result[n-1]? Assuming 0 for now (Brad L.)
    result[0] = 0;
    result[n-1] = 0;
    
    matrix[n-1][1]=1;
    // What about matrix[n-1][0] and matrix[n-1][2]? For now, assuming they are 0 (Brad L.)
    matrix[n-1][0]=0;
    matrix[n-1][2]=0;
    
    // solving pass1 (up->down)
    for(int i=1;i<n;i++)
    {
        double k = matrix[i][0]/matrix[i-1][1];
        matrix[i][1] -= k*matrix[i-1][2];
        matrix[i][0] = 0;
        result[i] -= k*result[i-1];
    }
    // solving pass2 (down->up)
    for(NSInteger i=n-2;i>=0;i--)
    {
        double k = matrix[i][2]/matrix[i+1][1];
        matrix[i][1] -= k*matrix[i+1][0];
        matrix[i][2] = 0;
        result[i] -= k*result[i+1];
    }
    
    double y2[n];
    for(int i=0;i<n;i++) y2[i]=result[i]/matrix[i][1];
    
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:n];
    for (int i=0;i<n;i++)
    {
        [output addObject:[NSNumber numberWithDouble:y2[i]]];
    }
    
    return output;
}

- (void) updateToneCurveTexture {
    if ( ([_redCurve count] >= 256) && ([_greenCurve count] >= 256) && ([_blueCurve count] >= 256) && ([_rgbCompositeCurve count] >= 256))
    {
        for (unsigned int currentCurveIndex = 0; currentCurveIndex < 256; currentCurveIndex++)
        {
            // BGRA for upload to texture
            GLubyte b = fmin(fmax(currentCurveIndex + [[_blueCurve objectAtIndex:currentCurveIndex] floatValue], 0), 255);
            toneCurveByteArray[currentCurveIndex * 4] = fmin(fmax(b + [[_rgbCompositeCurve objectAtIndex:b] floatValue], 0), 255);
            GLubyte g = fmin(fmax(currentCurveIndex + [[_greenCurve objectAtIndex:currentCurveIndex] floatValue], 0), 255);
            toneCurveByteArray[currentCurveIndex * 4 + 1] = fmin(fmax(g + [[_rgbCompositeCurve objectAtIndex:g] floatValue], 0), 255);
            GLubyte r = fmin(fmax(currentCurveIndex + [[_redCurve objectAtIndex:currentCurveIndex] floatValue], 0), 255);
            toneCurveByteArray[currentCurveIndex * 4 + 2] = fmin(fmax(r + [[_rgbCompositeCurve objectAtIndex:r] floatValue], 0), 255);
            toneCurveByteArray[currentCurveIndex * 4 + 3] = 255;
        }
    }
}

- (int)width
{
    return 256;
}

- (int)height
{
    return 1;
}

- (GLint)getTexId
{
    GLint texId = 0;
    texId = [BMWGLUtils createTextureWithData:self.textureData width:self.width height:self.height];
    return texId;
}
@end
