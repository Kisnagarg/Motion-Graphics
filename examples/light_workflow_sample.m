#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>
#import <unistd.h>

#define WIDTH 1920
#define HEIGHT 1080
#define TOTAL_FRAMES 3360
#define FPS 60.0

// Helper functions & easing
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

static inline double easeInOutQuad(double t) {
    t = clampd(t, 0.0, 1.0);
    return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
}

static void drawRoundedRectPath(CGContextRef ctx, CGRect rect, CGFloat r) {
    CGPathRef path = CGPathCreateWithRoundedRect(rect, r, r, NULL);
    CGContextAddPath(ctx, path);
    CGPathRelease(path);
}

// Light Studio Background (Apple signature light aesthetic)
static void drawLightStudioBackground(CGContextRef ctx, double t, double intensity) {
    // Solid base: warm light studio gray #F5F5F7
    CGContextSetRGBFillColor(ctx, 0.96, 0.96, 0.97, 1.0);
    CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[3] = {0.0, 0.6, 1.0};
    CGFloat components[12] = {
        1.0, 1.0, 1.0, 1.0,                  // pure soft white spotlight center
        0.965, 0.965, 0.975, 1.0,            // gentle studio falloff
        0.915, 0.915, 0.925, 1.0             // subtle vignette floor edge
    };
    CGGradientRef grad = CGGradientCreateWithColorComponents(cs, components, locations, 3);
    CGPoint center = CGPointMake(WIDTH * 0.5, HEIGHT * 0.68);
    CGContextDrawRadialGradient(ctx, grad, center, 0.0, center, WIDTH * 0.85, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(grad);
    CGColorSpaceRelease(cs);
}

static void drawGargProtocolWatermark(CGContextRef ctx, double alpha) {
    if (alpha <= 0.01) return;
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:0.45 * alpha],
        NSKernAttributeName: @(5.0)
    };
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"GARGPROTOCOL" attributes:attrs];
    [str drawAtPoint:NSMakePoint(80, HEIGHT - 70)];
    
    NSDictionary *metaAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.43 alpha:0.45 * alpha],
        NSKernAttributeName: @(3.0)
    };
    NSAttributedString *metaStr = [[NSAttributedString alloc] initWithString:@"REA // SECTION 2: RESULTS & CONCLUSION" attributes:metaAttrs];
    CGSize sz = [metaStr size];
    [metaStr drawAtPoint:NSMakePoint(WIDTH - 80 - sz.width, HEIGHT - 70)];
}

