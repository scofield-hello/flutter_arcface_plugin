//
//  Utility.m
//

#import "Utility.h"
#define clamp(a) (a>255?255:(a<0?0:a))
#define CDV_PHOTO_PREFIX @"cdv_registerPhoto_"
@implementation Utility

+ (ASF_CAMERA_INPUT_DATA) createOffscreen:(MInt32) width height:(MInt32) height format:(MUInt32) format
{
    ASF_CAMERA_DATA* pCameraData = MNull;
    do
    {
        pCameraData = (ASF_CAMERA_DATA*)malloc(sizeof(ASF_CAMERA_DATA));
        if(!pCameraData)
            break;
        memset(pCameraData, 0, sizeof(ASF_CAMERA_DATA));
        pCameraData->u32PixelArrayFormat = format;
        pCameraData->i32Width = width;
        pCameraData->i32Height = height;
        
        if (ASVL_PAF_NV12 == format) {
            pCameraData->pi32Pitch[0] = pCameraData->i32Width;        //Y
            pCameraData->pi32Pitch[1] = pCameraData->i32Width;        //UV
            pCameraData->ppu8Plane[0] = (MUInt8*)malloc(height * 3/2 * pCameraData->pi32Pitch[0]) ;    // Y
            pCameraData->ppu8Plane[1] = pCameraData->ppu8Plane[0] + pCameraData->i32Height * pCameraData->pi32Pitch[0]; // UV
            memset(pCameraData->ppu8Plane[0], 0, height * 3/2 * pCameraData->pi32Pitch[0]);
        } else if (ASVL_PAF_RGB24_B8G8R8 == format) {
            pCameraData->pi32Pitch[0] = pCameraData->i32Width * 3;
            pCameraData->ppu8Plane[0] = (MUInt8*)malloc(height * pCameraData->pi32Pitch[0]);
        }
    } while(false);
    
    return pCameraData;
}

#pragma mark - Private Methods
+ (ASF_CAMERA_INPUT_DATA)getCameraDataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (NULL == sampleBuffer)
        return NULL;
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    OSType pixelType =  CVPixelBufferGetPixelFormatType(cameraFrame);
    
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    ASF_CAMERA_DATA* _cameraData = NULL;
    if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == pixelType || kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == pixelType) // NV12
    {
        _cameraData = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_NV12];
        ASF_CAMERA_DATA* pCameraData = _cameraData;
        uint8_t  *baseAddress0 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0); // Y
        uint8_t  *baseAddress1 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1); // UV
        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
        size_t   rowBytePlane1 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 1);
        
        //Y Data
        if (rowBytePlane0 == pCameraData->pi32Pitch[0])
        {
            memcpy(pCameraData->ppu8Plane[0], baseAddress0, rowBytePlane0*bufferHeight);
        }
        else
        {
            for (int i = 0; i < bufferHeight; ++i) {
                memcpy(pCameraData->ppu8Plane[0] + i * bufferWidth, baseAddress0 + i * rowBytePlane0, bufferWidth);
            }
        }
        //uv data
        if (rowBytePlane1 == pCameraData->pi32Pitch[1])
        {
            memcpy(pCameraData->ppu8Plane[1], baseAddress1, rowBytePlane1 * bufferHeight / 2);
        }
        else
        {
            uint8_t  *pPlanUV = pCameraData->ppu8Plane[1];
            for (int i = 0; i < bufferHeight / 2; ++i) {
                memcpy(pPlanUV + i * bufferWidth, baseAddress1+ i * rowBytePlane1, bufferWidth);
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    
    return _cameraData;
}

+ (void) freeCameraData:(ASF_CAMERA_INPUT_DATA) pOffscreen
{
    if (MNull != pOffscreen)
    {
        if (MNull != pOffscreen->ppu8Plane[0])
        {
            free(pOffscreen->ppu8Plane[0]);
            pOffscreen->ppu8Plane[0] = MNull;
        }
        free(pOffscreen);
        pOffscreen = MNull;
    }
}

+ (UIImage *)clipWithImageToSize:(CGSize)clipSize clipImage:(UIImage *)clipImage
{
    UIGraphicsBeginImageContext(clipSize);
    [clipImage drawInRect:CGRectMake(0,0,clipSize.width,clipSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return  newImage;
}

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    uint8_t *yBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t yPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    uint8_t *cbCrBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    size_t cbCrPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
    
    int bytesPerPixel = 4;
    uint8_t *rgbBuffer = malloc(width * height * bytesPerPixel);
    
    for(int y = 0; y < height; y++) {
        uint8_t *rgbBufferLine = &rgbBuffer[y * width * bytesPerPixel];
        uint8_t *yBufferLine = &yBuffer[y * yPitch];
        uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];
        
        for(int x = 0; x < width; x++) {
            int16_t y = yBufferLine[x];
            int16_t cb = cbCrBufferLine[x & ~1] - 128;
            int16_t cr = cbCrBufferLine[x | 1] - 128;
            
            uint8_t *rgbOutput = &rgbBufferLine[x*bytesPerPixel];
            
            int16_t r = (int16_t)roundf( y + cr *  1.4 );
            int16_t g = (int16_t)roundf( y + cb * -0.343 + cr * -0.711 );
            int16_t b = (int16_t)roundf( y + cb *  1.765);
            
            rgbOutput[0] = 0xff;
            rgbOutput[1] = clamp(b);
            rgbOutput[2] = clamp(g);
            rgbOutput[3] = clamp(r);
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbBuffer, width, height, 8, width * bytesPerPixel, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(quartzImage);
    free(rgbBuffer);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
}
//照片获取本地路径转换
+ (NSString *)getImagePath:(UIImage *)Image
{
    
    NSString * filePath = nil;
    NSData * data = UIImageJPEGRepresentation(Image, 0.8);
    
    //图片保存的路径
    //这里将图片放在沙盒的documents文件夹中
    NSString * DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    //文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //把刚刚图片转换的data对象拷贝至沙盒中
    [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
    //获取当前时间日期
    int i = 1;
    NSString * ImagePath = [[NSString alloc]initWithFormat:@"%@%03d.jpg", CDV_PHOTO_PREFIX, i++];
    [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:ImagePath] contents:data attributes:nil];
    
    //得到选择后沙盒中图片的完整路径
    filePath = [[NSString alloc]initWithFormat:@"%@/%@",DocumentsPath,ImagePath];//file://
    BOOL success = [data writeToFile:filePath atomically:YES];
    if (success) {
        NSLog(@"写入成功");
    }
    
    return filePath;
}

@end
