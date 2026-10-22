#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>
#import <unistd.h>

#define WIDTH 1920
#define HEIGHT 1080
#define TOTAL_FRAMES 2400
#define FPS 60.0

// Easing functions
static inline double clampd(double v, double minv, double maxv) {
    if (v < minv) return minv;
    if (v > maxv) return maxv;
    return v;
}

static inline double easeInOutCubic(double t) {
    t = clampd(t, 0.0, 1.0);
    return t < 0.5 ? 4.0 * t * t * t : 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0;
}

static inline double easeOutCubic(double t) {
    t = clampd(t, 0.0, 1.0);
    return 1.0 - pow(1.0 - t, 3.0);
}

static inline double easeOutQuint(double t) {
    t = clampd(t, 0.0, 1.0);
    return 1.0 - pow(1.0 - t, 5.0);
}

static inline double easeOutExpo(double t) {
    t = clampd(t, 0.0, 1.0);
    return (t >= 1.0) ? 1.0 : 1.0 - pow(2.0, -10.0 * t);
}

static inline double easeInOutQuad(double t) {
    t = clampd(t, 0.0, 1.0);
    return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
}

// Drawing Utilities
static void drawStudioBackground(CGContextRef ctx, double t, double intensity) {
    // Solid deep dark base
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

static void drawGargProtocolWatermark(CGContextRef ctx, double alpha) {
    if (alpha <= 0.01) return;
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.92 alpha:0.45 * alpha],
        NSKernAttributeName: @(5.0)
    };
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"GARGPROTOCOL" attributes:attrs];
    [str drawAtPoint:NSMakePoint(80, HEIGHT - 70)];
    
    NSDictionary *metaAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.75 alpha:0.35 * alpha],
        NSKernAttributeName: @(3.0)
    };
    NSAttributedString *metaStr = [[NSAttributedString alloc] initWithString:@"REA ARCHITECTURE // PRODUCT FILM" attributes:metaAttrs];
    CGSize sz = [metaStr size];
    [metaStr drawAtPoint:NSMakePoint(WIDTH - 80 - sz.width, HEIGHT - 70)];
}

static void drawRoundedRectPath(CGContextRef ctx, CGRect rect, CGFloat r) {
    CGPathRef path = CGPathCreateWithRoundedRect(rect, r, r, NULL);
    CGContextAddPath(ctx, path);
    CGPathRelease(path);
}