// Shot 1: The Experiment in One View (04:04 - 04:11, Frames 0 - 419, 7.0s)
static void renderShot1(CGContextRef ctx, int frame) {
    double t = frame / FPS; // 0.0 to 7.0s
    drawLightStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);

    double camPush = 0.96 + 0.05 * easeInOutQuad(t / 7.0);
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, WIDTH * 0.5, HEIGHT * 0.5);
    CGContextScaleCTM(ctx, camPush, camPush);
    CGContextTranslateCTM(ctx, -WIDTH * 0.5, -HEIGHT * 0.5);

    // Title at Top
    double titleAlpha = easeOutCubic(clampd(t / 1.5, 0.0, 1.0));
    NSDictionary *catAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:titleAlpha],
        NSKernAttributeName: @(4.0)
    };
    NSAttributedString *catStr = [[NSAttributedString alloc] initWithString:@"METHODOLOGY SYNTHESIS" attributes:catAttrs];
    CGSize catSz = [catStr size];
    [catStr drawAtPoint:NSMakePoint((WIDTH - catSz.width) * 0.5, HEIGHT - 150)];

    NSDictionary *titleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:38 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:titleAlpha],
        NSKernAttributeName: @(1.2)
    };
    NSAttributedString *titleStr = [[NSAttributedString alloc] initWithString:@"The Software Investigation Workflow" attributes:titleAttrs];
    CGSize titleSz = [titleStr size];
    [titleStr drawAtPoint:NSMakePoint((WIDTH - titleSz.width) * 0.5, HEIGHT - 195)];

    // Floating Window Canvas
    CGFloat winW = 1200.0;
    CGFloat winH = 580.0;
    CGFloat winX = (WIDTH - winW) * 0.5;
    CGFloat winY = HEIGHT * 0.44 - winH * 0.5;
    CGRect winRect = CGRectMake(winX, winY, winW, winH);

    double winEntry = easeOutCubic(clampd((t - 0.3) / 1.5, 0.0, 1.0));
    CGContextSaveGState(ctx);
    // Soft ambient studio shadow
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, -28), 55.0, [[NSColor colorWithCalibratedRed:0.1 green:0.15 blue:0.25 alpha:0.12 * winEntry] CGColor]);

    // Frosted Light Glass Window Base
    drawRoundedRectPath(ctx, winRect, 22.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.92] CGColor]);
    CGContextFillPath(ctx);
    drawRoundedRectPath(ctx, winRect, 22.0);
    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.82 green:0.82 blue:0.85 alpha:0.8] CGColor]);
    CGContextSetLineWidth(ctx, 1.2);
    CGContextStrokePath(ctx);

    // Window Header & Traffic Lights
    CGRect tbRect = CGRectMake(winX, winY + winH - 52.0, winW, 52.0);
    drawRoundedRectPath(ctx, tbRect, 22.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.97 alpha:0.95] CGColor]);
    CGContextFillPath(ctx);

    CGFloat dotColors[3][4] = {{1.0, 0.36, 0.33, 0.9}, {1.0, 0.74, 0.18, 0.9}, {0.18, 0.80, 0.35, 0.9}};
    for (int d = 0; d < 3; d++) {
        CGRect dot = CGRectMake(winX + 24.0 + d * 20.0, tbRect.origin.y + 20.0, 11.0, 11.0);
        CGContextAddEllipseInRect(ctx, dot);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:dotColors[d][0] green:dotColors[d][1] blue:dotColors[d][2] alpha:dotColors[d][3]] CGColor]);
        CGContextFillPath(ctx);
    }

    NSDictionary *wtAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.35 green:0.35 blue:0.38 alpha:0.9],
        NSKernAttributeName: @(0.8)
    };
    NSAttributedString *wtStr = [[NSAttributedString alloc] initWithString:@"REA Investigation Engine // Active Session" attributes:wtAttrs];
    CGSize wtSz = [wtStr size];
    [wtStr drawAtPoint:NSMakePoint((WIDTH - wtSz.width) * 0.5, tbRect.origin.y + 19.0)];
    CGContextRestoreGState(ctx);

    // Three Workflow Stages: INVESTIGATE → UNDERSTAND → PROTOTYPE
    // Sequential reveal with vertical translation and fade
    NSArray *stages = @[@"INVESTIGATE", @"UNDERSTAND", @"PROTOTYPE"];
    NSArray *stageSubs = @[
        @"Surface UI deconstruction & component isolation",
        @"Deterministic state modeling & behavioral tracing",
        @"Synthesizing verified specifications & working code"
    ];
    NSArray *icons = @[@"🔍", @"⚙️", @"⚡"];

    CGFloat cardW = 320.0;
    CGFloat cardH = 340.0;
    CGFloat startX = winX + 60.0;
    CGFloat stepX = 390.0;

    for (int i = 0; i < 3; i++) {
        double stageStart = 1.2 + i * 1.2;
        double stageProgress = easeOutCubic(clampd((t - stageStart) / 1.0, 0.0, 1.0));
        if (stageProgress <= 0.001) continue;

        CGFloat x = startX + i * stepX;
        CGFloat y = winY + 65.0 + (1.0 - stageProgress) * 40.0;
        CGRect cardRect = CGRectMake(x, y, cardW, cardH);

        CGContextSaveGState(ctx);
        // Stage card shadow
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, -12), 25.0, [[NSColor colorWithCalibratedRed:0.1 green:0.12 blue:0.2 alpha:0.07 * stageProgress] CGColor]);

        // Card background
        drawRoundedRectPath(ctx, cardRect, 16.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.98 green:0.98 blue:0.99 alpha:0.95] CGColor]);
        CGContextFillPath(ctx);
        drawRoundedRectPath(ctx, cardRect, 16.0);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.86 green:0.86 blue:0.89 alpha:0.75] CGColor]);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextStrokePath(ctx);

        // Step number pill
        CGRect numPill = CGRectMake(x + 24.0, y + cardH - 48.0, 80.0, 26.0);
        drawRoundedRectPath(ctx, numPill, 13.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.1] CGColor]);
        CGContextFillPath(ctx);

        NSDictionary *npAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:1.0],
            NSKernAttributeName: @(1.5)
        };
        NSAttributedString *npStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"STEP 0%d", i + 1] attributes:npAttrs];
        CGSize npSz = [npStr size];
        [npStr drawAtPoint:NSMakePoint(numPill.origin.x + (numPill.size.width - npSz.width) * 0.5, numPill.origin.y + 6.0)];

        // Icon
        NSDictionary *icAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:36]};
        NSAttributedString *icStr = [[NSAttributedString alloc] initWithString:icons[i] attributes:icAttrs];
        [icStr drawAtPoint:NSMakePoint(x + 24.0, y + cardH - 110.0)];

        // Word (INVESTIGATE / UNDERSTAND / PROTOTYPE)
        NSDictionary *wAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:22 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:0.95],
            NSKernAttributeName: @(1.5)
        };
        NSAttributedString *wStr = [[NSAttributedString alloc] initWithString:stages[i] attributes:wAttrs];
        [wStr drawAtPoint:NSMakePoint(x + 24.0, y + cardH - 150.0)];

        // Subtitle description
        NSDictionary *descAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.45 green:0.45 blue:0.48 alpha:0.9],
            NSKernAttributeName: @(0.3)
        };
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.lineSpacing = 4.0;
        NSMutableDictionary *descAttrsP = [descAttrs mutableCopy];
        descAttrsP[NSParagraphStyleAttributeName] = ps;

        NSAttributedString *descStr = [[NSAttributedString alloc] initWithString:stageSubs[i] attributes:descAttrsP];
        CGRect descRect = CGRectMake(x + 24.0, y + 20.0, cardW - 48.0, 90.0);
        [descStr drawInRect:descRect];

        CGContextRestoreGState(ctx);

        // Arrow between cards (if not last card)
        if (i < 2 && t > stageStart + 0.8) {
            double arrowProgress = easeOutCubic(clampd((t - (stageStart + 0.8)) / 0.5, 0.0, 1.0));
            CGFloat ax = x + cardW + 18.0;
            CGFloat ay = y + cardH * 0.5;

            CGContextSaveGState(ctx);
            NSDictionary *arrAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:24 weight:NSFontWeightBold],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.75 * arrowProgress]
            };
            NSAttributedString *arrStr = [[NSAttributedString alloc] initWithString:@"→" attributes:arrAttrs];
            [arrStr drawAtPoint:NSMakePoint(ax, ay - 12.0)];
            CGContextRestoreGState(ctx);
        }
    }

    CGContextRestoreGState(ctx);

    // Cross-fade out at end of shot
    if (t > 6.4) {
        double fo = clampd((t - 6.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.97 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 2: Selected Features Come to Life (04:11 - 04:17, Frames 420 - 779, 6.0s)
static void renderShot2(CGContextRef ctx, int frame) {
    double t = (frame - 420) / FPS; // 0.0 to 6.0s
    drawLightStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);

    // Caption at top: SELECTED FEATURES, RECREATED
    double capAlpha = easeOutCubic(clampd(t / 1.2, 0.0, 1.0));
    NSDictionary *capAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:capAlpha],
        NSKernAttributeName: @(4.0)
    };
    NSAttributedString *capStr = [[NSAttributedString alloc] initWithString:@"SELECTED FEATURES, RECREATED" attributes:capAttrs];
    CGSize capSz = [capStr size];
    [capStr drawAtPoint:NSMakePoint((WIDTH - capSz.width) * 0.5, HEIGHT - 150)];

    NSDictionary *titleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:36 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:capAlpha],
        NSKernAttributeName: @(1.0)
    };
    NSAttributedString *titleStr = [[NSAttributedString alloc] initWithString:@"Notion-Inspired Prototype Components" attributes:titleAttrs];
    CGSize titleSz = [titleStr size];
    [titleStr drawAtPoint:NSMakePoint((WIDTH - titleSz.width) * 0.5, HEIGHT - 195)];

    // Three UI elements assemble into workspace:
    // 1. Page with Title (t = 0.4s)
    // 2. Text Block with Heading (t = 1.4s)
    // 3. Checklist with Animated Checkboxes (t = 2.4s)

    CGFloat colW = 460.0;
    CGFloat colH = 580.0;
    CGFloat gap = 48.0;
    CGFloat totalW = 3 * colW + 2 * gap;
    CGFloat startX = (WIDTH - totalW) * 0.5;
    CGFloat cardY = 120.0;

    for (int i = 0; i < 3; i++) {
        double startTime = 0.4 + i * 1.0;
        double progress = easeOutCubic(clampd((t - startTime) / 1.2, 0.0, 1.0));
        if (progress <= 0.001) continue;

        CGFloat x = startX + i * (colW + gap);
        CGFloat slideOffset = (1.0 - progress) * 70.0;
        CGFloat y = cardY - slideOffset;
        CGRect cRect = CGRectMake(x, y, colW, colH);

        CGContextSaveGState(ctx);
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, -22), 40.0, [[NSColor colorWithCalibratedRed:0.1 green:0.12 blue:0.2 alpha:0.09 * progress] CGColor]);

        drawRoundedRectPath(ctx, cRect, 20.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.95] CGColor]);
        CGContextFillPath(ctx);
        drawRoundedRectPath(ctx, cRect, 20.0);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.84 green:0.84 blue:0.87 alpha:0.85] CGColor]);
        CGContextSetLineWidth(ctx, 1.2);
        CGContextStrokePath(ctx);

        // Header Pill Badge
        NSArray *badges = @[@"PAGE CONTAINER", @"TEXT BLOCK", @"INTERACTIVE CHECKLIST"];
        CGFloat bW = (i == 2 ? 195.0 : (i == 0 ? 150.0 : 120.0)); CGRect bRect = CGRectMake(x + 28.0, y + colH - 54.0, bW, 30.0);
        drawRoundedRectPath(ctx, bRect, 15.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.09] CGColor]);
        CGContextFillPath(ctx);
        NSDictionary *bAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:1.0],
            NSKernAttributeName: @(1.5)
        };
        NSAttributedString *bStr = [[NSAttributedString alloc] initWithString:badges[i] attributes:bAttrs];
        CGSize bSz = [bStr size];
        [bStr drawAtPoint:NSMakePoint(bRect.origin.x + (bRect.size.width - bSz.width) * 0.5, bRect.origin.y + 8.0)];

        if (i == 0) {
            // Page with Title
            NSDictionary *icAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:34]};
            NSAttributedString *icStr = [[NSAttributedString alloc] initWithString:@"📑" attributes:icAttrs];
            [icStr drawAtPoint:NSMakePoint(x + 28.0, y + colH - 120.0)];

            NSDictionary *ptAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:22 weight:NSFontWeightBold],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:0.95],
                NSKernAttributeName: @(0.8)
            };
            NSAttributedString *ptStr = [[NSAttributedString alloc] initWithString:@"Workspace Page" attributes:ptAttrs];
            [ptStr drawAtPoint:NSMakePoint(x + 28.0, y + colH - 160.0)];

            // Properties
            CGRect propPill = CGRectMake(x + 28.0, y + colH - 200.0, 110.0, 24.0);
            drawRoundedRectPath(ctx, propPill, 6.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.92 green:0.93 blue:0.95 alpha:1.0] CGColor]);
            CGContextFillPath(ctx);
            NSDictionary *propAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightMedium],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.45 alpha:1.0],
                NSKernAttributeName: @(0.5)
            };
            NSAttributedString *propStr = [[NSAttributedString alloc] initWithString:@"Status: Recreated" attributes:propAttrs];
            [propStr drawAtPoint:NSMakePoint(x + 36.0, y + colH - 195.0)];

            for (int l = 0; l < 5; l++) {
                CGRect lRect = CGRectMake(x + 28.0, y + 180.0 - l * 34.0, colW - 56.0 - (l % 2 == 1 ? 60.0 : 0.0), 12.0);
                drawRoundedRectPath(ctx, lRect, 5.0);
                CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.92 alpha:1.0] CGColor]);
                CGContextFillPath(ctx);
            }
        } else if (i == 1) {
            // Text Block with Heading
            NSDictionary *hAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:20 weight:NSFontWeightBold],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:0.95],
                NSKernAttributeName: @(0.6)
            };
            NSAttributedString *hStr = [[NSAttributedString alloc] initWithString:@"H2 Subheading Block" attributes:hAttrs];
            [hStr drawAtPoint:NSMakePoint(x + 28.0, y + colH - 120.0)];

            NSArray *paras = @[
                @"Extracted paragraph block with inline tokens.",
                @"Reimplemented in standalone lightweight",
                @"React component without vendor lock-in.",
                @"Deterministic typography scale and margins."
            ];
            for (NSUInteger p = 0; p < paras.count; p++) {
                NSDictionary *pAttrs = @{
                    NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightRegular],
                    NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.35 green:0.35 blue:0.38 alpha:0.9],
                    NSKernAttributeName: @(0.3)
                };
                NSAttributedString *pStr = [[NSAttributedString alloc] initWithString:paras[p] attributes:pAttrs];
                [pStr drawAtPoint:NSMakePoint(x + 28.0, y + colH - 165.0 - p * 30.0)];
            }

            // Code snippet container
            CGRect codeBox = CGRectMake(x + 24.0, y + 40.0, colW - 48.0, 110.0);
            drawRoundedRectPath(ctx, codeBox, 10.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.94 green:0.95 blue:0.97 alpha:1.0] CGColor]);
            CGContextFillPath(ctx);
            NSDictionary *cAttrs = @{
                NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:11] ?: [NSFont systemFontOfSize:11],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.9]
            };
            NSAttributedString *cStr = [[NSAttributedString alloc] initWithString:@"// Isolated React Block\nexport function TextBlock() {\n  return <EditableContent />;\n}" attributes:cAttrs];
            [cStr drawAtPoint:NSMakePoint(codeBox.origin.x + 16.0, codeBox.origin.y + codeBox.size.height - 55.0)];
        } else if (i == 2) {
            // Checklist with Animated Checkboxes
            NSArray *tasks = @[
                @"Page structure extraction",
                @"Typography token mapping",
                @"Checkbox toggle state",
                @"Local storage persistence",
                @"Verified unit tests pass"
            ];
            for (NSUInteger k = 0; k < tasks.count; k++) {
                CGFloat ty = y + colH - 120.0 - k * 56.0;
                CGRect chk = CGRectMake(x + 28.0, ty, 22.0, 22.0);
                drawRoundedRectPath(ctx, chk, 6.0);

                BOOL checked = (k < 3) || (k == 3 && t > 4.2);
                if (checked) {
                    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.18 green:0.8 blue:0.4 alpha:0.95] CGColor]);
                    CGContextFillPath(ctx);

                    CGContextSetStrokeColorWithColor(ctx, [[NSColor whiteColor] CGColor]);
                    CGContextSetLineWidth(ctx, 2.0);
                    CGContextBeginPath(ctx);
                    CGContextMoveToPoint(ctx, chk.origin.x + 5.0, chk.origin.y + 11.0);
                    CGContextAddLineToPoint(ctx, chk.origin.x + 9.0, chk.origin.y + 6.0);
                    CGContextAddLineToPoint(ctx, chk.origin.x + 17.0, chk.origin.y + 15.0);
                    CGContextStrokePath(ctx);
                } else {
                    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.78 alpha:1.0] CGColor]);
                    CGContextSetLineWidth(ctx, 1.5);
                    CGContextStrokePath(ctx);
                }

                NSDictionary *tAttrs = @{
                    NSFontAttributeName: [NSFont systemFontOfSize:14 weight:(checked ? NSFontWeightMedium : NSFontWeightRegular)],
                    NSForegroundColorAttributeName: (checked ? [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:0.95] : [NSColor colorWithCalibratedRed:0.55 green:0.55 blue:0.58 alpha:0.8]),
                    NSKernAttributeName: @(0.4)
                };
                NSAttributedString *tStr = [[NSAttributedString alloc] initWithString:tasks[k] attributes:tAttrs];
                [tStr drawAtPoint:NSMakePoint(chk.origin.x + 36.0, ty + 2.0)];
            }
        }

        CGContextRestoreGState(ctx);
    }

    if (t > 5.4) {
        double fo = clampd((t - 5.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.97 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 3: The Limitation Reveal (04:17 - 04:25, Frames 780 - 1259, 8.0s)
static void renderShot3(CGContextRef ctx, int frame) {
    double t = (frame - 780) / FPS; // 0.0 to 8.0s
    drawLightStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);

    // Headline: A PROTOTYPE, NOT A FULL REPLACEMENT
    double headAlpha = easeOutCubic(clampd(t / 1.5, 0.0, 1.0));
    NSDictionary *catAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:headAlpha],
        NSKernAttributeName: @(4.0)
    };
    NSAttributedString *catStr = [[NSAttributedString alloc] initWithString:@"ACCURATE SCOPE & BOUNDARIES" attributes:catAttrs];
    CGSize catSz = [catStr size];
    [catStr drawAtPoint:NSMakePoint((WIDTH - catSz.width) * 0.5, HEIGHT - 150)];

    NSDictionary *headAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:38 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:headAlpha],
        NSKernAttributeName: @(1.2)
    };
    NSAttributedString *headStr = [[NSAttributedString alloc] initWithString:@"A Prototype, Not a Full Replacement" attributes:headAttrs];
    CGSize headSz = [headStr size];
    [headStr drawAtPoint:NSMakePoint((WIDTH - headSz.width) * 0.5, HEIGHT - 195)];

    // Center: Prototype Interface remains in clear, sharp focus
    CGFloat protoW = 760.0;
    CGFloat protoH = 460.0;
    CGFloat protoX = (WIDTH - protoW) * 0.5;
    CGFloat protoY = HEIGHT * 0.44 - protoH * 0.5;
    CGRect protoRect = CGRectMake(protoX, protoY, protoW, protoH);

    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, -25), 45.0, [[NSColor colorWithCalibratedRed:0.1 green:0.15 blue:0.25 alpha:0.12] CGColor]);
    drawRoundedRectPath(ctx, protoRect, 20.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.96] CGColor]);
    CGContextFillPath(ctx);
    drawRoundedRectPath(ctx, protoRect, 20.0);
    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.82 green:0.82 blue:0.85 alpha:0.9] CGColor]);
    CGContextSetLineWidth(ctx, 1.2);
    CGContextStrokePath(ctx);

    // Inner Prototype Header
    CGRect pHeader = CGRectMake(protoX, protoY + protoH - 48.0, protoW, 48.0);
    drawRoundedRectPath(ctx, pHeader, 20.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.95 green:0.96 blue:0.97 alpha:1.0] CGColor]);
    CGContextFillPath(ctx);

    NSDictionary *pTitleAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:0.9],
        NSKernAttributeName: @(1.0)
    };
    NSAttributedString *pTitleStr = [[NSAttributedString alloc] initWithString:@"Verified Component Prototype (UI & Local State)" attributes:pTitleAttrs];
    [pTitleStr drawAtPoint:NSMakePoint(protoX + 28.0, pHeader.origin.y + 16.0)];

    // Inner mock items
    for (int r = 0; r < 4; r++) {
        CGFloat ry = protoY + protoH - 110.0 - r * 68.0;
        CGRect rBox = CGRectMake(protoX + 32.0, ry, protoW - 64.0, 52.0);
        drawRoundedRectPath(ctx, rBox, 10.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.98 green:0.98 blue:0.99 alpha:1.0] CGColor]);
        CGContextFillPath(ctx);
        drawRoundedRectPath(ctx, rBox, 10.0);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.88 green:0.88 blue:0.9 alpha:0.7] CGColor]);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextStrokePath(ctx);

        NSArray *protoRows = @[@"✔  Extracted Document Canvas Component", @"✔  Structured Typography & Heading Blocks", @"✔  Interactive Checkbox Action Dispatchers", @"✔  Clean Isolated Codebase Export"];
        NSDictionary *prAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.25 green:0.25 blue:0.28 alpha:0.9],
            NSKernAttributeName: @(0.5)
        };
        NSAttributedString *prStr = [[NSAttributedString alloc] initWithString:protoRows[r] attributes:prAttrs];
        [prStr drawAtPoint:NSMakePoint(rBox.origin.x + 20.0, ry + 18.0)];
    }
    CGContextRestoreGState(ctx);

    // Around it: 3 Translucent Feature Cards that gently move backward in Z-space and fade to lower opacity
    // 1. Cloud synchronization
    // 2. Advanced databases
    // 3. Full application functionality
    double cardRecede = easeOutCubic(clampd((t - 1.5) / 2.5, 0.0, 1.0));
    double cardAlpha = 0.95 - 0.25 * cardRecede;
    double cardScale = 1.0 - 0.12 * cardRecede;

    NSArray *limTitles = @[@"Cloud Synchronization", @"Advanced Databases", @"Full Application Functionality"];
    NSArray *limIcons = @[@"☁️", @"🗄️", @"🌐"];
    NSArray *limNotes = @[
        @"Real-time multi-tenant cloud sync requires dedicated server infra.",
        @"Relational rollups and formulas remain proprietary engine features.",
        @"Reverse engineering extracts targeted components, not entire SaaS."
    ];

    // Left card, Right Top card, Right Bottom card
    CGPoint cardPositions[3] = {
        CGPointMake(protoX - 340.0 - cardRecede * 40.0, protoY + 50.0),
        CGPointMake(protoX + protoW + 40.0 + cardRecede * 40.0, protoY + 230.0),
        CGPointMake(protoX + protoW + 40.0 + cardRecede * 40.0, protoY + 20.0)
    };

    for (int c = 0; c < 3; c++) {
        CGFloat cx = cardPositions[c].x;
        CGFloat cy = cardPositions[c].y;
        CGFloat cw = 300.0 * cardScale;
        CGFloat ch = 180.0 * cardScale;
        CGRect cr = CGRectMake(cx, cy, cw, ch);

        CGContextSaveGState(ctx);
        // Translucent card styling (receding in background)
        drawRoundedRectPath(ctx, cr, 16.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.94 green:0.94 blue:0.96 alpha:cardAlpha * 0.9] CGColor]);
        CGContextFillPath(ctx);
        drawRoundedRectPath(ctx, cr, 16.0);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.8 alpha:cardAlpha] CGColor]);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextStrokePath(ctx);

        // Icon
        NSDictionary *iAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:24 * cardScale]};
        NSAttributedString *iStr = [[NSAttributedString alloc] initWithString:limIcons[c] attributes:iAttrs];
        [iStr drawAtPoint:NSMakePoint(cx + 18.0, cy + ch - 42.0 * cardScale)];

        // Title
        NSDictionary *ltAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:14 * cardScale weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.3 green:0.3 blue:0.35 alpha:cardAlpha],
            NSKernAttributeName: @(0.5)
        };
        NSAttributedString *ltStr = [[NSAttributedString alloc] initWithString:limTitles[c] attributes:ltAttrs];
        [ltStr drawAtPoint:NSMakePoint(cx + 18.0, cy + ch - 72.0 * cardScale)];

        // Scope description
        NSDictionary *ldAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:11 * cardScale weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.53 alpha:cardAlpha],
            NSKernAttributeName: @(0.3)
        };
        NSAttributedString *ldStr = [[NSAttributedString alloc] initWithString:limNotes[c] attributes:ldAttrs];
        CGRect ldr = CGRectMake(cx + 18.0, cy + 12.0, cw - 36.0, ch - 85.0 * cardScale);
        [ldStr drawInRect:ldr];

        CGContextRestoreGState(ctx);
    }

    if (t > 7.4) {
        double fo = clampd((t - 7.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.97 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 4: The Broader Application (04:25 - 04:33, Frames 1260 - 1739, 8.0s)
static void renderShot4(CGContextRef ctx, int frame) {
    double t = (frame - 1260) / FPS; // 0.0 to 8.0s
    drawLightStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);

    // Headline: CHOOSE A FEATURE
    double headAlpha = easeOutCubic(clampd(t / 1.5, 0.0, 1.0));
    NSDictionary *catAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:headAlpha],
        NSKernAttributeName: @(4.0)
    };
    NSAttributedString *catStr = [[NSAttributedString alloc] initWithString:@"UNIVERSAL EXTRACTABILITY" attributes:catAttrs];
    CGSize catSz = [catStr size];
    [catStr drawAtPoint:NSMakePoint((WIDTH - catSz.width) * 0.5, HEIGHT - 150)];

    NSDictionary *headAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:38 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:headAlpha],
        NSKernAttributeName: @(1.2)
    };
    NSAttributedString *headStr = [[NSAttributedString alloc] initWithString:@"Choose Any Feature From Any App" attributes:headAttrs];
    CGSize headSz = [headStr size];
    [headStr drawAtPoint:NSMakePoint((WIDTH - headSz.width) * 0.5, HEIGHT - 195)];

    // 3 Floating Application Windows: Dashboard, Website, Productivity Tool
    // Camera glides past them.
    // Center window's feature is selected and moves forward into foreground at t = 3.0s.
    double glide = easeInOutCubic(t / 8.0);
    double selectProgress = easeInOutCubic(clampd((t - 2.8) / 2.0, 0.0, 1.0));

    CGFloat winW = 560.0;
    CGFloat winH = 460.0;
    CGFloat gap = 60.0;
    CGFloat midX = WIDTH * 0.5;

    NSArray *apps = @[@"Analytics Dashboard", @"Component Library", @"Productivity Tool"];
    NSArray *types = @[@"Metrics & Charts", @"Selected Interactive Card", @"Kanban Task Board"];

    for (int i = 0; i < 3; i++) {
        CGContextSaveGState(ctx);

        // 3D positioning
        BOOL isCenter = (i == 1);
        CGFloat baseOffset = (i - 1) * (winW + gap);
        CGFloat x = midX + baseOffset - 30.0 * glide;
        CGFloat y = HEIGHT * 0.44 - winH * 0.5;

        CGFloat winScale = 1.0;
        CGFloat winOpacity = 1.0;

        if (isCenter) {
            // Selected feature moves forward
            winScale = 1.0 + 0.15 * selectProgress;
            y += selectProgress * 25.0;
        } else {
            // Other windows recede into background
            winScale = 1.0 - 0.15 * selectProgress;
            winOpacity = 1.0 - 0.45 * selectProgress;
        }

        CGContextTranslateCTM(ctx, x, y + winH * 0.5);
        CGContextScaleCTM(ctx, winScale, winScale);
        CGContextTranslateCTM(ctx, -winW * 0.5, -winH * 0.5);

        // Shadow
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, -20 * (isCenter ? 1.5 : 0.8)), 35.0 * (isCenter ? 1.5 : 0.8), [[NSColor colorWithCalibratedRed:0.1 green:0.15 blue:0.25 alpha:0.12 * winOpacity] CGColor]);

        CGRect wRect = CGRectMake(0, 0, winW, winH);
        drawRoundedRectPath(ctx, wRect, 18.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.95 * winOpacity] CGColor]);
        CGContextFillPath(ctx);
        drawRoundedRectPath(ctx, wRect, 18.0);

        if (isCenter && selectProgress > 0.1) {
            // Glowing border on selected center feature
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.9 * selectProgress] CGColor]);
            CGContextSetLineWidth(ctx, 2.5);
        } else {
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.84 green:0.84 blue:0.87 alpha:0.8 * winOpacity] CGColor]);
            CGContextSetLineWidth(ctx, 1.2);
        }
        CGContextStrokePath(ctx);

        // Header
        CGRect hRect = CGRectMake(0, winH - 46.0, winW, 46.0);
        drawRoundedRectPath(ctx, hRect, 18.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.97 alpha:winOpacity] CGColor]);
        CGContextFillPath(ctx);

        NSDictionary *tAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.25 alpha:winOpacity],
            NSKernAttributeName: @(0.8)
        };
        NSAttributedString *tStr = [[NSAttributedString alloc] initWithString:apps[i] attributes:tAttrs];
        [tStr drawAtPoint:NSMakePoint(24.0, hRect.origin.y + 15.0)];

        if (i == 0) {
            // Dashboard with mock charts
            for (int b = 0; b < 6; b++) {
                CGFloat bh = 60.0 + (b * 37) % 180;
                CGRect bar = CGRectMake(50.0 + b * 75.0, 50.0, 45.0, bh);
                drawRoundedRectPath(ctx, bar, 6.0);
                CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.88 green:0.90 blue:0.94 alpha:winOpacity] CGColor]);
                CGContextFillPath(ctx);
            }
        } else if (i == 1) {
            // Selected Component Feature
            CGRect cardBox = CGRectMake(36.0, 50.0, winW - 72.0, winH - 120.0);
            drawRoundedRectPath(ctx, cardBox, 14.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.98 green:0.99 blue:1.0 alpha:winOpacity] CGColor]);
            CGContextFillPath(ctx);
            drawRoundedRectPath(ctx, cardBox, 14.0);
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.4 * winOpacity] CGColor]);
            CGContextSetLineWidth(ctx, 1.5);
            CGContextStrokePath(ctx);

            NSDictionary *chAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:18 weight:NSFontWeightBold],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:winOpacity],
                NSKernAttributeName: @(0.6)
            };
            NSAttributedString *chStr = [[NSAttributedString alloc] initWithString:@"Target Component: Interactive Grid" attributes:chAttrs];
            [chStr drawAtPoint:NSMakePoint(cardBox.origin.x + 24.0, cardBox.origin.y + cardBox.size.height - 45.0)];

            // Data grid inside target component
            for (int r = 0; r < 3; r++) {
                CGRect row = CGRectMake(cardBox.origin.x + 24.0, cardBox.origin.y + cardBox.size.height - 95.0 - r * 42.0, cardBox.size.width - 48.0, 32.0);
                drawRoundedRectPath(ctx, row, 6.0);
                CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.95 green:0.96 blue:0.98 alpha:winOpacity] CGColor]);
                CGContextFillPath(ctx);
                for (int c = 0; c < 3; c++) {
                    CGRect cell = CGRectMake(row.origin.x + 16.0 + c * 140.0, row.origin.y + 10.0, 100.0, 12.0);
                    drawRoundedRectPath(ctx, cell, 4.0);
                    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.85 green:0.87 blue:0.91 alpha:winOpacity] CGColor]);
                    CGContextFillPath(ctx);
                }
            }

            if (selectProgress > 0.1) {
                // Selection badge
                CGRect selBadge = CGRectMake(cardBox.origin.x + 24.0, cardBox.origin.y + 30.0, 200.0, 36.0);
                drawRoundedRectPath(ctx, selBadge, 8.0);
                CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.95 * selectProgress] CGColor]);
                CGContextFillPath(ctx);

                NSDictionary *sbAttrs = @{
                    NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold],
                    NSForegroundColorAttributeName: [NSColor whiteColor],
                    NSKernAttributeName: @(1.0)
                };
                NSAttributedString *sbStr = [[NSAttributedString alloc] initWithString:@"FEATURE SELECTED" attributes:sbAttrs];
                CGSize sbSz = [sbStr size];
                [sbStr drawAtPoint:NSMakePoint(selBadge.origin.x + (selBadge.size.width - sbSz.width) * 0.5, selBadge.origin.y + 10.0)];
            }
        } else if (i == 2) {
            // Kanban columns
            for (int k = 0; k < 2; k++) {
                CGRect kCol = CGRectMake(40.0 + k * 240.0, 50.0, 220.0, winH - 120.0);
                drawRoundedRectPath(ctx, kCol, 10.0);
                CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.94 green:0.94 blue:0.96 alpha:winOpacity] CGColor]);
                CGContextFillPath(ctx);
            }
        }

        CGContextRestoreGState(ctx);
    }

    if (t > 7.4) {
        double fo = clampd((t - 7.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.97 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 5: From Reference to Implementation (04:33 - 04:41, Frames 1740 - 2219, 8.0s)
static void renderShot5(CGContextRef ctx, int frame) {
    double t = (frame - 1740) / FPS; // 0.0 to 8.0s
    drawLightStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);

    // Three-Stage Sequence: REFERENCE → ANALYSIS → IMPLEMENTATION
    double headAlpha = easeOutCubic(clampd(t / 1.5, 0.0, 1.0));
    NSDictionary *catAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:headAlpha],
        NSKernAttributeName: @(4.0)
    };
    NSAttributedString *catStr = [[NSAttributedString alloc] initWithString:@"END-TO-END RECONSTRUCTION" attributes:catAttrs];
    CGSize catSz = [catStr size];
    [catStr drawAtPoint:NSMakePoint((WIDTH - catSz.width) * 0.5, HEIGHT - 150)];

    NSDictionary *headAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:38 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:headAlpha],
        NSKernAttributeName: @(1.2)
    };
    NSAttributedString *headStr = [[NSAttributedString alloc] initWithString:@"Reference  ›  Analysis  ›  Implementation" attributes:headAttrs];
    CGSize headSz = [headStr size];
    [headStr drawAtPoint:NSMakePoint((WIDTH - headSz.width) * 0.5, HEIGHT - 195)];

    CGFloat stageW = 440.0;
    CGFloat stageH = 540.0;
    CGFloat gap = 80.0;
    CGFloat totalW = 3 * stageW + 2 * gap;
    CGFloat startX = (WIDTH - totalW) * 0.5;
    CGFloat stageY = 130.0;

    NSArray *titles = @[@"1. REFERENCE", @"2. ANALYSIS", @"3. IMPLEMENTATION"];
    NSArray *subheads = @[@"Live Application Component", @"Decompiled AST & Specs", @"New Production Web Mockup"];

    for (int i = 0; i < 3; i++) {
        double startTime = 0.5 + i * 1.6;
        double progress = easeOutCubic(clampd((t - startTime) / 1.2, 0.0, 1.0));
        if (progress <= 0.001) continue;

        CGFloat x = startX + i * (stageW + gap);
        CGFloat slideOffset = (1.0 - progress) * 60.0;
        CGFloat y = stageY - slideOffset;
        CGRect r = CGRectMake(x, y, stageW, stageH);

        CGContextSaveGState(ctx);
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, -18), 35.0, [[NSColor colorWithCalibratedRed:0.1 green:0.15 blue:0.25 alpha:0.09 * progress] CGColor]);

        drawRoundedRectPath(ctx, r, 20.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithWhite:1.0 alpha:0.96] CGColor]);
        CGContextFillPath(ctx);
        drawRoundedRectPath(ctx, r, 20.0);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.84 green:0.84 blue:0.87 alpha:0.85] CGColor]);
        CGContextSetLineWidth(ctx, 1.2);
        CGContextStrokePath(ctx);

        // Header Title
        NSDictionary *stAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:progress],
            NSKernAttributeName: @(1.5)
        };
        NSAttributedString *stStr = [[NSAttributedString alloc] initWithString:titles[i] attributes:stAttrs];
        [stStr drawAtPoint:NSMakePoint(x + 28.0, y + stageH - 45.0)];

        NSDictionary *subAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.45 green:0.45 blue:0.48 alpha:progress],
            NSKernAttributeName: @(0.5)
        };
        NSAttributedString *subStr = [[NSAttributedString alloc] initWithString:subheads[i] attributes:subAttrs];
        [subStr drawAtPoint:NSMakePoint(x + 28.0, y + stageH - 72.0)];

        if (i == 0) {
            // Stage 1: Reference UI (Product mockup)
            CGRect uiBox = CGRectMake(x + 24.0, y + 36.0, stageW - 48.0, stageH - 130.0);
            drawRoundedRectPath(ctx, uiBox, 12.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.98 alpha:1.0] CGColor]);
            CGContextFillPath(ctx);

            for (int l = 0; l < 4; l++) {
                CGRect lRect = CGRectMake(uiBox.origin.x + 20.0, uiBox.origin.y + uiBox.size.height - 45.0 - l * 40.0, uiBox.size.width - 40.0 - (l == 2 ? 80.0 : 0.0), 16.0);
                drawRoundedRectPath(ctx, lRect, 6.0);
                CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.85 green:0.86 blue:0.89 alpha:1.0] CGColor]);
                CGContextFillPath(ctx);
            }
            // Action button
            CGRect btn = CGRectMake(uiBox.origin.x + 20.0, uiBox.origin.y + 30.0, 140.0, 36.0);
            drawRoundedRectPath(ctx, btn, 8.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.9] CGColor]);
            CGContextFillPath(ctx);
        } else if (i == 1) {
            // Stage 2: Analysis Blueprint (AST wireframe)
            CGRect bpBox = CGRectMake(x + 24.0, y + 36.0, stageW - 48.0, stageH - 130.0);
            drawRoundedRectPath(ctx, bpBox, 12.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.94 green:0.96 blue:0.98 alpha:1.0] CGColor]);
            CGContextFillPath(ctx);

            // Wireframe blueprint grid lines
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.4] CGColor]);
            CGContextSetLineWidth(ctx, 1.0);
            CGFloat dash[2] = {4.0, 3.0};
            CGContextSetLineDash(ctx, 0, dash, 2);
            for (int w = 0; w < 3; w++) {
                CGRect wRect = CGRectMake(bpBox.origin.x + 16.0, bpBox.origin.y + bpBox.size.height - 45.0 - w * 55.0, bpBox.size.width - 32.0, 38.0);
                drawRoundedRectPath(ctx, wRect, 6.0);
                CGContextStrokePath(ctx);
            }
            CGContextSetLineDash(ctx, 0, NULL, 0);

            NSDictionary *codeAttrs = @{
                NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:11] ?: [NSFont systemFontOfSize:11],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.9]
            };
            NSAttributedString *codeStr = [[NSAttributedString alloc] initWithString:@"<ASTNode: ComponentTree>\n  props: { state, onClick }\n  reconstructed: 100%" attributes:codeAttrs];
            [codeStr drawAtPoint:NSMakePoint(bpBox.origin.x + 20.0, bpBox.origin.y + 40.0)];
        } else if (i == 2) {
            // Stage 3: Implementation in New Website
            CGRect newBox = CGRectMake(x + 24.0, y + 36.0, stageW - 48.0, stageH - 130.0);
            drawRoundedRectPath(ctx, newBox, 12.0);
            CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.98 green:0.98 blue:1.0 alpha:1.0] CGColor]);
            CGContextFillPath(ctx);
            drawRoundedRectPath(ctx, newBox, 12.0);
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.18 green:0.8 blue:0.4 alpha:0.7] CGColor]);
            CGContextSetLineWidth(ctx, 1.5);
            CGContextStrokePath(ctx);

            NSDictionary *finAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold],
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.18 green:0.8 blue:0.4 alpha:1.0]
            };
            NSAttributedString *finStr = [[NSAttributedString alloc] initWithString:@"✔ Live in Target Website" attributes:finAttrs];
            [finStr drawAtPoint:NSMakePoint(newBox.origin.x + 20.0, newBox.origin.y + newBox.size.height - 40.0)];

            for (int l = 0; l < 4; l++) {
                CGRect lRect = CGRectMake(newBox.origin.x + 20.0, newBox.origin.y + newBox.size.height - 85.0 - l * 40.0, newBox.size.width - 40.0, 14.0);
                drawRoundedRectPath(ctx, lRect, 5.0);
                CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.88 green:0.90 blue:0.94 alpha:1.0] CGColor]);
                CGContextFillPath(ctx);
            }
        }

        CGContextRestoreGState(ctx);

        // Thin connector line between stages
        if (i < 2 && t > startTime + 1.0) {
            double lineP = easeOutCubic(clampd((t - (startTime + 1.0)) / 0.8, 0.0, 1.0));
            CGFloat lx1 = x + stageW;
            CGFloat lx2 = lx1 + gap * lineP;
            CGFloat ly = y + stageH * 0.5;

            CGContextSaveGState(ctx);
            CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.6] CGColor]);
            CGContextSetLineWidth(ctx, 2.0);
            CGContextBeginPath(ctx);
            CGContextMoveToPoint(ctx, lx1 + 10.0, ly);
            CGContextAddLineToPoint(ctx, lx2 - 10.0, ly);
            CGContextStrokePath(ctx);
            CGContextRestoreGState(ctx);
        }
    }

    if (t > 7.4) {
        double fo = clampd((t - 7.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.97 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 6: Cinematic Closing Statement (04:41 - 04:49, Frames 2220 - 2699, 8.0s)
static void renderShot6(CGContextRef ctx, int frame) {
    double t = (frame - 2220) / FPS; // 0.0 to 8.0s
    drawLightStudioBackground(ctx, t, 1.0);
    drawGargProtocolWatermark(ctx, 1.0);

    double camPush = 0.95 + 0.06 * easeInOutQuad(t / 8.0);
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, WIDTH * 0.5, HEIGHT * 0.5);
    CGContextScaleCTM(ctx, camPush, camPush);
    CGContextTranslateCTM(ctx, -WIDTH * 0.5, -HEIGHT * 0.5);

    // Center Title: REA
    double reaAlpha = easeOutCubic(clampd(t / 1.5, 0.0, 1.0));
    NSDictionary *reaAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:175 weight:NSFontWeightHeavy],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:reaAlpha],
        NSKernAttributeName: @(18.0)
    };
    NSAttributedString *reaStr = [[NSAttributedString alloc] initWithString:@"REA" attributes:reaAttrs];
    CGSize reaSz = [reaStr size];
    [reaStr drawAtPoint:NSMakePoint((WIDTH - reaSz.width) * 0.5 + 9.0, HEIGHT * 0.5 - reaSz.height * 0.5 + 60.0)];

    // Divider line & Subtitle: Reverse Engineer Anything
    if (t > 1.8) {
        double subProg = easeOutCubic(clampd((t - 1.8) / 1.5, 0.0, 1.0));
        CGFloat lineW = 160.0 * subProg;

        CGContextSaveGState(ctx);
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.6 * subProg] CGColor]);
        CGContextSetLineWidth(ctx, 1.5);
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, WIDTH * 0.5 - lineW, HEIGHT * 0.5 - 55.0);
        CGContextAddLineToPoint(ctx, WIDTH * 0.5 + lineW, HEIGHT * 0.5 - 55.0);
        CGContextStrokePath(ctx);
        CGContextRestoreGState(ctx);

        NSDictionary *subAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:26 weight:NSFontWeightLight],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.25 green:0.25 blue:0.28 alpha:0.95 * subProg],
            NSKernAttributeName: @(8.0)
        };
        NSAttributedString *subStr = [[NSAttributedString alloc] initWithString:@"Reverse Engineer Anything" attributes:subAttrs];
        CGSize subSz = [subStr size];
        [subStr drawAtPoint:NSMakePoint((WIDTH - subSz.width) * 0.5 + 4.0, HEIGHT * 0.5 - 110.0)];
    }

    // Smaller line: Explore. Understand. Build. (Appears at t = 3.6s)
    if (t > 3.6) {
        double tagProg = easeOutCubic(clampd((t - 3.6) / 1.5, 0.0, 1.0));
        NSDictionary *tagAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:18 weight:NSFontWeightSemibold],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.95 * tagProg],
            NSKernAttributeName: @(5.0)
        };
        NSAttributedString *tagStr = [[NSAttributedString alloc] initWithString:@"Explore.  Understand.  Build." attributes:tagAttrs];
        CGSize tagSz = [tagStr size];
        [tagStr drawAtPoint:NSMakePoint((WIDTH - tagSz.width) * 0.5 + 2.5, HEIGHT * 0.5 - 175.0)];
    }

    CGContextRestoreGState(ctx);

    if (t > 7.4) {
        double fo = clampd((t - 7.4) / 0.6, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.97 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Shot 7: Subscribe to GargProtocol (04:49 - 05:00, Frames 2700 - 3359, 11.0s)
static void renderShot7(CGContextRef ctx, int frame) {
    double t = (frame - 2700) / FPS; // 0.0 to 11.0s
    drawLightStudioBackground(ctx, t, 1.0);

    // Slow camera pullback for outro
    double camPull = 1.04 - 0.06 * easeInOutQuad(t / 11.0);
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, WIDTH * 0.5, HEIGHT * 0.5);
    CGContextScaleCTM(ctx, camPull, camPull);
    CGContextTranslateCTM(ctx, -WIDTH * 0.5, -HEIGHT * 0.5);

    double mainAlpha = easeOutCubic(clampd(t / 1.8, 0.0, 1.0));

    // Channel Brand Logo Mark (Minimalist Monogram GP)
    CGFloat iconR = 48.0;
    CGPoint iconCenter = CGPointMake(WIDTH * 0.5, HEIGHT * 0.64);
    CGRect iconRect = CGRectMake(iconCenter.x - iconR, iconCenter.y - iconR, iconR * 2, iconR * 2);

    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, -10), 25.0, [[NSColor colorWithCalibratedRed:0.1 green:0.15 blue:0.25 alpha:0.12 * mainAlpha] CGColor]);
    drawRoundedRectPath(ctx, iconRect, 24.0);
    CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:mainAlpha] CGColor]);
    CGContextFillPath(ctx);

    NSDictionary *gpAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:34 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSKernAttributeName: @(1.0)
    };
    NSAttributedString *gpStr = [[NSAttributedString alloc] initWithString:@"GP" attributes:gpAttrs];
    CGSize gpSz = [gpStr size];
    [gpStr drawAtPoint:NSMakePoint(iconCenter.x - gpSz.width * 0.5, iconCenter.y - gpSz.height * 0.5)];
    CGContextRestoreGState(ctx);

    // GARGPROTOCOL Channel Name
    NSDictionary *chAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:54 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.11 green:0.11 blue:0.12 alpha:mainAlpha],
        NSKernAttributeName: @(6.0)
    };
    NSAttributedString *chStr = [[NSAttributedString alloc] initWithString:@"GARGPROTOCOL" attributes:chAttrs];
    CGSize chSz = [chStr size];
    [chStr drawAtPoint:NSMakePoint((WIDTH - chSz.width) * 0.5 + 3.0, HEIGHT * 0.5 - 20.0)];

    // Tagline: Technology. AI. Building.
    NSDictionary *tgAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:20 weight:NSFontWeightLight],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.44 alpha:0.95 * mainAlpha],
        NSKernAttributeName: @(4.0)
    };
    NSAttributedString *tgStr = [[NSAttributedString alloc] initWithString:@"Technology.  AI.  Building." attributes:tgAttrs];
    CGSize tgSz = [tgStr size];
    [tgStr drawAtPoint:NSMakePoint((WIDTH - tgSz.width) * 0.5 + 2.0, HEIGHT * 0.5 - 70.0)];

    // Subscribe Button with subtle pulse scale at t = 2.5s
    if (t > 1.8) {
        double subBtnProg = easeOutCubic(clampd((t - 1.8) / 1.2, 0.0, 1.0));
        double btnPulse = 1.0;
        if (t > 3.0 && t < 5.0) {
            btnPulse = 1.0 + 0.04 * sin((t - 3.0) * M_PI * 1.5);
        }

        CGFloat btnW = 240.0;
        CGFloat btnH = 56.0;
        CGFloat btnX = WIDTH * 0.5 - btnW * 0.5;
        CGFloat btnY = HEIGHT * 0.5 - 170.0;

        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, WIDTH * 0.5, btnY + btnH * 0.5);
        CGContextScaleCTM(ctx, btnPulse, btnPulse);
        CGContextTranslateCTM(ctx, -WIDTH * 0.5, -(btnY + btnH * 0.5));

        CGRect btnRect = CGRectMake(btnX, btnY, btnW, btnH);
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, -8), 20.0, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.25 * subBtnProg] CGColor]);

        drawRoundedRectPath(ctx, btnRect, 28.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.0 green:0.44 blue:0.89 alpha:0.96 * subBtnProg] CGColor]);
        CGContextFillPath(ctx);

        NSDictionary *subAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:16 weight:NSFontWeightSemibold],
            NSForegroundColorAttributeName: [NSColor whiteColor],
            NSKernAttributeName: @(3.0)
        };
        NSAttributedString *subStr = [[NSAttributedString alloc] initWithString:@"SUBSCRIBE" attributes:subAttrs];
        CGSize subSz = [subStr size];
        [subStr drawAtPoint:NSMakePoint(btnX + (btnW - subSz.width) * 0.5, btnY + 18.0)];

        CGContextRestoreGState(ctx);
    }

    CGContextRestoreGState(ctx);

    // Gentle fade to white / black at very end (10.0s - 11.0s)
    if (t > 10.0) {
        double fo = clampd((t - 10.0) / 1.0, 0.0, 1.0);
        CGContextSetFillColorWithColor(ctx, [[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.97 alpha:fo] CGColor]);
        CGContextFillRect(ctx, CGRectMake(0, 0, WIDTH, HEIGHT));
    }
}

