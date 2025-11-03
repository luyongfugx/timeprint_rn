#import "BMWRoundRectangleDrawer.h"
#import "BMWGLUtils.h"

static NSString* const kFragmentString = SHADER_STRING
(
     precision highp float;
     varying vec2 textureCoordinate;
     uniform sampler2D inputImageTexture;
    
    const vec4 bgColor = vec4(0.0);
     uniform int enableBorder;
     uniform vec4 borderColor;
     uniform float borderWidth;
     uniform float radius;
     uniform vec2 resolution;
    // ref：https://www.shadertoy.com/view/fsdyzB
     float roundedBoxSDF(vec2 centerPosition, vec2 size, vec4 radius)
     {
        radius.xy = (centerPosition.x > 0.0) ? radius.xy : radius.zw;
        radius.x  = (centerPosition.y > 0.0) ? radius.x  : radius.y;
        vec2 q = abs(centerPosition)-size+radius.x;
        return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - radius.x;
     }

     vec4 border(vec4 fragColor, vec2 fragCoord)
     {
        vec2 rectSize = resolution.xy;     // The pixel-space scale of the rectangle.
        vec2 rectCenter = (resolution.xy / 2.0); // The pixel-space rectangle center location
        
        vec4  colorRect = fragColor; // The color of rectangle
        vec4  colorBorder = borderColor; // The color of (internal) border
        vec4  colorShadow = vec4(0.0); // The color of shadow
        vec4  colorBg = vec4(0.0); // The color of background

        // Corner
        float edgeSoftness = 2.0; // How soft the edges should be (in pixels). Higher values could be used to simulate a drop shadow.
        vec4 cornerRadiuses = vec4(radius, radius, radius, radius); // The radiuses of the corners(in pixels): [topRight, bottomRight, topLeft, bottomLeft]
         
        // Border
        float borderThickness = borderWidth; // The border size (in pixels)
        float borderSoftness = 2.0; // How soft the (internal) border should be (in pixels)
         
        // Shadow
        float shadowSoftness = 0.0;            // The (half) shadow radius (in pixels)
        vec2  shadowOffset = vec2(0.0, 0.0); // The pixel-space shadow offset from rectangle center
        
        vec2 halfSize = (rectSize / 2.0); // Rectangle extents (half of the size)
        vec4 radius = cornerRadiuses; // Animated corners radiuses
        float distance = roundedBoxSDF(fragCoord.xy - rectCenter, halfSize, radius);
        float smoothedAlpha = 1.0-smoothstep(0.0, edgeSoftness, distance);
        float borderAlpha = 1.0-smoothstep(borderThickness - borderSoftness, borderThickness, abs(distance));
        float shadowDistance = roundedBoxSDF(fragCoord.xy - rectCenter + shadowOffset, halfSize, radius);
        float shadowAlpha = 1.0-smoothstep(-shadowSoftness, shadowSoftness, shadowDistance);
        
        // Apply colors layer-by-layer: background <- shadow <- rect <- border.
        // Blend background with shadow
        vec4 res_shadow_color = mix(colorBg, vec4(colorShadow.rgb, shadowAlpha), shadowAlpha);
        
        // Blend (background+shadow) with rect
        vec4 res_shadow_with_rect_color = mix(res_shadow_color, colorRect, min(colorRect.a, smoothedAlpha));
        
        // Blend (background+shadow+rect) with border
        vec4 res_shadow_with_rect_with_border = mix(res_shadow_with_rect_color, colorBorder, min(colorBorder.a, min(borderAlpha, smoothedAlpha)) );
         return res_shadow_with_rect_with_border;
     }
     
     void main()
     {
        vec4 outColor = texture2D(inputImageTexture, textureCoordinate);
        if(enableBorder > 0) {
            vec2 pos = textureCoordinate * resolution;
            outColor = border(outColor, pos);
        }
        gl_FragColor = outColor;
     }
);

@interface BMWRoundRectangleDrawer ()
{
    GLuint _enableBorderSlot;
    GLuint _borderColorSlot;
    GLuint _borderWidthSlot;
    GLuint _radiusSlot;
    GLuint _resolutionSlot;
}

@property (nonatomic, strong) BMWImageContext *imageContext;
@property (nonatomic, assign) int enableBorder;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) float borderWidth;
@property (nonatomic, assign) float radius;
@property (nonatomic, assign) CGSize resolution;

@end

@implementation BMWRoundRectangleDrawer


- (instancetype)initWithContext:(BMWImageContext *)imageContext
{
    if (self = [super init]) {
        self.imageContext = imageContext;
    }
    return self;
}


- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:kFragmentString];
    
    _enableBorderSlot = [super getUniformLocation:@"enableBorder"];
    _borderColorSlot = [super getUniformLocation:@"borderColor"];
    _borderWidthSlot = [super getUniformLocation:@"borderWidth"];
    _radiusSlot = [super getUniformLocation:@"radius"];
    _resolutionSlot = [super getUniformLocation:@"resolution"];
}

- (void)prepare
{
    [super prepare];
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    glUniform1i(_enableBorderSlot, self.enableBorder ? 1 : 0);
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [self.borderColor getRed:&red green:&green blue:&blue alpha:&alpha];
    glUniform4f(_borderColorSlot, red, green, blue, alpha);
    glUniform1f(_borderWidthSlot, self.borderWidth);
    glUniform1f(_radiusSlot, self.radius);
    glUniform2f(_resolutionSlot, self.resolution.width,  self.resolution.height);
}

- (void)clearup
{
    [super clearup];
    glDisable(GL_BLEND);
}


- (void)setResolution:(CGSize)resolution radius:(int)radius borderWidth:(float)borderWidth borderColor:(UIColor*)borderColor
{
    self.enableBorder = YES;
    self.resolution = resolution;
    self.radius = radius;
    self.borderWidth = borderWidth;
    self.borderColor = borderColor;
}

@end