// Shot 1: REA Reveal (Frames 0 - 359, 0.0s - 6.0s)
static void renderShot1(CGContextRef ctx, int frame) {
    double t = frame / FPS; // 0.0 to 6.0
    
    // Background fade from pure black to subtle studio spotlight
    double bgAlpha = easeOutCubic(clampd((t - 0.3) / 2.0, 0.0, 1.0));
    drawStudioBackground(ctx, t, bgAlpha);
    
    // Camera slow push
    double push = 0.95 + 0.06 * easeInOutQuad(t / 6.0);
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, WIDTH * 0.5, HEIGHT * 0.5);
    CGContextScaleCTM(ctx, push, push);
    CGContextTranslateCTM(ctx, -WIDTH * 0.5, -HEIGHT * 0.5);
    
    // Thin soft white light beam sweeping across
    double beamProgress = clampd((t - 0.4) / 2.6, 0.0, 1.0);
    double beamX = -200.0 + (WIDTH + 400.0) * easeInOutCubic(beamProgress);
    
    if (t > 0.4 && t < 3.8) {
        CGContextSaveGState(ctx);
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGFloat bLocs[3] = {0.0, 0.5, 1.0};
        CGFloat bAlpha = (t < 2.8) ? 0.45 : 0.45 * (1.0 - (t - 2.8) / 1.0);
        CGFloat bComps[12] = {
            1.0, 1.0, 1.0, 0.0,
            1.0, 1.0, 1.0, (CGFloat)bAlpha,
            1.0, 1.0, 1.0, 0.0
        };
        CGGradientRef bGrad = CGGradientCreateWithColorComponents(cs, bComps, bLocs, 3);
        CGContextDrawLinearGradient(ctx, bGrad, CGPointMake(beamX - 160, 0), CGPointMake(beamX + 160, 0), 0);
        CGGradientRelease(bGrad);
        CGColorSpaceRelease(cs);
        CGContextRestoreGState(ctx);
    }
    
    // REA Letters Reveal
    // Reveal mask advances with the beam
    double textReveal = clampd((beamX - (WIDTH * 0.5 - 300)) / 600.0, 0.0, 1.0);
    double titleAlpha = easeOutCubic(textReveal);
    
    if (titleAlpha > 0.001) {
        CGContextSaveGState(ctx);
        // Soft ambient glow behind REA
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, 10), 35.0, [[NSColor colorWithWhite:1.0 alpha:0.18 * titleAlpha] CGColor]);
        
        NSDictionary *titleAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:175 weight:NSFontWeightHeavy],
            NSForegroundColorAttributeName: [NSColor colorWithWhite:0.98 alpha:titleAlpha],
            NSKernAttributeName: @(18.0)
        };
        NSAttributedString *titleStr = [[NSAttributedString alloc] initWithString:@"REA" attributes:titleAttrs];
        CGSize titleSz = [titleStr size];
        CGPoint titlePt = CGPointMake((WIDTH - titleSz.width) * 0.5 + 9.0, HEIGHT * 0.5 - titleSz.height * 0.5 + 45.0);
        
        [titleStr drawAtPoint:titlePt];
        CGContextRestoreGState(ctx);
    }
    
    // Subtitle & Divider Line (Fade in at t = 2.4s to 4.5s)
    if (t > 2.2) {
        double subProgress = easeOutCubic(clampd((t - 2.2) / 1.5, 0.0, 1.0));
        
        // Thin silver divider line
        double lineHalfWidth = 140.0 * subProgress;
        CGContextSaveGState(ctx);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:0.85 alpha:0.4 * subProgress] CGColor]);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, WIDTH * 0.5 - lineHalfWidth, HEIGHT * 0.5 - 65.0);
        CGContextAddLineToPoint(ctx, WIDTH * 0.5 + lineHalfWidth, HEIGHT * 0.5 - 65.0);
        CGContextStrokePath(ctx);
        CGContextRestoreGState(ctx);
        
        // Subtitle "Reverse Engineer Anything"
        NSDictionary *subAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:26 weight:NSFontWeightLight],
            NSForegroundColorAttributeName: [NSColor colorWithWhite:0.88 alpha:0.92 * subProgress],
            NSKernAttributeName: @(8.0)
        };
        NSAttributedString *subStr = [[NSAttributedString alloc] initWithString:@"Reverse Engineer Anything" attributes:subAttrs];
        CGSize subSz = [subStr size];
        CGPoint subPt = CGPointMake((WIDTH - subSz.width) * 0.5 + 4.0, HEIGHT * 0.5 - 118.0);
        [subStr drawAtPoint:subPt];
    }
    
    CGContextRestoreGState(ctx);
    
    // Watermark
    double wmAlpha = easeOutCubic(clampd((t - 1.5) / 1.5, 0.0, 1.0));
    drawGargProtocolWatermark(ctx, wmAlpha);
    
    // Cross-dissolve out at end of shot
    if (t > 5.4) {
        double fadeOut = clampd((t - 5.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:0.02 alpha:fadeOut] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 2: The Tool (Frames 360 - 719, 6.0s - 12.0s)
static void renderShot2(CGContextRef ctx, int frame) {
    double t = (frame - 360) / FPS; // 0.0 to 6.0
    
    drawStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);
    
    // Entry animation: panel glides from depth
    double entry = easeOutCubic(clampd(t / 2.0, 0.0, 1.0));
    double rotY = -0.10 + 0.16 * easeInOutQuad(t / 6.0); // Gentle 3D orbit
    double rotX = 0.04 - 0.06 * easeInOutQuad(t / 6.0);
    double scale = 0.88 + 0.12 * entry;
    
    // Layer separation progress starts around t = 3.0
    double sep = easeInOutCubic(clampd((t - 2.8) / 2.0, 0.0, 1.0));
    
    // Headline at top
    double textAlpha = easeOutCubic(clampd((t - 0.5) / 1.2, 0.0, 1.0));
    NSDictionary *hdrAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.25 green:0.62 blue:1.0 alpha:0.9 * textAlpha],
        NSKernAttributeName: @(4.0)
    };
    NSAttributedString *hdrStr = [[NSAttributedString alloc] initWithString:@"AGENTIC REVERSE-ENGINEERING ENGINE" attributes:hdrAttrs];
    CGSize hdrSz = [hdrStr size];
    [hdrStr drawAtPoint:NSMakePoint((WIDTH - hdrSz.width) * 0.5, HEIGHT - 130)];
    
    NSDictionary *titleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:38 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.96 alpha:textAlpha],
        NSKernAttributeName: @(1.5)
    };
    NSAttributedString *titleStr = [[NSAttributedString alloc] initWithString:@"The Autonomous Analysis Platform" attributes:titleAttrs];
    CGSize titleSz = [titleStr size];
    [titleStr drawAtPoint:NSMakePoint((WIDTH - titleSz.width) * 0.5, HEIGHT - 180)];
    
    // 3D Panel Container
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, WIDTH * 0.5, HEIGHT * 0.46);
    CGContextScaleCTM(ctx, scale, scale);
    
    // 3D Skew / perspective representation
    CGAffineTransform transform3D = CGAffineTransformMake(cos(rotY), sin(rotX) * 0.5, -sin(rotY) * 0.3, cos(rotX), 0, 0);
    CGContextConcatCTM(ctx, transform3D);
    
    CGFloat panelW = 1140.0;
    CGFloat panelH = 620.0;
    CGRect baseRect = CGRectMake(-panelW * 0.5, -panelH * 0.5, panelW, panelH);
    
    // --- LAYER 1: Deep Backing Glass ---
    CGContextSaveGState(ctx);
    // Deep realistic drop shadow
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, -35), 65.0, [[NSColor colorWithWhite:0.0 alpha:0.75] CGColor]);
    
    // Frosted dark glass fill
    drawRoundedRectPath(ctx, baseRect, 18.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.08 green:0.09 blue:0.12 alpha:0.88] CGColor]);
    CGContextFillPath(ctx);
    
    // Specular border
    drawRoundedRectPath(ctx, baseRect, 18.0);
    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.18] CGColor]);
    CGContextSetLineWidth(ctx, 1.5);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
    
    // --- LAYER 2: Window Chrome & Sidebar (Separates slightly in Z) ---
    CGContextSaveGState(ctx);
    CGFloat layer2Offset = sep * 25.0;
    CGContextTranslateCTM(ctx, layer2Offset * 0.5, layer2Offset * 0.5);
    
    // Title bar area
    CGRect titleBarRect = CGRectMake(baseRect.origin.x, baseRect.origin.y + panelH - 52.0, panelW, 52.0);
    drawRoundedRectPath(ctx, titleBarRect, 18.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.05] CGColor]);
    CGContextFillPath(ctx);
    
    // Apple Traffic Light dots
    CGFloat dotY = titleBarRect.origin.y + 26.0;
    CGFloat dotColors[3][4] = {
        {1.0, 0.36, 0.33, 0.95}, // Red
        {1.0, 0.74, 0.18, 0.95}, // Yellow
        {0.18, 0.80, 0.35, 0.95} // Green
    };
    for (int d = 0; d < 3; d++) {
        CGRect dotRect = CGRectMake(baseRect.origin.x + 28.0 + d * 22.0, dotY - 6.0, 12.0, 12.0);
        CGContextAddEllipseInRect(ctx, dotRect);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:dotColors[d][0] green:dotColors[d][1] blue:dotColors[d][2] alpha:dotColors[d][3]] CGColor]);
        CGContextFillPath(ctx);
    }
    
    // Window Title Pill
    NSDictionary *winTitleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.75 alpha:0.9],
        NSKernAttributeName: @(1.0)
    };
    NSAttributedString *winTitleStr = [[NSAttributedString alloc] initWithString:@"REA Engine — Static & Dynamic AST Session" attributes:winTitleAttrs];
    CGSize winTitleSz = [winTitleStr size];
    [winTitleStr drawAtPoint:NSMakePoint(-winTitleSz.width * 0.5, dotY - 8.0)];
    
    // Left Sidebar (Modules / File Tree)
    CGFloat sidebarW = 280.0;
    CGRect sidebarRect = CGRectMake(baseRect.origin.x + 16.0, baseRect.origin.y + 16.0, sidebarW, panelH - 78.0);
    drawRoundedRectPath(ctx, sidebarRect, 12.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.035] CGColor]);
    CGContextFillPath(ctx);
    drawRoundedRectPath(ctx, sidebarRect, 12.0);
    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.08] CGColor]);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextStrokePath(ctx);
    
    // Sidebar items
    NSArray *modules = @[@"▶  Target: NotionWorkspace", @"   ├─  DOM Root (94 nodes)", @"   ├─  State Tree Store", @"   ├─  Event Dispatchers", @"   ├─  Network Interceptors", @"   └─  Telemetry Bridges"];
    for (NSUInteger m = 0; m < modules.count; m++) {
        NSDictionary *modAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:12 weight:(m == 0 ? NSFontWeightSemibold : NSFontWeightRegular)],
            NSForegroundColorAttributeName: (m == 0 ? [NSColor colorWithCalibratedRed:0.3 green:0.7 blue:1.0 alpha:0.95] : [NSColor colorWithWhite:0.65 alpha:0.85]),
            NSKernAttributeName: @(0.5)
        };
        NSAttributedString *modStr = [[NSAttributedString alloc] initWithString:modules[m] attributes:modAttrs];
        [modStr drawAtPoint:NSMakePoint(sidebarRect.origin.x + 18.0, sidebarRect.origin.y + sidebarRect.size.height - 35.0 - m * 30.0)];
    }
    CGContextRestoreGState(ctx);
    
    // --- LAYER 3: Main Inspection Canvas (Separates further in Z) ---
    CGContextSaveGState(ctx);
    CGFloat layer3Offset = sep * 55.0;
    CGContextTranslateCTM(ctx, layer3Offset * 0.7, layer3Offset * 0.7);
    
    CGFloat canvasX = baseRect.origin.x + sidebarW + 36.0;
    CGFloat canvasW = panelW - sidebarW - 52.0;
    CGFloat canvasH = panelH - 78.0;
    CGRect canvasRect = CGRectMake(canvasX, baseRect.origin.y + 16.0, canvasW, canvasH);
    
    // Soft shadow from layer 3 onto layer 2
    if (sep > 0.05) {
        CGContextSetShadowWithColor(ctx, CGSizeMake(-15 * sep, -20 * sep), 30.0 * sep, [[NSColor colorWithWhite:0.0 alpha:0.6 * sep] CGColor]);
    }
    
    drawRoundedRectPath(ctx, canvasRect, 14.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.05 green:0.06 blue:0.08 alpha:0.92] CGColor]);
    CGContextFillPath(ctx);
    drawRoundedRectPath(ctx, canvasRect, 14.0);
    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.15] CGColor]);
    CGContextSetLineWidth(ctx, 1.2);
    CGContextStrokePath(ctx);
    
    // Inside Canvas: Software UI being analyzed
    // Header bar inside target app
    CGRect appHdrRect = CGRectMake(canvasX + 24.0, canvasRect.origin.y + canvasH - 60.0, canvasW - 48.0, 40.0);
    drawRoundedRectPath(ctx, appHdrRect, 8.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.06] CGColor]);
    CGContextFillPath(ctx);
    
    NSDictionary *appTitleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.9 alpha:0.9],
        NSKernAttributeName: @(1.0)
    };
    NSAttributedString *appTitleStr = [[NSAttributedString alloc] initWithString:@"Workspace Architecture & Roadmap" attributes:appTitleAttrs];
    [appTitleStr drawAtPoint:NSMakePoint(appHdrRect.origin.x + 16.0, appHdrRect.origin.y + 11.0)];
    
    // Precision inspection bounding boxes (Cool Blue vectors showing AI analysis)
    CGRect box1 = CGRectMake(canvasX + 24.0, canvasRect.origin.y + canvasH - 180.0, canvasW - 48.0, 100.0);
    drawRoundedRectPath(ctx, box1, 8.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.16 green:0.59 blue:1.0 alpha:0.06] CGColor]);
    CGContextFillPath(ctx);
    drawRoundedRectPath(ctx, box1, 8.0);
    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.25 green:0.65 blue:1.0 alpha:0.55] CGColor]);
    CGContextSetLineWidth(ctx, 1.2);
    CGFloat dash[2] = {6.0, 4.0};
    CGContextSetLineDash(ctx, 0, dash, 2);
    CGContextStrokePath(ctx);
    CGContextSetLineDash(ctx, 0, NULL, 0); // Reset dash
    
    // Telemetry label badge
    NSDictionary *tagAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.3 green:0.75 blue:1.0 alpha:1.0],
        NSKernAttributeName: @(1.5)
    };
    NSAttributedString *tagStr = [[NSAttributedString alloc] initWithString:@"<HERO_CONTENT_CONTAINER  w:740  h:100>" attributes:tagAttrs];
    [tagStr drawAtPoint:NSMakePoint(box1.origin.x + 12.0, box1.origin.y + box1.size.height + 6.0)];
    
    // Two child blocks inside target app
    CGFloat childW = (canvasW - 64.0) * 0.5;
    for (int c = 0; c < 2; c++) {
        CGRect childRect = CGRectMake(canvasX + 24.0 + c * (childW + 16.0), canvasRect.origin.y + 36.0, childW, 200.0);
        drawRoundedRectPath(ctx, childRect, 10.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.04] CGColor]);
        CGContextFillPath(ctx);
        drawRoundedRectPath(ctx, childRect, 10.0);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.1] CGColor]);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextStrokePath(ctx);
        
        // Mock text lines inside child blocks
        for (int l = 0; l < 4; l++) {
            CGRect lineRect = CGRectMake(childRect.origin.x + 18.0, childRect.origin.y + childRect.size.height - 40.0 - l * 28.0, childW - 36.0 - (l == 3 ? 60.0 : 0.0), 10.0);
            drawRoundedRectPath(ctx, lineRect, 4.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.12] CGColor]);
            CGContextFillPath(ctx);
        }
    }
    
    CGContextRestoreGState(ctx);
    CGContextRestoreGState(ctx);
    
    // Bottom Subtitle
    NSDictionary *botAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.65 alpha:0.8 * textAlpha],
        NSKernAttributeName: @(3.0)
    };
    NSAttributedString *botStr = [[NSAttributedString alloc] initWithString:@"REAL-TIME OBSERVABILITY & STRUCTURAL DECONSTRUCTION" attributes:botAttrs];
    CGSize botSz = [botStr size];
    [botStr drawAtPoint:NSMakePoint((WIDTH - botSz.width) * 0.5, 75)];

    if (t > 5.4) {
        double fo = clampd((t - 5.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.02 green:0.02 blue:0.03 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 3: Beyond the Interface (Frames 720 - 1079, 12.0s - 18.0s)
static void renderShot3(CGContextRef ctx, int frame) {
    double t = (frame - 720) / FPS; // 0.0 to 6.0
    
    drawStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);
    
    // Camera orbit: rotation from 14 degrees to -8 degrees
    double orbitProgress = easeInOutCubic(t / 6.0);
    double rotY = 0.18 - 0.28 * orbitProgress;
    double rotX = 0.08 - 0.04 * orbitProgress;
    double camPush = 0.94 + 0.08 * easeInOutQuad(t / 6.0);
    
    // Separation expansion: layers glide apart in 3D
    double sep = easeOutCubic(clampd(t / 2.8, 0.0, 1.0));
    
    // Prominent Apple-style Headline
    double headAlpha = easeOutCubic(clampd(t / 1.5, 0.0, 1.0));
    NSDictionary *headAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:58 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.98 alpha:headAlpha],
        NSKernAttributeName: @(1.5)
    };
    NSAttributedString *headStr = [[NSAttributedString alloc] initWithString:@"More Than What You See." attributes:headAttrs];
    [headStr drawAtPoint:NSMakePoint(120, HEIGHT - 180)];
    
    NSDictionary *subAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:22 weight:NSFontWeightLight],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.75 alpha:0.85 * headAlpha],
        NSKernAttributeName: @(1.2)
    };
    NSAttributedString *subStr = [[NSAttributedString alloc] initWithString:@"Uncovering the underlying architecture beneath the visible interface." attributes:subAttrs];
    [subStr drawAtPoint:NSMakePoint(120, HEIGHT - 225)];
    
    // 3D Exploded Layer Composition
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, WIDTH * 0.56, HEIGHT * 0.44);
    CGContextScaleCTM(ctx, camPush, camPush);
    
    CGAffineTransform transform3D = CGAffineTransformMake(cos(rotY), sin(rotX) * 0.4, -sin(rotY) * 0.35, cos(rotX), 0, 0);
    CGContextConcatCTM(ctx, transform3D);
    
    CGFloat layerW = 860.0;
    CGFloat layerH = 500.0;
    CGRect layerRect = CGRectMake(-layerW * 0.5, -layerH * 0.5, layerW, layerH);
    
    // 4 Distinct Architectural Layers
    // Layer 0: System Grid & Coordinate Fabric (Back)
    // Layer 1: Window Shell & Navigation Tier
    // Layer 2: Content Modules & Containers
    // Layer 3: Interactive Controls & State Triggers (Front)
    
    CGFloat zSpacing = 70.0 * sep;
    
    for (int l = 0; l < 4; l++) {
        CGContextSaveGState(ctx);
        CGFloat zOffset = (l - 1.5) * zSpacing;
        CGContextTranslateCTM(ctx, zOffset * 0.6, zOffset * 0.6);
        
        // Realistic depth shadow cast onto lower layers
        if (l > 0 && sep > 0.1) {
            CGContextSetShadowWithColor(ctx, CGSizeMake(-20, -25), 35.0, [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor]);
        }
        
        if (l == 0) {
            // Layer 0: System Grid
            drawRoundedRectPath(ctx, layerRect, 18.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.04 green:0.05 blue:0.08 alpha:0.85] CGColor]);
            CGContextFillPath(ctx);
            drawRoundedRectPath(ctx, layerRect, 18.0);
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.2 green:0.5 blue:0.9 alpha:0.3] CGColor]);
            CGContextSetLineWidth(ctx, 1.0);
            CGContextStrokePath(ctx);
            
            // Grid lines
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.06] CGColor]);
            CGContextSetLineWidth(ctx, 1.0);
            for (CGFloat gx = layerRect.origin.x + 60.0; gx < layerRect.origin.x + layerW; gx += 60.0) {
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, gx, layerRect.origin.y);
                CGContextAddLineToPoint(ctx, gx, layerRect.origin.y + layerH);
                CGContextStrokePath(ctx);
            }
            for (CGFloat gy = layerRect.origin.y + 60.0; gy < layerRect.origin.y + layerH; gy += 60.0) {
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, layerRect.origin.x, gy);
                CGContextAddLineToPoint(ctx, layerRect.origin.x + layerW, gy);
                CGContextStrokePath(ctx);
            }
            
            // Layer tag
            NSDictionary *ltAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.3 green:0.65 blue:1.0 alpha:0.8],
                NSKernAttributeName: @(2.0)
            };
            NSAttributedString *ltStr = [[NSAttributedString alloc] initWithString:@"LAYER 01 // SYSTEM RUNTIME & LAYOUT ENGINE" attributes:ltAttrs];
            [ltStr drawAtPoint:NSMakePoint(layerRect.origin.x + 24.0, layerRect.origin.y + 20.0)];
        }
        else if (l == 1) {
            // Layer 1: Navigation Tier
            CGRect navRect = CGRectMake(layerRect.origin.x, layerRect.origin.y + layerH - 70.0, layerW, 70.0);
            drawRoundedRectPath(ctx, navRect, 14.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.06] CGColor]);
            CGContextFillPath(ctx);
            drawRoundedRectPath(ctx, navRect, 14.0);
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.18] CGColor]);
            CGContextSetLineWidth(ctx, 1.2);
            CGContextStrokePath(ctx);
            
            // Nav bar items
            NSDictionary *navAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
                NSForegroundColorAttributeName: [NSColor colorWithWhite:0.85 alpha:0.9],
                NSKernAttributeName: @(1.0)
            };
            NSAttributedString *navStr = [[NSAttributedString alloc] initWithString:@"Notion Workspace  ›  Engineering  ›  Architecture Specs" attributes:navAttrs];
            [navStr drawAtPoint:NSMakePoint(navRect.origin.x + 28.0, navRect.origin.y + 26.0)];
            
            // Search pill
            CGRect searchPill = CGRectMake(navRect.origin.x + layerW - 240.0, navRect.origin.y + 16.0, 210.0, 36.0);
            drawRoundedRectPath(ctx, searchPill, 18.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.08] CGColor]);
            CGContextFillPath(ctx);
            
            NSDictionary *ltAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold],
                NSForegroundColorAttributeName: [NSColor colorWithWhite:0.7 alpha:0.8],
                NSKernAttributeName: @(2.0)
            };
            NSAttributedString *ltStr = [[NSAttributedString alloc] initWithString:@"LAYER 02 // NAVIGATION HIERARCHY" attributes:ltAttrs];
            [ltStr drawAtPoint:NSMakePoint(layerRect.origin.x + 24.0, layerRect.origin.y + 20.0)];
        }
        else if (l == 2) {
            // Layer 2: Content Modules
            CGFloat cardW = (layerW - 48.0) * 0.5;
            for (int c = 0; c < 2; c++) {
                CGRect cRect = CGRectMake(layerRect.origin.x + 16.0 + c * (cardW + 16.0), layerRect.origin.y + 60.0, cardW, layerH - 150.0);
                drawRoundedRectPath(ctx, cRect, 14.0);
                CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.08 green:0.09 blue:0.12 alpha:0.85] CGColor]);
                CGContextFillPath(ctx);
                drawRoundedRectPath(ctx, cRect, 14.0);
                CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.16] CGColor]);
                CGContextSetLineWidth(ctx, 1.2);
                CGContextStrokePath(ctx);
                
                // Content lines
                for (int cl = 0; cl < 5; cl++) {
                    CGRect line = CGRectMake(cRect.origin.x + 24.0, cRect.origin.y + cRect.size.height - 40.0 - cl * 32.0, cardW - 48.0 - (cl % 2 == 1 ? 70.0 : 0.0), 12.0);
                    drawRoundedRectPath(ctx, line, 5.0);
                    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.14] CGColor]);
                    CGContextFillPath(ctx);
                }
            }
            
            NSDictionary *ltAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold],
                NSForegroundColorAttributeName: [NSColor colorWithWhite:0.7 alpha:0.8],
                NSKernAttributeName: @(2.0)
            };
            NSAttributedString *ltStr = [[NSAttributedString alloc] initWithString:@"LAYER 03 // COMPONENT CONTAINERS" attributes:ltAttrs];
            [ltStr drawAtPoint:NSMakePoint(layerRect.origin.x + 24.0, layerRect.origin.y + 20.0)];
        }
        else if (l == 3) {
            // Layer 3: Interactive Controls (Floating at forefront)
            // Primary Action Button
            CGRect btnRect = CGRectMake(layerRect.origin.x + 60.0, layerRect.origin.y + 120.0, 220.0, 48.0);
            drawRoundedRectPath(ctx, btnRect, 10.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.16 green:0.59 blue:1.0 alpha:0.95] CGColor]);
            CGContextFillPath(ctx);
            
            NSDictionary *btnAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
                NSForegroundColorAttributeName: [NSColor whiteColor],
                NSKernAttributeName: @(1.0)
            };
            NSAttributedString *btnStr = [[NSAttributedString alloc] initWithString:@"Analyze Component" attributes:btnAttrs];
            CGSize btnSz = [btnStr size];
            [btnStr drawAtPoint:NSMakePoint(btnRect.origin.x + (btnRect.size.width - btnSz.width) * 0.5, btnRect.origin.y + 15.0)];
            
            // Toggle Switch
            CGRect switchRect = CGRectMake(layerRect.origin.x + layerW - 200.0, layerRect.origin.y + 124.0, 70.0, 40.0);
            drawRoundedRectPath(ctx, switchRect, 20.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.2 green:0.75 blue:0.4 alpha:0.9] CGColor]);
            CGContextFillPath(ctx);
            CGRect knobRect = CGRectMake(switchRect.origin.x + switchRect.size.width - 36.0, switchRect.origin.y + 4.0, 32.0, 32.0);
            CGContextAddEllipseInRect(ctx, knobRect);
            CGContextSetFillColorWithColor(ctx, [[NSColor whiteColor] CGColor]);
            CGContextFillPath(ctx);
            
            NSDictionary *ltAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.3 green:0.75 blue:1.0 alpha:1.0],
                NSKernAttributeName: @(2.0)
            };
            NSAttributedString *ltStr = [[NSAttributedString alloc] initWithString:@"LAYER 04 // INTERACTIVE LOGIC & DISPATCHERS" attributes:ltAttrs];
            [ltStr drawAtPoint:NSMakePoint(layerRect.origin.x + 24.0, layerRect.origin.y + 20.0)];
        }
        
        CGContextRestoreGState(ctx);
    }
    
    // Architectural Alignment Tracer lines connecting the layer corners
    if (sep > 0.15) {
        CGContextSaveGState(ctx);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.3 green:0.65 blue:1.0 alpha:0.25 * sep] CGColor]);
        CGContextSetLineWidth(ctx, 1.0);
        CGFloat dash[2] = {4.0, 4.0};
        CGContextSetLineDash(ctx, 0, dash, 2);
        
        // 4 corner projection lines
        CGPoint corners[4] = {
            layerRect.origin,
            CGPointMake(layerRect.origin.x + layerW, layerRect.origin.y),
            CGPointMake(layerRect.origin.x + layerW, layerRect.origin.y + layerH),
            CGPointMake(layerRect.origin.x, layerRect.origin.y + layerH)
        };
        for (int c = 0; c < 4; c++) {
            CGPoint pStart = CGPointMake(corners[c].x + (-1.5 * zSpacing) * 0.6, corners[c].y + (-1.5 * zSpacing) * 0.6);
            CGPoint pEnd = CGPointMake(corners[c].x + (1.5 * zSpacing) * 0.6, corners[c].y + (1.5 * zSpacing) * 0.6);
            CGContextBeginPath(ctx);
            CGContextMoveToPoint(ctx, pStart.x, pStart.y);
            CGContextAddLineToPoint(ctx, pEnd.x, pEnd.y);
            CGContextStrokePath(ctx);
        }
        CGContextRestoreGState(ctx);
    }
    
    CGContextRestoreGState(ctx);

    if (t > 5.4) {
        double fo = clampd((t - 5.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.02 green:0.02 blue:0.03 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 4: Structure and Behavior (Frames 1080 - 1379, 18.0s - 23.0s)
static void renderShot4(CGContextRef ctx, int frame) {
    double t = (frame - 1080) / FPS; // 0.0 to 5.0
    
    drawStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);
    
    // Sequential Words: "Structure." at 0.0 - 2.5s, then "Behavior." at 2.5 - 5.0s
    double structAlpha = 0.0;
    double behavAlpha = 0.0;
    
    if (t < 2.5) {
        structAlpha = easeOutCubic(clampd(t / 0.8, 0.0, 1.0));
        if (t > 2.0) structAlpha *= (1.0 - (t - 2.0) / 0.5);
    } else {
        behavAlpha = easeOutCubic(clampd((t - 2.5) / 0.8, 0.0, 1.0));
    }
    
    if (structAlpha > 0.001) {
        NSDictionary *sAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:68 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor colorWithWhite:0.98 alpha:structAlpha],
            NSKernAttributeName: @(2.0)
        };
        NSAttributedString *sStr = [[NSAttributedString alloc] initWithString:@"Structure." attributes:sAttrs];
        [sStr drawAtPoint:NSMakePoint(120, HEIGHT - 180)];
        
        NSDictionary *ssAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:22 weight:NSFontWeightLight],
            NSForegroundColorAttributeName: [NSColor colorWithWhite:0.7 alpha:0.8 * structAlpha],
            NSKernAttributeName: @(1.2)
        };
        NSAttributedString *ssStr = [[NSAttributedString alloc] initWithString:@"Every node, frame, and container mapped into deterministic models." attributes:ssAttrs];
        [ssStr drawAtPoint:NSMakePoint(120, HEIGHT - 225)];
    }
    
    if (behavAlpha > 0.001) {
        NSDictionary *bAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:68 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor colorWithWhite:0.98 alpha:behavAlpha],
            NSKernAttributeName: @(2.0)
        };
        NSAttributedString *bStr = [[NSAttributedString alloc] initWithString:@"Behavior." attributes:bAttrs];
        [bStr drawAtPoint:NSMakePoint(120, HEIGHT - 180)];
        
        NSDictionary *bsAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:22 weight:NSFontWeightLight],
            NSForegroundColorAttributeName: [NSColor colorWithWhite:0.7 alpha:0.8 * behavAlpha],
            NSKernAttributeName: @(1.2)
        };
        NSAttributedString *bsStr = [[NSAttributedString alloc] initWithString:@"Tracing interaction causality directly to state transitions." attributes:bsAttrs];
        [bsStr drawAtPoint:NSMakePoint(120, HEIGHT - 225)];
    }
    
    // Interactive 3D Composition
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, WIDTH * 0.5, HEIGHT * 0.44);
    
    double rotY = -0.06 + 0.12 * easeInOutQuad(t / 5.0);
    double rotX = 0.04;
    CGAffineTransform transform3D = CGAffineTransformMake(cos(rotY), sin(rotX) * 0.3, -sin(rotY) * 0.2, cos(rotX), 0, 0);
    CGContextConcatCTM(ctx, transform3D);
    
    // Left: Trigger Component (Button & Checkbox)
    CGRect leftCard = CGRectMake(-580, -260, 480, 520);
    drawRoundedRectPath(ctx, leftCard, 18.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.07 green:0.08 blue:0.11 alpha:0.92] CGColor]);
    CGContextFillPath(ctx);
    drawRoundedRectPath(ctx, leftCard, 18.0);
    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.15] CGColor]);
    CGContextSetLineWidth(ctx, 1.2);
    CGContextStrokePath(ctx);
    
    NSDictionary *cardTitleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.85 alpha:0.9],
        NSKernAttributeName: @(1.5)
    };
    NSAttributedString *ctStr = [[NSAttributedString alloc] initWithString:@"INTERACTIVE TRIGGER CANOPY" attributes:cardTitleAttrs];
    [ctStr drawAtPoint:NSMakePoint(leftCard.origin.x + 28.0, leftCard.origin.y + leftCard.size.height - 45.0)];
    
    // Interactive Action 1: Button Depresses at t = 1.0s to 1.8s
    double btnPress = 0.0;
    if (t > 0.8 && t < 2.4) {
        btnPress = sin(clampd((t - 0.8) / 1.6, 0.0, 1.0) * M_PI);
    }
    CGRect btnRect = CGRectMake(leftCard.origin.x + 36.0, leftCard.origin.y + 320.0, 408.0, 64.0);
    
    // Button shadow & press offset
    CGContextSaveGState(ctx);
    CGFloat pressOffset = btnPress * 6.0;
    CGContextTranslateCTM(ctx, pressOffset * 0.5, -pressOffset);
    
    if (btnPress > 0.05) {
        // Glowing aura when pressed
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), 25.0 * btnPress, [[NSColor colorWithCalibratedRed:0.2 green:0.6 blue:1.0 alpha:0.8 * btnPress] CGColor]);
    }
    drawRoundedRectPath(ctx, btnRect, 12.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.16 green:0.59 blue:1.0 alpha:(0.85 + 0.15 * btnPress)] CGColor]);
    CGContextFillPath(ctx);
    
    NSDictionary *btnLabelAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:16 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSKernAttributeName: @(1.2)
    };
    NSAttributedString *blStr = [[NSAttributedString alloc] initWithString:(btnPress > 0.2 ? @"▶  Executing Action Dispatcher..." : @"▶  Trigger State Transition") attributes:btnLabelAttrs];
    CGSize blSz = [blStr size];
    [blStr drawAtPoint:NSMakePoint(btnRect.origin.x + (btnRect.size.width - blSz.width) * 0.5, btnRect.origin.y + 22.0)];
    CGContextRestoreGState(ctx);
    
    // Interactive Action 2: Checkboxes at t = 2.8s to 4.5s
    for (int k = 0; k < 3; k++) {
        CGRect rowRect = CGRectMake(leftCard.origin.x + 36.0, leftCard.origin.y + 220.0 - k * 70.0, 408.0, 52.0);
        drawRoundedRectPath(ctx, rowRect, 10.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.04] CGColor]);
        CGContextFillPath(ctx);
        
        // Checkbox box
        CGRect chkBox = CGRectMake(rowRect.origin.x + 16.0, rowRect.origin.y + 14.0, 24.0, 24.0);
        drawRoundedRectPath(ctx, chkBox, 6.0);
        
        // Ticking animation for second checkbox at t = 3.2s
        BOOL checked = (k == 0) || (k == 1 && t > 3.2);
        if (checked) {
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.18 green:0.8 blue:0.4 alpha:0.95] CGColor]);
            CGContextFillPath(ctx);
            
            // Checkmark draw
            CGContextSetStrokeColorWithColor(ctx, [[NSColor whiteColor] CGColor]);
            CGContextSetLineWidth(ctx, 2.2);
            CGContextBeginPath(ctx);
            CGContextMoveToPoint(ctx, chkBox.origin.x + 5.0, chkBox.origin.y + 12.0);
            CGContextAddLineToPoint(ctx, chkBox.origin.x + 10.0, chkBox.origin.y + 6.0);
            CGContextAddLineToPoint(ctx, chkBox.origin.x + 19.0, chkBox.origin.y + 17.0);
            CGContextStrokePath(ctx);
        } else {
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.3] CGColor]);
            CGContextSetLineWidth(ctx, 1.5);
            CGContextStrokePath(ctx);
        }
        
        NSArray *rowTexts = @[@"Inspect View Hierarchy", @"Bind Event Handlers", @"Extract Behavioral Graph"];
        NSDictionary *rtAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightMedium],
            NSForegroundColorAttributeName: (checked ? [NSColor colorWithWhite:0.95 alpha:0.95] : [NSColor colorWithWhite:0.6 alpha:0.7]),
            NSKernAttributeName: @(0.8)
        };
        NSAttributedString *rtStr = [[NSAttributedString alloc] initWithString:rowTexts[k] attributes:rtAttrs];
        [rtStr drawAtPoint:NSMakePoint(chkBox.origin.x + 36.0, rowRect.origin.y + 17.0)];
    }
    
    // Right: Connected Result / Slide-out Inspector Panel (Opens at t = 1.4s)
    double panelOpen = easeOutCubic(clampd((t - 1.2) / 1.5, 0.0, 1.0));
    CGFloat rightPanelX = 80.0 + (1.0 - panelOpen) * 60.0;
    CGRect rightCard = CGRectMake(rightPanelX, -260, 500, 520);
    
    drawRoundedRectPath(ctx, rightCard, 18.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.08 green:0.09 blue:0.13 alpha:0.92 * panelOpen] CGColor]);
    CGContextFillPath(ctx);
    drawRoundedRectPath(ctx, rightCard, 18.0);
    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.25 green:0.65 blue:1.0 alpha:0.4 * panelOpen] CGColor]);
    CGContextSetLineWidth(ctx, 1.2);
    CGContextStrokePath(ctx);
    
    if (panelOpen > 0.05) {
        NSDictionary *rcTitleAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.3 green:0.75 blue:1.0 alpha:panelOpen],
            NSKernAttributeName: @(1.5)
        };
        NSAttributedString *rctStr = [[NSAttributedString alloc] initWithString:@"OBSERVED STATE TRANSITION LOG" attributes:rcTitleAttrs];
        [rctStr drawAtPoint:NSMakePoint(rightCard.origin.x + 28.0, rightCard.origin.y + rightCard.size.height - 45.0)];
        
        NSArray *logs = @[
            @"• [EVENT] onClick -> TriggerButton#btn_42",
            @"• [DISPATCH] action: { type: 'APP_STATE_MUTATE' }",
            @"• [MUTATION] payload: { target: 'ChecklistGrid' }",
            @"• [TELEMETRY] latency: 1.2ms | diff: 3 DOM Nodes",
            @"• [RECONSTRUCTION] Deterministic handler verified ✓"
        ];
        for (NSUInteger lg = 0; lg < logs.count; lg++) {
            NSDictionary *lgAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
                NSForegroundColorAttributeName: [NSColor colorWithWhite:0.8 alpha:0.85 * panelOpen],
                NSKernAttributeName: @(0.5)
            };
            NSAttributedString *lgStr = [[NSAttributedString alloc] initWithString:logs[lg] attributes:lgAttrs];
            [lgStr drawAtPoint:NSMakePoint(rightCard.origin.x + 28.0, rightCard.origin.y + rightCard.size.height - 95.0 - lg * 45.0)];
        }
    }
    
    // Luminous Vector Connecting Tracer Lines
    if (t > 1.2) {
        double lineProgress = easeOutCubic(clampd((t - 1.2) / 1.0, 0.0, 1.0));
        CGPoint pStart = CGPointMake(btnRect.origin.x + btnRect.size.width, btnRect.origin.y + btnRect.size.height * 0.5);
        CGPoint pEnd = CGPointMake(rightCard.origin.x, rightCard.origin.y + rightCard.size.height - 110.0);
        CGPoint pCurrent = CGPointMake(pStart.x + (pEnd.x - pStart.x) * lineProgress, pStart.y + (pEnd.y - pStart.y) * lineProgress);
        
        CGContextSaveGState(ctx);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.25 green:0.65 blue:1.0 alpha:0.75] CGColor]);
        CGContextSetLineWidth(ctx, 2.0);
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, pStart.x, pStart.y);
        CGContextAddCurveToPoint(ctx, pStart.x + 80.0, pStart.y, pEnd.x - 80.0, pEnd.y, pCurrent.x, pCurrent.y);
        CGContextStrokePath(ctx);
        
        // Traveling energy particle pulse along the line
        double pulseT = fmod((t - 1.2) * 1.5, 1.0);
        double px = pStart.x + (pEnd.x - pStart.x) * pulseT;
        double py = pStart.y + (pEnd.y - pStart.y) * pulseT;
        CGContextAddEllipseInRect(ctx, CGRectMake(px - 5.0, py - 5.0, 10.0, 10.0));
        CGContextSetFillColorWithColor(ctx, [[NSColor whiteColor] CGColor]);
        CGContextFillPath(ctx);
        CGContextRestoreGState(ctx);
    }
    
    CGContextRestoreGState(ctx);
    if (t > 4.4) {
        double fo = clampd((t - 4.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.02 green:0.02 blue:0.03 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 5: Feature Analysis (Frames 1380 - 1679, 23.0s - 28.0s)
static void renderShot5(CGContextRef ctx, int frame) {
    double t = (frame - 1380) / FPS; // 0.0 to 5.0
    
    drawStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);
    
    // Top Headline
    double headAlpha = easeOutCubic(clampd(t / 1.2, 0.0, 1.0));
    NSDictionary *headAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:44 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.98 alpha:headAlpha],
        NSKernAttributeName: @(1.5)
    };
    NSAttributedString *headStr = [[NSAttributedString alloc] initWithString:@"Feature Analysis" attributes:headAttrs];
    CGSize headSz = [headStr size];
    [headStr drawAtPoint:NSMakePoint((WIDTH - headSz.width) * 0.5, HEIGHT - 150)];
    
    // Tracked-out restrained pill labels: PAGES · TEXT BLOCKS · CHECKLISTS
    NSDictionary *pillAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.3 green:0.68 blue:1.0 alpha:0.95 * headAlpha],
        NSKernAttributeName: @(4.0)
    };
    NSAttributedString *pillStr = [[NSAttributedString alloc] initWithString:@"PAGES  ·  TEXT BLOCKS  ·  CHECKLISTS" attributes:pillAttrs];
    CGSize pillSz = [pillStr size];
    [pillStr drawAtPoint:NSMakePoint((WIDTH - pillSz.width) * 0.5, HEIGHT - 195)];
    
    // Three Elements glide in sequentially with physical spring easing:
    // Element 1: Page (t = 0.4s)
    // Element 2: Text Block (t = 1.4s)
    // Element 3: Checklist (t = 2.4s)
    
    CGFloat colW = 460.0;
    CGFloat colH = 560.0;
    CGFloat gap = 48.0;
    CGFloat totalW = 3 * colW + 2 * gap;
    CGFloat startX = (WIDTH - totalW) * 0.5;
    CGFloat cardY = 120.0;
    
    for (int i = 0; i < 3; i++) {
        double startTime = 0.4 + i * 1.0;
        double progress = easeOutCubic(clampd((t - startTime) / 1.2, 0.0, 1.0));
        if (progress <= 0.001) continue;
        
        CGContextSaveGState(ctx);
        CGFloat slideOffset = (1.0 - progress) * 80.0;
        CGFloat x = startX + i * (colW + gap);
        CGFloat y = cardY - slideOffset;
        
        // Card elevation shadow
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, -25), 45.0, [[NSColor colorWithWhite:0.0 alpha:0.6 * progress] CGColor]);
        
        CGRect cardRect = CGRectMake(x, y, colW, colH);
        drawRoundedRectPath(ctx, cardRect, 20.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.08 green:0.09 blue:0.12 alpha:0.92] CGColor]);
        CGContextFillPath(ctx);
        drawRoundedRectPath(ctx, cardRect, 20.0);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.16] CGColor]);
        CGContextSetLineWidth(ctx, 1.2);
        CGContextStrokePath(ctx);
        
        // Element Badge / Pill
        NSArray *badgeTitles = @[@"PAGES", @"TEXT BLOCKS", @"CHECKLISTS"];
        CGRect badgeRect = CGRectMake(x + 28.0, y + colH - 56.0, 140.0, 32.0);
        drawRoundedRectPath(ctx, badgeRect, 16.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.16 green:0.59 blue:1.0 alpha:0.15] CGColor]);
        CGContextFillPath(ctx);
        drawRoundedRectPath(ctx, badgeRect, 16.0);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.25 green:0.65 blue:1.0 alpha:0.5] CGColor]);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextStrokePath(ctx);
        
        NSDictionary *bAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.3 green:0.75 blue:1.0 alpha:1.0],
            NSKernAttributeName: @(2.0)
        };
        NSAttributedString *bStr = [[NSAttributedString alloc] initWithString:badgeTitles[i] attributes:bAttrs];
        CGSize bSz = [bStr size];
        [bStr drawAtPoint:NSMakePoint(badgeRect.origin.x + (badgeRect.size.width - bSz.width) * 0.5, badgeRect.origin.y + 9.0)];
        
        // Specific internal mockups for each element
        if (i == 0) {
            // Page element: Document canvas preview
            CGRect docRect = CGRectMake(x + 28.0, y + 40.0, colW - 56.0, colH - 120.0);
            drawRoundedRectPath(ctx, docRect, 12.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.04] CGColor]);
            CGContextFillPath(ctx);
            
            // Document title & icon
            NSDictionary *dtAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:18 weight:NSFontWeightSemibold],
                NSForegroundColorAttributeName: [NSColor whiteColor],
                NSKernAttributeName: @(0.8)
            };
            NSAttributedString *dtStr = [[NSAttributedString alloc] initWithString:@"📄 Engineering Hub" attributes:dtAttrs];
            [dtStr drawAtPoint:NSMakePoint(docRect.origin.x + 20.0, docRect.origin.y + docRect.size.height - 45.0)];
            
            for (int l = 0; l < 6; l++) {
                CGRect lRect = CGRectMake(docRect.origin.x + 20.0, docRect.origin.y + docRect.size.height - 90.0 - l * 34.0, docRect.size.width - 40.0 - (l % 3 == 0 ? 80.0 : 0.0), 12.0);
                drawRoundedRectPath(ctx, lRect, 5.0);
                CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.14] CGColor]);
                CGContextFillPath(ctx);
            }
        } else if (i == 1) {
            // Text Block element: Rich typography preview
            CGRect docRect = CGRectMake(x + 28.0, y + 40.0, colW - 56.0, colH - 120.0);
            drawRoundedRectPath(ctx, docRect, 12.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.04] CGColor]);
            CGContextFillPath(ctx);
            
            NSDictionary *hAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:16 weight:NSFontWeightSemibold],
                NSForegroundColorAttributeName: [NSColor colorWithWhite:0.95 alpha:0.95],
                NSKernAttributeName: @(0.5)
            };
            NSAttributedString *hStr = [[NSAttributedString alloc] initWithString:@"H2 Architecture Specification" attributes:hAttrs];
            [hStr drawAtPoint:NSMakePoint(docRect.origin.x + 20.0, docRect.origin.y + docRect.size.height - 45.0)];
            
            NSArray *paragraphs = @[
                @"Autonomous agents reconstruct exact state",
                @"machines directly from interactive traces.",
                @"Zero guesswork. Deterministic components."
            ];
            for (NSUInteger p = 0; p < paragraphs.count; p++) {
                NSDictionary *pAttrs = @{
                    NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightRegular],
                    NSForegroundColorAttributeName: [NSColor colorWithWhite:0.7 alpha:0.85],
                    NSKernAttributeName: @(0.4)
                };
                NSAttributedString *pStr = [[NSAttributedString alloc] initWithString:paragraphs[p] attributes:pAttrs];
                [pStr drawAtPoint:NSMakePoint(docRect.origin.x + 20.0, docRect.origin.y + docRect.size.height - 95.0 - p * 30.0)];
            }
            
            // Code block inside text block
            CGRect codeBox = CGRectMake(docRect.origin.x + 16.0, docRect.origin.y + 30.0, docRect.size.width - 32.0, 110.0);
            drawRoundedRectPath(ctx, codeBox, 8.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.04 green:0.04 blue:0.06 alpha:0.95] CGColor]);
            CGContextFillPath(ctx);
            NSDictionary *cAttrs = @{
                NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:11] ?: [NSFont systemFontOfSize:11],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.3 green:0.75 blue:1.0 alpha:0.9],
                NSKernAttributeName: @(0.2)
            };
            NSAttributedString *cStr = [[NSAttributedString alloc] initWithString:@"export const Page = () => {\n  return <CanvasTree />;\n};" attributes:cAttrs];
            [cStr drawAtPoint:NSMakePoint(codeBox.origin.x + 14.0, codeBox.origin.y + codeBox.size.height - 50.0)];
        } else if (i == 2) {
            // Checklist element: Interactive tasks
            CGRect docRect = CGRectMake(x + 28.0, y + 40.0, colW - 56.0, colH - 120.0);
            drawRoundedRectPath(ctx, docRect, 12.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.04] CGColor]);
            CGContextFillPath(ctx);
            
            NSArray *tasks = @[
                @"DOM tree serialization",
                @"CSS style tokenization",
                @"Dynamic click handling",
                @"State reducer synthesis",
                @"Verification pass complete"
            ];
            for (NSUInteger k = 0; k < tasks.count; k++) {
                CGFloat ty = docRect.origin.y + docRect.size.height - 45.0 - k * 52.0;
                CGRect chk = CGRectMake(docRect.origin.x + 18.0, ty, 20.0, 20.0);
                drawRoundedRectPath(ctx, chk, 6.0);
                
                CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.18 green:0.8 blue:0.4 alpha:0.95] CGColor]);
                CGContextFillPath(ctx);
                
                // Tick
                CGContextSetStrokeColorWithColor(ctx, [[NSColor whiteColor] CGColor]);
                CGContextSetLineWidth(ctx, 2.0);
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, chk.origin.x + 4.0, chk.origin.y + 10.0);
                CGContextAddLineToPoint(ctx, chk.origin.x + 8.0, chk.origin.y + 5.0);
                CGContextAddLineToPoint(ctx, chk.origin.x + 16.0, chk.origin.y + 14.0);
                CGContextStrokePath(ctx);
                
                NSDictionary *tAttrs = @{
                    NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
                    NSForegroundColorAttributeName: [NSColor colorWithWhite:0.85 alpha:0.9],
                    NSKernAttributeName: @(0.5)
                };
                NSAttributedString *tStr = [[NSAttributedString alloc] initWithString:tasks[k] attributes:tAttrs];
                [tStr drawAtPoint:NSMakePoint(chk.origin.x + 30.0, ty + 2.0)];
            }
        }
        
        CGContextRestoreGState(ctx);
    }

    if (t > 4.4) {
        double fo = clampd((t - 4.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.02 green:0.02 blue:0.03 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 6: Notion Showcase (Frames 1680 - 2039, 28.0s - 34.0s)
static void renderShot6(CGContextRef ctx, int frame) {
    double t = (frame - 1680) / FPS; // 0.0 to 6.0
    
    drawStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);
    
    // Subtle camera push-in
    double push = 0.96 + 0.05 * easeInOutQuad(t / 6.0);
    
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, WIDTH * 0.5, HEIGHT * 0.48);
    CGContextScaleCTM(ctx, push, push);
    CGContextTranslateCTM(ctx, -WIDTH * 0.5, -HEIGHT * 0.48);
    
    CGFloat winW = 1320.0;
    CGFloat winH = 760.0;
    CGRect winRect = CGRectMake((WIDTH - winW) * 0.5, (HEIGHT - winH) * 0.5 - 20.0, winW, winH);
    
    // Window Shadow & Base
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, -30), 60.0, [[NSColor colorWithWhite:0.0 alpha:0.75] CGColor]);
    drawRoundedRectPath(ctx, winRect, 18.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.09 green:0.10 blue:0.12 alpha:0.96] CGColor]);
    CGContextFillPath(ctx);
    drawRoundedRectPath(ctx, winRect, 18.0);
    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.16] CGColor]);
    CGContextSetLineWidth(ctx, 1.2);
    CGContextStrokePath(ctx);
    
    // Window Title Bar
    CGRect tbRect = CGRectMake(winRect.origin.x, winRect.origin.y + winH - 48.0, winW, 48.0);
    drawRoundedRectPath(ctx, tbRect, 18.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.04] CGColor]);
    CGContextFillPath(ctx);
    
    // Traffic lights
    CGFloat dotColors[3][4] = {{1.0, 0.36, 0.33, 0.95}, {1.0, 0.74, 0.18, 0.95}, {0.18, 0.80, 0.35, 0.95}};
    for (int d = 0; d < 3; d++) {
        CGRect dot = CGRectMake(winRect.origin.x + 24.0 + d * 20.0, tbRect.origin.y + 18.0, 11.0, 11.0);
        CGContextAddEllipseInRect(ctx, dot);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:dotColors[d][0] green:dotColors[d][1] blue:dotColors[d][2] alpha:dotColors[d][3]] CGColor]);
        CGContextFillPath(ctx);
    }
    
    // Left Sidebar (Notion workspace navigation)
    CGFloat sbW = 260.0;
    CGRect sbRect = CGRectMake(winRect.origin.x + 12.0, winRect.origin.y + 12.0, sbW, winH - 68.0);
    drawRoundedRectPath(ctx, sbRect, 12.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.025] CGColor]);
    CGContextFillPath(ctx);
    
    NSArray *sbItems = @[@"WORKSPACE", @"  📂 GargProtocol", @"  📄 System Specs", @"  📄 Product Roadmap", @"  📄 REA Pipeline", @"  ⚙ Settings"];
    for (NSUInteger s = 0; s < sbItems.count; s++) {
        BOOL isHeading = (s == 0);
        BOOL isActive = (s == 3);
        if (isActive) {
            CGRect activePill = CGRectMake(sbRect.origin.x + 8.0, sbRect.origin.y + sbRect.size.height - 40.0 - s * 34.0 - 4.0, sbW - 16.0, 30.0);
            drawRoundedRectPath(ctx, activePill, 8.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.08] CGColor]);
            CGContextFillPath(ctx);
        }
        NSDictionary *sbAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:(isHeading ? 11 : 13) weight:(isHeading ? NSFontWeightBold : (isActive ? NSFontWeightSemibold : NSFontWeightRegular))],
            NSForegroundColorAttributeName: (isHeading ? [NSColor colorWithWhite:0.5 alpha:0.8] : (isActive ? [NSColor whiteColor] : [NSColor colorWithWhite:0.7 alpha:0.85])),
            NSKernAttributeName: @(isHeading ? 2.0 : 0.5)
        };
        NSAttributedString *sbStr = [[NSAttributedString alloc] initWithString:sbItems[s] attributes:sbAttrs];
        [sbStr drawAtPoint:NSMakePoint(sbRect.origin.x + 16.0, sbRect.origin.y + sbRect.size.height - 40.0 - s * 34.0)];
    }
    
    // Main Workspace Page Content
    CGFloat contentX = winRect.origin.x + sbW + 48.0;
    CGFloat contentW = winW - sbW - 96.0;
    
    // Page Icon & Title
    double pageAppear = easeOutCubic(clampd(t / 1.5, 0.0, 1.0));
    
    // Page Icon (Notion style document icon)
    NSDictionary *iconAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:26],
    };
    NSAttributedString *iconStr = [[NSAttributedString alloc] initWithString:@"📋" attributes:iconAttrs];
    [iconStr drawAtPoint:NSMakePoint(contentX, winRect.origin.y + winH - 132.0)];

    NSDictionary *titleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:35 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.98 alpha:pageAppear],
        NSKernAttributeName: @(0.8)
    };
    NSAttributedString *titleStr = [[NSAttributedString alloc] initWithString:@"Product Roadmap & Architecture" attributes:titleAttrs];
    [titleStr drawAtPoint:NSMakePoint(contentX + 38.0, winRect.origin.y + winH - 132.0)];

    // Notion property pills
    if (pageAppear > 0.2) {
        double propAlpha = easeOutCubic(clampd((pageAppear - 0.2) / 0.8, 0.0, 1.0));
        CGFloat py = winRect.origin.y + winH - 175.0;
        
        // Property 1: Status
        CGRect statusPill = CGRectMake(contentX, py, 105.0, 24.0);
        drawRoundedRectPath(ctx, statusPill, 5.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.18 green:0.45 blue:0.85 alpha:0.25 * propAlpha] CGColor]);
        CGContextFillPath(ctx);
        NSDictionary *stAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightMedium],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.4 green:0.75 blue:1.0 alpha:0.95 * propAlpha],
            NSKernAttributeName: @(0.5)
        };
        NSAttributedString *stStr = [[NSAttributedString alloc] initWithString:@"● In Progress" attributes:stAttrs];
        [stStr drawAtPoint:NSMakePoint(contentX + 10.0, py + 5.0)];
        
        // Property 2: Engine
        CGRect engPill = CGRectMake(contentX + 115.0, py, 115.0, 24.0);
        drawRoundedRectPath(ctx, engPill, 5.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.06 * propAlpha] CGColor]);
        CGContextFillPath(ctx);
        NSDictionary *enAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: [NSColor colorWithWhite:0.75 alpha:0.85 * propAlpha],
            NSKernAttributeName: @(0.5)
        };
        NSAttributedString *enStr = [[NSAttributedString alloc] initWithString:@"Engine: REA Core" attributes:enAttrs];
        [enStr drawAtPoint:NSMakePoint(contentX + 122.0, py + 5.0)];
    }
    
    // Text Block Paragraph
    double textAppear = easeOutCubic(clampd((t - 1.0) / 1.5, 0.0, 1.0));
    if (textAppear > 0.001) {
        NSDictionary *paraAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:15 weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: [NSColor colorWithWhite:0.75 alpha:0.9 * textAppear],
            NSKernAttributeName: @(0.4)
        };
        NSAttributedString *p1 = [[NSAttributedString alloc] initWithString:@"Autonomous full-stack synthesis powered by the REA reverse-engineering engine." attributes:paraAttrs];
        [p1 drawAtPoint:NSMakePoint(contentX, winRect.origin.y + winH - 215.0)];
        NSAttributedString *p2 = [[NSAttributedString alloc] initWithString:@"Reconstructing component hierarchies, dynamic interaction models, and verified specifications." attributes:paraAttrs];
        [p2 drawAtPoint:NSMakePoint(contentX, winRect.origin.y + winH - 240.0)];
    }
    
    // Checklist Items Added & Checked Dynamically
    NSArray *checkItems = @[
        @"Deconstruct UI hierarchy and component tree",
        @"Extract dynamic state & event behaviors",
        @"Map verified API boundaries and schemas",
        @"Synthesize production-ready codebase"
    ];
    
    for (NSUInteger c = 0; c < checkItems.count; c++) {
        double itemStart = 1.8 + c * 0.9;
        double itemProgress = easeOutCubic(clampd((t - itemStart) / 0.8, 0.0, 1.0));
        if (itemProgress <= 0.001) continue;
        
        CGFloat itemY = winRect.origin.y + winH - 300.0 - c * 58.0;
        CGRect box = CGRectMake(contentX, itemY, 24.0, 24.0);
        
        // Ticking progress
        BOOL isChecked = (t > itemStart + 0.4);
        drawRoundedRectPath(ctx, box, 6.0);
        if (isChecked) {
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.18 green:0.8 blue:0.4 alpha:0.95] CGColor]);
            CGContextFillPath(ctx);
            
            // Checkmark
            CGContextSetStrokeColorWithColor(ctx, [[NSColor whiteColor] CGColor]);
            CGContextSetLineWidth(ctx, 2.2);
            CGContextBeginPath(ctx);
            CGContextMoveToPoint(ctx, box.origin.x + 5.0, box.origin.y + 12.0);
            CGContextAddLineToPoint(ctx, box.origin.x + 10.0, box.origin.y + 6.0);
            CGContextAddLineToPoint(ctx, box.origin.x + 19.0, box.origin.y + 17.0);
            CGContextStrokePath(ctx);
        } else {
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.35] CGColor]);
            CGContextSetLineWidth(ctx, 1.5);
            CGContextStrokePath(ctx);
        }
        
        NSDictionary *ciAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:17 weight:(isChecked ? NSFontWeightMedium : NSFontWeightRegular)],
            NSForegroundColorAttributeName: (isChecked ? [NSColor colorWithWhite:0.95 alpha:0.95] : [NSColor colorWithWhite:0.6 alpha:0.7]),
            NSKernAttributeName: @(0.6)
        };
        NSAttributedString *ciStr = [[NSAttributedString alloc] initWithString:checkItems[c] attributes:ciAttrs];
        [ciStr drawAtPoint:NSMakePoint(contentX + 38.0, itemY + 2.0)];
    }
    
    CGContextRestoreGState(ctx);

    if (t > 5.4) {
        double fo = clampd((t - 5.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.02 green:0.02 blue:0.03 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 7: Connect REA (Frames 2040 - 2399, 34.0s - 40.0s)
static void renderShot7(CGContextRef ctx, int frame) {
    double t = (frame - 2040) / FPS; // 0.0 to 6.0
    
    drawStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);
    
    // Background interface gently recedes
    double recede = easeOutCubic(clampd(t / 2.0, 0.0, 1.0));
    if (recede < 0.99) {
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, WIDTH * 0.5, HEIGHT * 0.5);
        double bgScale = 1.0 - 0.15 * recede;
        CGContextScaleCTM(ctx, bgScale, bgScale);
        CGContextTranslateCTM(ctx, -WIDTH * 0.5, -HEIGHT * 0.5);
        
        CGRect ghostRect = CGRectMake(WIDTH * 0.5 - 500, HEIGHT * 0.5 - 280, 1000, 560);
        drawRoundedRectPath(ctx, ghostRect, 20.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.04 * (1.0 - recede)] CGColor]);
        CGContextFillPath(ctx);
        CGContextRestoreGState(ctx);
    }
    
    // Main Headline at top: REA + AI Agent
    double headAlpha = easeOutCubic(clampd((t - 0.4) / 1.5, 0.0, 1.0));
    NSDictionary *headAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:64 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.98 alpha:headAlpha],
        NSKernAttributeName: @(2.5)
    };
    NSAttributedString *headStr = [[NSAttributedString alloc] initWithString:@"REA + AI Agent" attributes:headAttrs];
    CGSize headSz = [headStr size];
    [headStr drawAtPoint:NSMakePoint((WIDTH - headSz.width) * 0.5, HEIGHT - 180)];
    
    NSDictionary *subAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:22 weight:NSFontWeightLight],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.75 alpha:0.85 * headAlpha],
        NSKernAttributeName: @(1.2)
    };
    NSAttributedString *subStr = [[NSAttributedString alloc] initWithString:@"Empowering autonomous AI agents with precision software understanding." attributes:subAttrs];
    CGSize subSz = [subStr size];
    [subStr drawAtPoint:NSMakePoint((WIDTH - subSz.width) * 0.5, HEIGHT - 225)];
    
    // Left: Minimal Frosted White/Silver REA Tool Card
    double cardSlide = easeOutCubic(clampd((t - 0.5) / 1.5, 0.0, 1.0));
    CGFloat reaCardW = 380.0;
    CGFloat reaCardH = 240.0;
    CGFloat reaX = 400.0 - (1.0 - cardSlide) * 120.0;
    CGFloat cardY = HEIGHT * 0.44 - reaCardH * 0.5;
    CGRect reaRect = CGRectMake(reaX, cardY, reaCardW, reaCardH);
    
    CGContextSaveGState(ctx);
    // Silver card drop shadow
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, -25), 45.0, [[NSColor colorWithWhite:0.0 alpha:0.7 * cardSlide] CGColor]);
    
    // Metallic Silver Gradient Card
    drawRoundedRectPath(ctx, reaRect, 24.0);
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGFloat silverLocs[3] = {0.0, 0.5, 1.0};
    CGFloat silverComps[12] = {
        0.95, 0.96, 0.98, 0.95,
        0.82, 0.84, 0.88, 0.95,
        0.72, 0.74, 0.78, 0.95
    };
    CGGradientRef sGrad = CGGradientCreateWithColorComponents(cs, silverComps, silverLocs, 3);
    CGContextSaveGState(ctx);
    CGContextClip(ctx);
    CGContextDrawLinearGradient(ctx, sGrad, CGPointMake(reaX, cardY + reaCardH), CGPointMake(reaX + reaCardW, cardY), 0);
    CGGradientRelease(sGrad);
    CGColorSpaceRelease(cs);
    CGContextRestoreGState(ctx);
    
    // REA Bold Title inside Card
    NSDictionary *rcAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:54 weight:NSFontWeightHeavy],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.08 green:0.09 blue:0.12 alpha:0.95],
        NSKernAttributeName: @(4.0)
    };
    NSAttributedString *rcStr = [[NSAttributedString alloc] initWithString:@"REA" attributes:rcAttrs];
    [rcStr drawAtPoint:NSMakePoint(reaX + 36.0, cardY + reaCardH - 95.0)];
    
    NSDictionary *rcSubAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.25 green:0.28 blue:0.35 alpha:0.85],
        NSKernAttributeName: @(1.5)
    };
    NSAttributedString *rcSubStr = [[NSAttributedString alloc] initWithString:@"CORE ENGINE // API" attributes:rcSubAttrs];
    [rcSubStr drawAtPoint:NSMakePoint(reaX + 38.0, cardY + reaCardH - 128.0)];
    
    NSDictionary *rcBrandAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.35 green:0.38 blue:0.45 alpha:0.75],
        NSKernAttributeName: @(2.0)
    };
    NSAttributedString *rcBrandStr = [[NSAttributedString alloc] initWithString:@"GARGPROTOCOL VERIFIED" attributes:rcBrandAttrs];
    [rcBrandStr drawAtPoint:NSMakePoint(reaX + 38.0, cardY + 28.0)];
    
    // Connection Port Node on Right Edge of REA Card
    CGPoint portREA = CGPointMake(reaX + reaCardW, cardY + reaCardH * 0.5);
    CGContextAddEllipseInRect(ctx, CGRectMake(portREA.x - 8.0, portREA.y - 8.0, 16.0, 16.0));
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.16 green:0.59 blue:1.0 alpha:1.0] CGColor]);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
    
    // Right: Minimal AI Agent Symbol
    double agentSlide = easeOutCubic(clampd((t - 0.7) / 1.5, 0.0, 1.0));
    CGFloat agentX = 1420.0 + (1.0 - agentSlide) * 120.0;
    CGFloat agentY = cardY + reaCardH * 0.5;
    CGPoint portAgent = CGPointMake(agentX - 110.0, agentY);
    
    CGContextSaveGState(ctx);
    // Concentric orbital rings
    for (int r = 3; r >= 1; r--) {
        CGFloat rad = 35.0 * r;
        CGRect ringRect = CGRectMake(agentX - rad, agentY - rad, rad * 2, rad * 2);
        CGContextAddEllipseInRect(ctx, ringRect);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.25 green:0.65 blue:1.0 alpha:(0.2 + 0.15 * r)] CGColor]);
        CGContextSetLineWidth(ctx, 1.5);
        CGContextStrokePath(ctx);
    }
    
    // Glowing Core Node
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), 30.0, [[NSColor colorWithCalibratedRed:0.3 green:0.75 blue:1.0 alpha:0.9] CGColor]);
    CGRect coreRect = CGRectMake(agentX - 22.0, agentY - 22.0, 44.0, 44.0);
    CGContextAddEllipseInRect(ctx, coreRect);
    CGContextSetFillColorWithColor(ctx, [[NSColor whiteColor] CGColor]);
    CGContextFillPath(ctx);
    
    // Agent Label
    NSDictionary *agAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:18 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSKernAttributeName: @(1.5)
    };
    NSAttributedString *agStr = [[NSAttributedString alloc] initWithString:@"Autonomous Agent" attributes:agAttrs];
    CGSize agSz = [agStr size];
    [agStr drawAtPoint:NSMakePoint(agentX - agSz.width * 0.5, agentY - 140.0)];
    
    NSDictionary *agSubAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.7 alpha:0.8],
        NSKernAttributeName: @(1.0)
    };
    NSAttributedString *agSubStr = [[NSAttributedString alloc] initWithString:@"Code Synthesis & Execution" attributes:agSubAttrs];
    CGSize agSubSz = [agSubStr size];
    [agSubStr drawAtPoint:NSMakePoint(agentX - agSubSz.width * 0.5, agentY - 165.0)];
    
    CGContextRestoreGState(ctx);
    
    // Connecting Line & Pulse
    if (t > 1.8) {
        double lineProgress = easeOutCubic(clampd((t - 1.8) / 1.2, 0.0, 1.0));
        CGPoint pCurrent = CGPointMake(portREA.x + (portAgent.x - portREA.x) * lineProgress, portREA.y);
        
        CGContextSaveGState(ctx);
        // Soft blue connection beam
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.25 green:0.65 blue:1.0 alpha:0.85] CGColor]);
        CGContextSetLineWidth(ctx, 3.0);
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, portREA.x, portREA.y);
        CGContextAddLineToPoint(ctx, pCurrent.x, pCurrent.y);
        CGContextStrokePath(ctx);
        
        // Traveling Pulse
        if (lineProgress >= 1.0) {
            double pulseAge = t - 3.0;
            if (pulseAge > 0.0) {
                double pulseRad = 15.0 + 40.0 * easeOutCubic(fmod(pulseAge * 1.5, 1.0));
                double pulseOpacity = 1.0 - easeOutCubic(fmod(pulseAge * 1.5, 1.0));
                
                CGRect pr = CGRectMake(portAgent.x - pulseRad, portAgent.y - pulseRad, pulseRad * 2, pulseRad * 2);
                CGContextAddEllipseInRect(ctx, pr);
                CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.4 green:0.8 blue:1.0 alpha:pulseOpacity] CGColor]);
                CGContextSetLineWidth(ctx, 2.0);
                CGContextStrokePath(ctx);
            }
        }
        CGContextRestoreGState(ctx);
    }
    
    // Bottom Tutorial Transition Card
    if (t > 3.6) {
        double cardAlpha = easeOutCubic(clampd((t - 3.6) / 1.0, 0.0, 1.0));
        NSDictionary *trAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.3 green:0.7 blue:1.0 alpha:0.9 * cardAlpha],
            NSKernAttributeName: @(3.0)
        };
        NSAttributedString *trStr = [[NSAttributedString alloc] initWithString:@"STARTING CONFIGURATION TUTORIAL..." attributes:trAttrs];
        CGSize trSz = [trStr size];
        [trStr drawAtPoint:NSMakePoint((WIDTH - trSz.width) * 0.5, 80)];
    }
    
    // Cinematic fade out at 5.4s - 6.0s
    if (t > 5.4) {
        double fadeOut = clampd((t - 5.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:0.0 alpha:fadeOut] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Master Render Function
int main(int argc, char *argv[]) {
    @autoreleasepool {
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
        CGContextSetAllowsFontSubpixelQuantization(ctx, true);
        CGContextSetShouldSubpixelQuantizeFonts(ctx, true);
        
        void *data = CGBitmapContextGetData(ctx);
        
        // Mode 1: Single Frame preview mode: e.g. `./renderer --frame 200 /tmp/frame.png`
        if (argc >= 4 && strcmp(argv[1], "--frame") == 0) {
            int frame = atoi(argv[2]);
            const char *outPath = argv[3];
            
            CGContextClearRect(ctx, CGRectMake(0, 0, w, h));
            NSGraphicsContext *nsCtx = [NSGraphicsContext graphicsContextWithCGContext:ctx flipped:NO];
            [NSGraphicsContext setCurrentContext:nsCtx];
            
            if (frame < 360) renderShot1(ctx, frame);
            else if (frame < 720) renderShot2(ctx, frame);
            else if (frame < 1080) renderShot3(ctx, frame);
            else if (frame < 1380) renderShot4(ctx, frame);
            else if (frame < 1680) renderShot5(ctx, frame);
            else if (frame < 2040) renderShot6(ctx, frame);
            else renderShot7(ctx, frame);
            
            CGImageRef img = CGBitmapContextCreateImage(ctx);
            NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
            NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
            [pngData writeToFile:[NSString stringWithUTF8String:outPath] atomically:YES];
            CGImageRelease(img);
            fprintf(stderr, "Frame %d exported to %s\n", frame, outPath);
            return 0;
        }
        
        // Mode 2: Full video pipe mode
        fprintf(stderr, "Rendering all %d frames at %dx%d (60 fps)...\n", TOTAL_FRAMES, w, h);
        
        for (int frame = 0; frame < TOTAL_FRAMES; frame++) {
            CGContextClearRect(ctx, CGRectMake(0, 0, w, h));
            NSGraphicsContext *nsCtx = [NSGraphicsContext graphicsContextWithCGContext:ctx flipped:NO];
            [NSGraphicsContext setCurrentContext:nsCtx];
            
            if (frame < 360) renderShot1(ctx, frame);
            else if (frame < 720) renderShot2(ctx, frame);
            else if (frame < 1080) renderShot3(ctx, frame);
            else if (frame < 1380) renderShot4(ctx, frame);
            else if (frame < 1680) renderShot5(ctx, frame);
            else if (frame < 2040) renderShot6(ctx, frame);
            else renderShot7(ctx, frame);
            
            write(STDOUT_FILENO, data, bytesPerRow * h);
            
            if (frame % 120 == 0) {
                fprintf(stderr, "Rendered frame %d / %d (%.1f%%)\n", frame, TOTAL_FRAMES, (frame * 100.0) / TOTAL_FRAMES);
            }
        }
        
        fprintf(stderr, "Finished rendering all %d frames!\n", TOTAL_FRAMES);
        CGContextRelease(ctx);
        CGColorSpaceRelease(cs);
    }
    return 0;
}
