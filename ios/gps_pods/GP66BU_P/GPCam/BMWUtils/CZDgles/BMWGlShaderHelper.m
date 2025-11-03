#import "BMWGlShaderHelper.h"

@implementation BMWGlShaderHelper

+ (GLuint)loadShader:(GLenum)type withFilepath:(NSString *)shaderFilepath
{
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderFilepath
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
    if (!shaderString) {
                return 0;
    }

    return [self loadShader:type withString:shaderString];
}

+ (GLuint)loadShader:(GLenum)type withString:(NSString *)shaderString
{
    // Create the shader object
    GLuint shader = glCreateShader(type);
    if (shader == 0) {
                return 0;
    }

    // Load the shader source
    const char * shaderStringUTF8 = [shaderString UTF8String];
    glShaderSource(shader, 1, &shaderStringUTF8, NULL);

    // Compile the shader
    glCompileShader(shader);

    // Check the compile status
    GLint compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

    if (!compiled) {
        GLint infoLen = 0;
        glGetShaderiv ( shader, GL_INFO_LOG_LENGTH, &infoLen );

        if (infoLen > 1) {
            char * infoLog = malloc(sizeof(char) * infoLen);
            glGetShaderInfoLog (shader, infoLen, NULL, infoLog);

            free(infoLog);
        }

        glDeleteShader(shader);
        return 0;
    }

    return shader;
}

+ (GLuint)loadProgramString:(NSString *)vertexShaderString withFragmentShaderString:(NSString *)fragmentShaderString
{
    GLuint vertexShader = [self loadShader:GL_VERTEX_SHADER withString:vertexShaderString];
    if (vertexShader == 0)
        return 0;

    GLuint fragmentShader = [self loadShader:GL_FRAGMENT_SHADER withString:fragmentShaderString];

    if (fragmentShader == 0) {
        glDeleteShader(vertexShader);
        return 0;
    }

    // Create the program object
    GLuint programHandle = glCreateProgram();
    if (programHandle == 0)
        return 0;

    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);

    // Link the program
    glLinkProgram(programHandle);

    // Check the link status
    GLint linked;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linked);

    if (!linked) {
        GLint infoLen = 0;
        glGetProgramiv(programHandle, GL_INFO_LOG_LENGTH, &infoLen);

        if (infoLen > 1){
            char * infoLog = malloc(sizeof(char) * infoLen);
            glGetProgramInfoLog(programHandle, infoLen, NULL, infoLog);

            free(infoLog);
        }

        glDeleteProgram(programHandle );
        return 0;
    }

    // Free up no longer needed shader resources
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    return programHandle;

}

+ (GLuint)loadProgram:(NSString *)vertexShaderFilepath withFragmentShaderFilepath:(NSString *)fragmentShaderFilepath
{
    // Load the vertex/fragment shaders
    GLuint vertexShader = [self loadShader:GL_VERTEX_SHADER
                              withFilepath:vertexShaderFilepath];
    if (vertexShader == 0)
        return 0;

    GLuint fragmentShader = [self loadShader:GL_FRAGMENT_SHADER
                                withFilepath:fragmentShaderFilepath];
    if (fragmentShader == 0) {
        glDeleteShader(vertexShader);
        return 0;
    }

    // Create the program object
    GLuint programHandle = glCreateProgram();
    if (programHandle == 0)
        return 0;

    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);

    // Link the program
    glLinkProgram(programHandle);

    // Check the link status
    GLint linked;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linked);

    if (!linked) {
        GLint infoLen = 0;
        glGetProgramiv(programHandle, GL_INFO_LOG_LENGTH, &infoLen);

        if (infoLen > 1){
            char * infoLog = malloc(sizeof(char) * infoLen);
            glGetProgramInfoLog(programHandle, infoLen, NULL, infoLog);

            free(infoLog);
        }

        glDeleteProgram(programHandle );
        return 0;
    }

    // Free up no longer needed shader resources
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    return programHandle;
}

@end