// Master Render Loop
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

        // Preview Single Frame mode
        if (argc >= 4 && strcmp(argv[1], "--frame") == 0) {
            int frame = atoi(argv[2]);
            const char *outPath = argv[3];

            CGContextClearRect(ctx, CGRectMake(0, 0, w, h));
            NSGraphicsContext *nsCtx = [NSGraphicsContext graphicsContextWithCGContext:ctx flipped:NO];
            [NSGraphicsContext setCurrentContext:nsCtx];

            if (frame < 420) renderShot1(ctx, frame);
            else if (frame < 780) renderShot2(ctx, frame);
            else if (frame < 1260) renderShot3(ctx, frame);
            else if (frame < 1740) renderShot4(ctx, frame);
            else if (frame < 2220) renderShot5(ctx, frame);
            else if (frame < 2700) renderShot6(ctx, frame);
            else renderShot7(ctx, frame);

            CGImageRef img = CGBitmapContextCreateImage(ctx);
            NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
            NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
            [pngData writeToFile:[NSString stringWithUTF8String:outPath] atomically:YES];
            CGImageRelease(img);
            fprintf(stderr, "Exported frame %d to %s\n", frame, outPath);
            return 0;
        }

        // Full Stream Video Pipe mode
        fprintf(stderr, "Rendering all %d frames at %dx%d (60 fps, light theme)...\n", TOTAL_FRAMES, w, h);

        for (int frame = 0; frame < TOTAL_FRAMES; frame++) {
            CGContextClearRect(ctx, CGRectMake(0, 0, w, h));
            NSGraphicsContext *nsCtx = [NSGraphicsContext graphicsContextWithCGContext:ctx flipped:NO];
            [NSGraphicsContext setCurrentContext:nsCtx];

            if (frame < 420) renderShot1(ctx, frame);
            else if (frame < 780) renderShot2(ctx, frame);
            else if (frame < 1260) renderShot3(ctx, frame);
            else if (frame < 1740) renderShot4(ctx, frame);
            else if (frame < 2220) renderShot5(ctx, frame);
            else if (frame < 2700) renderShot6(ctx, frame);
            else renderShot7(ctx, frame);

            write(STDOUT_FILENO, data, bytesPerRow * h);

            if (frame % 180 == 0) {
                fprintf(stderr, "Rendered frame %d / %d (%.1f%%)\n", frame, TOTAL_FRAMES, (frame * 100.0) / TOTAL_FRAMES);
            }
        }

        fprintf(stderr, "Completed all %d frames!\n", TOTAL_FRAMES);
        CGContextRelease(ctx);
        CGColorSpaceRelease(cs);
    }
    return 0;
}
