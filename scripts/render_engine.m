#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>
#import <unistd.h>

#define WIDTH 1920
#define HEIGHT 1080
#define FPS 60.0

static inline double clampd(double v, double minv, double maxv) {
    if (v < minv) return minv;
    if (v > maxv) return maxv;
    return v;
}

static inline double easeOutCubic(double t) {
    t = clampd(t, 0.0, 1.0);
    return 1.0 - pow(1.0 - t, 3.0);
}

static inline double easeInOutQuad(double t) {
    t = clampd(t, 0.0, 1.0);
    return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
}

static void drawRoundedRectPath(CGContextRef ctx, CGRect rect, CGFloat r) {
    CGPathRef path = CGPathCreateWithRoundedRect(rect, r, r, NULL);
    CGContextAddPath(ctx, path);
    CGPathRelease(path);
}

// Studio Lighting Shaders
static void drawStudioBackground(CGContextRef ctx, BOOL isLight, double intensity) {
    if (isLight) {
        CGContextSetRGBFillColor(ctx, 0.96, 0.96, 0.97, 1.0);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));

        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGFloat locations[3] = {0.0, 0.60, 1.0};
        CGFloat components[12] = {
            1.0, 1.0, 1.0, 1.0,
            0.965, 0.965, 0.975, 1.0,
            0.915, 0.915, 0.925, 1.0
        };
        CGGradientRef grad = CGGradientCreateWithColorComponents(cs, components, locations, 3);
        CGPoint center = CGPointMake(WIDTH * 0.5, HEIGHT * 0.68);
        CGContextDrawRadialGradient(ctx, grad, center, 0.0, center, WIDTH * 0.85, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(grad);
        CGColorSpaceRelease(cs);
    } else {
        CGContextSetRGBFillColor(ctx, 0.02, 0.02, 0.03, 1.0);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));

        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGFloat locations[3] = {0.0, 0.55, 1.0};
        CGFloat components[12] = {
            0.09 * intensity, 0.10 * intensity, 0.15 * intensity, 1.0,
            0.04 * intensity, 0.042 * intensity, 0.06 * intensity, 1.0,
            0.02 * intensity, 0.02 * intensity, 0.03 * intensity, 1.0
        };
        CGGradientRef grad = CGGradientCreateWithColorComponents(cs, components, locations, 3);
        CGPoint center = CGPointMake(WIDTH * 0.5, HEIGHT * 0.65);
        CGContextDrawRadialGradient(ctx, grad, center, 0.0, center, WIDTH * 0.85, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(grad);
        CGColorSpaceRelease(cs);
    }
}

static void drawBrandWatermark(CGContextRef ctx, const char *brand, BOOL isLight, double alpha) {
    if (alpha <= 0.01) return;
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: (isLight ? [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:0.45 * alpha] : [NSColor colorWithWhite:0.92 alpha:0.45 * alpha]),
        NSKernAttributeName: @(5.0)
    };
    NSString *brandStr = [NSString stringWithUTF8String:brand];
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:brandStr attributes:attrs];
    [str drawAtPoint:NSMakePoint(80, HEIGHT - 70)];
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        BOOL isLight = NO;
        int targetFrame = -1;
        const char *singleOutPath = NULL;
        int totalFrames = 1800; // default 30s
        const char *brand = "APPLE MOTION GRAPHICS";

        for (int i = 1; i < argc; i++) {
            if (strcmp(argv[i], "--theme") == 0 && i + 1 < argc) {
                if (strcmp(argv[i+1], "light") == 0) isLight = YES;
                i++;
            } else if (strcmp(argv[i], "--frame") == 0 && i + 2 < argc) {
                targetFrame = atoi(argv[i+1]);
                singleOutPath = argv[i+2];
                i += 2;
            } else if (strcmp(argv[i], "--frames") == 0 && i + 1 < argc) {
                totalFrames = atoi(argv[i+1]);
                i++;
            } else if (strcmp(argv[i], "--brand") == 0 && i + 1 < argc) {
                brand = argv[i+1];
                i++;
            }
        }

        int w = WIDTH;
        int h = HEIGHT;
        int bytesPerRow = w * 4;
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(NULL, w, h, 8, bytesPerRow, cs, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);

        CGContextSetAllowsAntialiasing(ctx, true);
        CGContextSetShouldAntialias(ctx, true);
        CGContextSetAllowsFontSmoothing(ctx, true);
        CGContextSetShouldSmoothFonts(ctx, true);
        CGContextSetAllowsFontSubpixelPositioning(ctx, true);
        CGContextSetShouldSubpixelPositionFonts(ctx, true);

        void *data = CGBitmapContextGetData(ctx);

        if (targetFrame >= 0 && singleOutPath) {
            CGContextClearRect(ctx, CGRectMake(0, 0, w, h));
            NSGraphicsContext *nsCtx = [NSGraphicsContext graphicsContextWithCGContext:ctx flipped:NO];
            [NSGraphicsContext setCurrentContext:nsCtx];

            drawStudioBackground(ctx, isLight, 1.0);
            drawBrandWatermark(ctx, brand, isLight, 1.0);

            // Render sample frame
            NSDictionary *titleAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:120 weight:NSFontWeightBold],
                NSForegroundColorAttributeName: (isLight ? [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:1.0] : [NSColor whiteColor]),
                NSKernAttributeName: @(8.0)
            };
            NSAttributedString *tStr = [[NSAttributedString alloc] initWithString:@"PREVIEW" attributes:titleAttrs];
            CGSize sz = [tStr size];
            [tStr drawAtPoint:NSMakePoint((w - sz.width) * 0.5, (h - sz.height) * 0.5)];

            CGImageRef img = CGBitmapContextCreateImage(ctx);
            NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
            NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
            [pngData writeToFile:[NSString stringWithUTF8String:singleOutPath] atomically:YES];
            CGImageRelease(img);
            fprintf(stderr, "Exported preview frame %d to %s\n", targetFrame, singleOutPath);
            return 0;
        }

        // Streaming video pipe mode
        fprintf(stderr, "Streaming %d frames to stdout at %dx%d (60fps, %s mode)...\n", totalFrames, w, h, isLight ? "light" : "dark");
        for (int frame = 0; frame < totalFrames; frame++) {
            CGContextClearRect(ctx, CGRectMake(0, 0, w, h));
            NSGraphicsContext *nsCtx = [NSGraphicsContext graphicsContextWithCGContext:ctx flipped:NO];
            [NSGraphicsContext setCurrentContext:nsCtx];

            drawStudioBackground(ctx, isLight, 1.0);
            drawBrandWatermark(ctx, brand, isLight, 1.0);

            write(STDOUT_FILENO, data, bytesPerRow * h);
        }
        fprintf(stderr, "Stream completed successfully!\n");
        CGContextRelease(ctx);
        CGColorSpaceRelease(cs);
    }
    return 0;
}
