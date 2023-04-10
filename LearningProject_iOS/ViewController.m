//
//  ViewController.m
//  LearningProject_iOS
//
//  Created by LinMacmini on 2023/1/5.
//

#import "ViewController.h"
#import "avformat.h"
#import "timestamp.h"
#import "avcodec.h"
#import "opt.h"
#import "samplefmt.h"
#import "swscale.h"
#import "avutil.h"
#import "channel_layout.h"

#define WORD uint16_t
#define DWORD uint32_t
#define LONG int32_t

#pragma pack(2)
typedef struct tagBITMAPFILEHEADER {
  WORD  bfType;
  DWORD bfSize;
  WORD  bfReserved1;
  WORD  bfReserved2;
  DWORD bfOffBits;
} BITMAPFILEHEADER, *PBITMAPFILEHEADER;


typedef struct tagBITMAPINFOHEADER {
  DWORD biSize;
  LONG  biWidth;
  LONG  biHeight;
  WORD  biPlanes;
  WORD  biBitCount;
  DWORD biCompression;
  DWORD biSizeImage;
  LONG  biXPelsPerMeter;
  LONG  biYPelsPerMeter;
  DWORD biClrUsed;
  DWORD biClrImportant;
} BITMAPINFOHEADER, *PBITMAPINFOHEADER;

void saveBMP(struct SwsContext *img_convert_ctx, AVFrame *frame, int w, int h, char *filename)
{
    //1 先进行转换,  YUV420=>RGB24:
    // int w = img_convert_ctx->frame_dst->width;
    // int h = img_convert_ctx->frame_dst->height;

    int data_size = w * h * 3;

    AVFrame *pFrameRGB = av_frame_alloc();

    //avpicture_fill((AVPicture *)pFrameRGB, buffer, AV_PIX_FMT_BGR24, w, h);
    pFrameRGB->width = w;
    pFrameRGB->height = h;
    pFrameRGB->format =  AV_PIX_FMT_BGR24;

    av_frame_get_buffer(pFrameRGB, 0);

    sws_scale(img_convert_ctx,
              (const uint8_t* const *)frame->data,
              frame->linesize,
              0, frame->height, pFrameRGB->data, pFrameRGB->linesize);

    //2 构造 BITMAPINFOHEADER
    BITMAPINFOHEADER header;
    header.biSize = sizeof(BITMAPINFOHEADER);


    header.biWidth = w;
    header.biHeight = h*(-1);
    header.biBitCount = 24;
    header.biCompression = 0;
    header.biSizeImage = 0;
    header.biClrImportant = 0;
    header.biClrUsed = 0;
    header.biXPelsPerMeter = 0;
    header.biYPelsPerMeter = 0;
    header.biPlanes = 1;

    //3 构造文件头
    BITMAPFILEHEADER bmpFileHeader = {0,};
    //HANDLE hFile = NULL;
    DWORD dwTotalWriten = 0;
    DWORD dwWriten;

    bmpFileHeader.bfType = 0x4d42; //'BM';
    bmpFileHeader.bfSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER)+ data_size;
    bmpFileHeader.bfOffBits=sizeof(BITMAPFILEHEADER)+sizeof(BITMAPINFOHEADER);

    FILE* pf = fopen(filename, "wb");
    fwrite(&bmpFileHeader, sizeof(BITMAPFILEHEADER), 1, pf);
    fwrite(&header, sizeof(BITMAPINFOHEADER), 1, pf);
    fwrite(pFrameRGB->data[0], 1, data_size, pf);
    fclose(pf);


    //释放资源
    //av_free(buffer);
    av_freep(&pFrameRGB[0]);
    av_free(pFrameRGB);
}

static void pgm_save(unsigned char *buf, int wrap, int xsize, int ysize,
                     char *filename)
{
    FILE *f;
    int i;

    f = fopen(filename,"w");
    fprintf(f, "P5\n%d %d\n%d\n", xsize, ysize, 255);
    for (i = 0; i < ysize; i++)
        fwrite(buf + i * wrap, 1, xsize, f);
    fclose(f);
}

static int decode_write_frame(const char *outfilename, AVCodecContext *avctx,
                              struct SwsContext *img_convert_ctx, AVFrame *frame, AVPacket *pkt)
{
    int ret = -1;
    char buf[1024];

    ret = avcodec_send_packet(avctx, pkt);
    if (ret < 0) {
        fprintf(stderr, "Error while decoding frame, %s(%d)\n", av_err2str(ret), ret);
        return ret;
    }

    while (ret >= 0) {
        fflush(stdout);

        ret = avcodec_receive_frame(avctx, frame);
        if(ret == AVERROR(EAGAIN) || ret == AVERROR_EOF){
            return 0;
        }else if( ret < 0){
            return -1;
        }

        /* the picture is allocated by the decoder, no need to free it */
        snprintf(buf, sizeof(buf), "%s-%d.bmp", outfilename, avctx->frame_number);
        /*pgm_save(frame->data[0], frame->linesize[0],
                 frame->width, frame->height, buf);*/

        saveBMP(img_convert_ctx, frame, 160,  120, buf);

    }
    return 0;
}

static void log_packet(AVFormatContext *fmtCtx, const AVPacket *pkt, int64_t pts_start, int64_t dts_start){
    // = &fmtCtx->streams[pkt->stream_index]->time_base;
    av_log(fmtCtx,
           AV_LOG_INFO,
           "pts:%s dts:%s pts_diff:%lld dts_diff:%lld stream_idx:%d pts_start:%lld dts_start:%lld\n",
           av_ts2str(pkt->pts),
           av_ts2str(pkt->dts),
           pkt->pts - pts_start,
           pkt->dts - dts_start,
           pkt->stream_index,
           pts_start,
           dts_start);
}

static int encode(AVCodecContext *ctx, AVFrame *frame, AVPacket *pkt, FILE *out){
    int ret = -1;

    ret = avcodec_send_frame(ctx, frame);
    if(ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "Failed to send frame to encoder!\n");
        goto _END;
    }

    while( ret >= 0){
        ret = avcodec_receive_packet(ctx, pkt);
        if(ret == AVERROR(EAGAIN) || ret == AVERROR_EOF){
            return 0;
        } else if( ret < 0) {
            return -1; //退出tkyc
        }

        fwrite(pkt->data, 1, pkt->size, out);
        av_packet_unref(pkt);
    }
_END:
    return 0;
}

static int select_best_sample_rate(const AVCodec *codec){
    const int *p;
    int best_samplerate = 0;

    if(!codec->supported_samplerates){
        return 44100;
    }
    p = codec->supported_samplerates;
    while(*p){
        if(!best_samplerate || abs(44100 - *p) < abs(44100 - best_samplerate)){
            best_samplerate = *p;
        }
        p++;
    }
    return best_samplerate;
}

static int check_sample_fmt(const AVCodec *codec, enum AVSampleFormat sample_fmt){
    const enum AVSampleFormat *p = codec->sample_fmts;

    while(*p != AV_SAMPLE_FMT_NONE){
        if( *p == sample_fmt) {
            return 1;
        }
        p++;
    }
    return 0;

}

/* select layout with the highest channel count */
static int select_channel_layout(const AVCodec *codec)
{
    const uint64_t *p;
    uint64_t best_ch_layout = 0;
    int best_nb_channels   = 0;

    if (!codec->channel_layouts)
        return AV_CH_LAYOUT_STEREO;

    p = codec->channel_layouts;
    while (*p) {
        int nb_channels = av_get_channel_layout_nb_channels(*p);

        if (nb_channels > best_nb_channels) {
            best_ch_layout    = *p;
            best_nb_channels = nb_channels;
        }
        p++;
    }
    return best_ch_layout;
}

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    const char * version = av_version_info();
    const char * config = avutil_configuration();
    
    av_log_set_level(AV_LOG_DEBUG);
    av_log(NULL, AV_LOG_INFO, "当前ffmpeg版本号：%s\n\n", version);
    av_log(NULL, AV_LOG_INFO, "当前ffmpeg配置：%s", config);
    
}

- (IBAction)extraAudioAction:(id)sender {
    
    //需要处理的视频文件路径
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    char  srcChar [ 1024 ];
    strcpy (srcChar ,( char  *)[path  UTF8String]);
    // 处理好的文件存储路径
    NSString * dstpath = [NSString stringWithFormat:@"%@/Library/Caches/1-1.aac",NSHomeDirectory()];
    char  dstChar [ 1024 ];
    strcpy (dstChar ,( char  *)[dstpath  UTF8String]);
    
    char * argv[2];
    argv[0] = srcChar;
    argv[1] = dstChar;
    
    NSLog(@"存储路径：%@", dstpath);
    
    extraAudio(2, argv);
    
    
}

- (IBAction)extraVedioAction:(id)sender {
    
    //需要处理的视频文件路径
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    char  srcChar [ 1024 ];
    strcpy (srcChar ,( char  *)[path  UTF8String]);
    // 处理好的文件存储路径
    NSString * dstpath = [NSString stringWithFormat:@"%@/Library/Caches/1-1.mp4",NSHomeDirectory()];
    char  dstChar [ 1024 ];
    strcpy (dstChar ,( char  *)[dstpath  UTF8String]);
    
    char * argv[2];
    argv[0] = srcChar;
    argv[1] = dstChar;
    
    NSLog(@"存储路径：%@", dstpath);
    
    extraVideo(2, argv);
}

- (IBAction)remuxMultimediaAction:(id)sender {
    
    //需要处理的视频文件路径
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    char  srcChar [ 1024 ];
    strcpy (srcChar ,( char  *)[path  UTF8String]);
    // 处理好的文件存储路径
    NSString * dstpath = [NSString stringWithFormat:@"%@/Library/Caches/1-1.flv",NSHomeDirectory()];
    char  dstChar [ 1024 ];
    strcpy (dstChar ,( char  *)[dstpath  UTF8String]);
    
    char * argv[2];
    argv[0] = srcChar;
    argv[1] = dstChar;
    
    NSLog(@"存储路径：%@", dstpath);
    remuxMultimedia(2, argv);
}

- (IBAction)cutMultimediaAction:(id)sender {
    
    //需要处理的视频文件路径
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    char  srcChar [ 1024 ];
    strcpy (srcChar ,( char  *)[path  UTF8String]);
    // 处理好的文件存储路径
    NSString * dstpath = [NSString stringWithFormat:@"%@/Library/Caches/1-2.mp4",NSHomeDirectory()];
    char  dstChar [ 1024 ];
    strcpy (dstChar ,( char  *)[dstpath  UTF8String]);
    // 截取的开始时间点
    NSString * start = @"10.0";
    char  startChar [ 1024 ];
    strcpy (startChar ,( char  *)[start  UTF8String]);
    // 截取的结束时间点
    NSString * end = @"30.0";
    char  endChar [ 1024 ];
    strcpy (endChar ,( char  *)[end  UTF8String]);
    
    char * argv[4];
    argv[0] = srcChar;
    argv[1] = dstChar;
    argv[2] = startChar;
    argv[3] = endChar;
    
    NSLog(@"存储路径：%@", dstpath);
    cutMultimedia(4, argv);
}

- (IBAction)encodeVideoAction:(id)sender {
    
    // 处理好的文件存储路径
    NSString * dstpath = [NSString stringWithFormat:@"%@/Library/Caches/1-1.h264",NSHomeDirectory()];
    char  dstChar [ 1024 ];
    strcpy (dstChar ,( char  *)[dstpath  UTF8String]);
    
    //编码格式
    NSString * type = @"libx264";
    char  typeChar [ 1024 ];
    strcpy (typeChar ,( char  *)[type  UTF8String]);
    
    char * argv[2];
    argv[0] = dstChar;
    argv[1] = typeChar;
    
    NSLog(@"存储路径：%@", dstpath);
    
    encodeVideo(2, argv);
}

- (IBAction)encodeAudioAction:(id)sender {
    
    // 处理好的文件存储路径
    NSString * dstpath = [NSString stringWithFormat:@"%@/Library/Caches/1-4.aac",NSHomeDirectory()];
    char  dstChar [ 1024 ];
    strcpy (dstChar ,( char  *)[dstpath  UTF8String]);
    
    //编码格式
    NSString * type = @"libfdk_aac";
    char  typeChar [ 1024 ];
    strcpy (typeChar ,( char  *)[type  UTF8String]);
    
    char * argv[2];
    argv[0] = dstChar;
    argv[1] = typeChar;
    
    NSLog(@"存储路径：%@", dstpath);
    
    encodeAudio(2, argv);
}

- (IBAction)decodeVideoAction:(id)sender {
    
}

- (IBAction)decodeAudioAction:(id)sender {
    
}

#pragma mark 视频解码
int decodeVideo(int argc, char* argv[]) {
    int ret;
    int idx;

    const char *filename, *outfilename;

    AVFormatContext *fmt_ctx = NULL;

    const AVCodec *codec = NULL;
    AVCodecContext *ctx = NULL;

    AVStream *inStream = NULL;

    AVFrame *frame = NULL;
    AVPacket avpkt;

    struct SwsContext *img_convert_ctx;

    if (argc <= 2) {
        fprintf(stderr, "Usage: %s <input file> <output file>\n", argv[0]);
        exit(0);
    }
    filename    = argv[1];
    outfilename = argv[2];

    /* open input file, and allocate format context */
    if (avformat_open_input(&fmt_ctx, filename, NULL, NULL) < 0) {
        fprintf(stderr, "Could not open source file %s\n", filename);
        exit(1);
    }

    /* retrieve stream information */
    if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
        fprintf(stderr, "Could not find stream information\n");
        exit(1);
    }

    /* dump input information to stderr */
    //av_dump_format(fmt_ctx, 0, filename, 0);

    //av_init_packet(&avpkt);

    /* set end of buffer to 0 (this ensures that no overreading happens for damaged MPEG streams) */
    //memset(inbuf + INBUF_SIZE, 0, AV_INPUT_BUFFER_PADDING_SIZE);
    //

    idx = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (idx < 0) {
        fprintf(stderr, "Could not find %s stream in input file '%s'\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO), filename);
        return idx;
    }

    inStream = fmt_ctx->streams[idx];

    /* find decoder for the stream */
    codec = avcodec_find_decoder(inStream->codecpar->codec_id);
    if (!codec) {
        fprintf(stderr, "Failed to find %s codec\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO));
        return AVERROR(EINVAL);
    }

    ctx = avcodec_alloc_context3(NULL);
    if (!ctx) {
        fprintf(stderr, "Could not allocate video codec context\n");
        exit(1);
    }

    /* Copy codec parameters from input stream to output codec context */
    if ((ret = avcodec_parameters_to_context(ctx, inStream->codecpar)) < 0) {
        fprintf(stderr, "Failed to copy %s codec parameters to decoder context\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO));
        return ret;
    }

    /* open it */
    if (avcodec_open2(ctx, codec, NULL) < 0) {
        fprintf(stderr, "Could not open codec\n");
        exit(1);
    }

    img_convert_ctx = sws_getContext(ctx->width, ctx->height,
                                     ctx->pix_fmt,
                                     160, 120,
                                     AV_PIX_FMT_BGR24,
                                     SWS_BICUBIC, NULL, NULL, NULL);

    if (img_convert_ctx == NULL)
    {
        fprintf(stderr, "Cannot initialize the conversion context\n");
        exit(1);
    }

    frame = av_frame_alloc();
    if (!frame) {
        fprintf(stderr, "Could not allocate video frame\n");
        exit(1);
    }

    while (av_read_frame(fmt_ctx, &avpkt) >= 0) {
        if(avpkt.stream_index == idx){
            if (decode_write_frame(outfilename, ctx, img_convert_ctx, frame, &avpkt) < 0)
                exit(1);
        }

        av_packet_unref(&avpkt);
    }

    decode_write_frame(outfilename, ctx, img_convert_ctx, frame, NULL);

    avformat_close_input(&fmt_ctx);

    sws_freeContext(img_convert_ctx);
    avcodec_free_context(&ctx);
    av_frame_free(&frame);

    return 0;
}


#pragma mark 视频编码
void encodeVideo(int argc, char* argv[]) {
    int ret = -1;

    FILE *f = NULL;

    char *dst = NULL;
    char *codecName = NULL;

    const AVCodec *codec = NULL;
    AVCodecContext *ctx = NULL;

    AVFrame *frame = NULL;
    AVPacket *pkt = NULL;

    av_log_set_level(AV_LOG_DEBUG);

    //1. 输入参数
    if(argc < 2){
        av_log(NULL, AV_LOG_ERROR, "arguments must be more than 2\n");
        goto _ERROR;
    }

    dst = argv[0];
    codecName = argv[1];

    //2. 查找编码器
    codec = avcodec_find_encoder_by_name(codecName);
    if(!codec){
        av_log(NULL, AV_LOG_ERROR, "don't find Codec: %s", codecName);
        goto _ERROR;
    }

    //3. 创建编码器上下文
    ctx = avcodec_alloc_context3(codec);
    if(!ctx){
        av_log(NULL, AV_LOG_ERROR, "NO MEMRORY\n");
        goto _ERROR;
    }

    //4. 设置编码器参数
    ctx->width = 640;
    ctx->height = 480;
    ctx->bit_rate = 500000;// 码率
    //时间基
    ctx->time_base = (AVRational){1, 25};
    //帧率
    ctx->framerate = (AVRational){25, 1};

    ctx->gop_size = 10;
    ctx->max_b_frames = 1;
    ctx->pix_fmt = AV_PIX_FMT_YUV420P;

    if(codec->id == AV_CODEC_ID_H264){
        av_opt_set(ctx->priv_data, "preset", "slow", 0);
    }

    //5. 编码器与编码器上下文绑定到一起
    ret = avcodec_open2(ctx, codec , NULL);
    if(ret < 0) {
        av_log(ctx, AV_LOG_ERROR, "Don't open codec: %s \n", av_err2str(ret));
        goto _ERROR;
    }

    //6. 创建输出文件
    f = fopen(dst, "wb");// w写内容,b二进制
    if(!f){
        av_log(NULL, AV_LOG_ERROR, "Don't open file:%s", dst);
        goto _ERROR;
    }

    //7. 创建AVFrame
    frame = av_frame_alloc();
    if(!frame){
        av_log(NULL, AV_LOG_ERROR, "NO MEMORY!\n");
        goto _ERROR;
    }
    frame->width = ctx->width;
    frame->height = ctx->height;
    frame->format = ctx->pix_fmt;

    ret = av_frame_get_buffer(frame, 0);
    if(ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "Could not allocate the video frame \n");
        goto _ERROR;
    }

    //8. 创建AVPacket
    pkt = av_packet_alloc();
     if(!pkt){
        av_log(NULL, AV_LOG_ERROR, "NO MEMORY!\n");
        goto _ERROR;
    }

    //9. 生成视频内容
    for(int i=0; i<25; i++){
        ret = av_frame_make_writable(frame);
        if(ret < 0) {
            break;
        }

        //Y分量
        for(int y = 0; y < ctx->height; y++){
            for(int x=0; x < ctx->width; x++){
                frame->data[0][y*frame->linesize[0]+x] = x + y + i * 3;
            }
        }

        //UV分量
        for(int y=0; y< ctx->height/2; y++){
            for(int x=0; x < ctx->width/2; x++){
                frame->data[1][y * frame->linesize[1] + x ] = 128 + y + i * 2;
                frame->data[2][y * frame->linesize[2] + x ] = 64 + x + i * 5;
            }
        }

        frame->pts = i;

        //10. 编码
        ret = encode(ctx, frame, pkt, f);
        if(ret == -1){
            goto _ERROR;
        }
    }
    //10. 编码
    encode(ctx, NULL, pkt, f);
_ERROR:
    //ctx
    if(ctx){
        avcodec_free_context(&ctx);
    }

    //avframe
    if(frame){
        av_frame_free(&frame);
    }

    //avpacket
    if(pkt){
        av_packet_free(&pkt);
    }

    //dst
    if(f){
        fclose(f);
    }
}

#pragma mark 音频编码
void encodeAudio(int argc, char* argv[]) {
    int ret = -1;

    FILE *f = NULL;

    char *dst = NULL;
    char *codecName = NULL;

    const AVCodec *codec = NULL;
    AVCodecContext *ctx = NULL;

    AVFrame *frame = NULL;
    AVPacket *pkt = NULL;

    uint16_t *samples = NULL;

    av_log_set_level(AV_LOG_DEBUG);

    //1. 输入参数
    if(argc < 2){
        av_log(NULL, AV_LOG_ERROR, "arguments must be more than 2\n");
        goto _ERROR;
    }

    dst = argv[0];
    codecName = argv[1];

    //2. 查找编码器
    codec = avcodec_find_encoder_by_name(codecName);
    //codec = avcodec_find_encoder(AV_CODEC_ID_AAC);
    if(!codec){
        av_log(NULL, AV_LOG_ERROR, "don't find Codec: %s", codecName);
        goto _ERROR;
    }

    //3. 创建编码器上下文
    ctx = avcodec_alloc_context3(codec);
    if(!ctx){
        av_log(NULL, AV_LOG_ERROR, "NO MEMRORY\n");
        goto _ERROR;
    }

    //4. 设置编码器参数
    ctx->bit_rate = 64000;
    ctx->sample_fmt = AV_SAMPLE_FMT_S16;//AV_SAMPLE_FMT_FLTP
    if(!check_sample_fmt(codec, ctx->sample_fmt)){
        av_log(NULL, AV_LOG_ERROR, "Encoder does not support sample format!\n");
        goto _ERROR;
    }

    ctx->sample_rate = select_best_sample_rate(codec);
//    av_channel_layout_copy(&ctx->ch_layout, &(AVChannelLayout)AV_CHANNEL_LAYOUT_STEREO); //AV_CHANNEL_LAYOUT_MONO

    ctx->channel_layout = select_channel_layout(codec);
    ctx->channels       = av_get_channel_layout_nb_channels(ctx->channel_layout);
    
    //5. 编码器与编码器上下文绑定到一起
    ret = avcodec_open2(ctx, codec , NULL);
    if(ret < 0) {
        av_log(ctx, AV_LOG_ERROR, "Don't open codec: %s \n", av_err2str(ret));
        goto _ERROR;
    }

    //6. 创建输出文件
    f = fopen(dst, "wb");
    if(!f){
        av_log(NULL, AV_LOG_ERROR, "Don't open file:%s", dst);
        goto _ERROR;
    }

    //7. 创建AVFrame
    frame = av_frame_alloc();
    if(!frame){
        av_log(NULL, AV_LOG_ERROR, "NO MEMORY!\n");
        goto _ERROR;
    }

    frame->nb_samples = ctx->frame_size;
    frame->format = AV_SAMPLE_FMT_S16; //AV_SAMPLE_FMT_FLTP
//    av_channel_layout_copy(&frame->ch_layout,  &(AVChannelLayout)AV_CHANNEL_LAYOUT_STEREO); //AV_CHANNEL_LAYOUT_MONO
    frame->channel_layout = ctx->channel_layout;
    
    frame->sample_rate = ctx->sample_rate;
    ret = av_frame_get_buffer(frame, 0);
    if(ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "Could not allocate the video frame \n");
        goto _ERROR;
    }

    //8. 创建AVPacket
    pkt = av_packet_alloc();
     if(!pkt){
        av_log(NULL, AV_LOG_ERROR, "NO MEMORY!\n");
        goto _ERROR;
    }

    //9. 生成音频内容
    float t = 0;
    float tincr = 4*M_PI*440/ctx->sample_rate;

    for(int i=0; i < 200; i++){
        ret = av_frame_make_writable(frame);
        if(ret < 0) {
            av_log(NULL, AV_LOG_ERROR, "Could not allocate space!\n");
            goto _ERROR;
        }

        samples = (uint16_t*)frame->data[0]; //FLTP 32 (uint32_t*)
        for(int j=0; j < ctx->frame_size; j++){
            samples[2*j] = (int)(sin(t)*10000); //4
            for(int k=1; k < ctx->channels; k++){
                samples[2*j + k] = samples[2*j]; //4
            }
            t += tincr;
        }
        encode(ctx, frame, pkt, f);
    }
    //10. 编码
    encode(ctx, NULL, pkt, f);
_ERROR:
    //ctx
    if(ctx){
        avcodec_free_context(&ctx);
    }

    //avframe
    if(frame){
        av_frame_free(&frame);
    }

    //avpacket
    if(pkt){
        av_packet_free(&pkt);
    }

    //dst
    if(f){
        fclose(f);
    }
}


#pragma mark 视频裁剪
void cutMultimedia(int argc, char* argv[]) {
    int ret = -1;
    int stream_idx = 0;
    int i = 0;

    //1. 处理一些参数；
    char* src;
    char* dst;

    double starttime = 0;
    double endtime = 0;

    int *stream_map = NULL;
    int64_t *dts_start_time = NULL;
    int64_t *pts_start_time = NULL;


    AVFormatContext *pFmtCtx = NULL;
    AVFormatContext *oFmtCtx = NULL;

    AVPacket pkt;

    av_log_set_level(AV_LOG_DEBUG);

    //cut src dst start end
    if(argc < 4){
        av_log(NULL, AV_LOG_INFO, "arguments must be more than 4!\n");
        exit(-1);
    }

    src = argv[0];
    dst = argv[1];
    starttime = atof(argv[2]);
    endtime = atof(argv[3]);

    //2. 打开多媒体文件
    if((ret = avformat_open_input(&pFmtCtx, src, NULL, NULL)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "%s\n", av_err2str(ret));
        exit(-1);
    }

    //4. 打开目的文件的上下文
    avformat_alloc_output_context2(&oFmtCtx, NULL, NULL, dst);
    if(!oFmtCtx){
        av_log(NULL, AV_LOG_ERROR, "NO MEMORY!\n");
        goto _ERROR;
    }

    stream_map = av_calloc(pFmtCtx->nb_streams, sizeof(int));
    if(!stream_map){
        av_log(NULL, AV_LOG_ERROR, "NO MEMORY!\n");
        goto _ERROR;
    }

    for(i=0; i < pFmtCtx->nb_streams; i++){
        AVStream *outStream = NULL;
        AVStream *inStream = pFmtCtx->streams[i];
        AVCodecParameters *inCodecPar = inStream->codecpar;
        if(inCodecPar->codec_type != AVMEDIA_TYPE_AUDIO &&
           inCodecPar->codec_type != AVMEDIA_TYPE_VIDEO &&
           inCodecPar->codec_type != AVMEDIA_TYPE_SUBTITLE) {
                stream_map[i] = -1;
                continue;
           }
        stream_map[i] = stream_idx++;

        //5. 为目的文件，创建一个新的视频流
        outStream = avformat_new_stream(oFmtCtx, NULL);
        if(!outStream){
            av_log(oFmtCtx, AV_LOG_ERROR, "NO MEMORY!\n");
            goto _ERROR;
        }

        avcodec_parameters_copy(outStream->codecpar, inStream->codecpar);
        outStream->codecpar->codec_tag = 0;
    }

    //绑定
    ret = avio_open2(&oFmtCtx->pb, dst, AVIO_FLAG_WRITE, NULL, NULL);
    if(ret < 0 ){
        av_log(oFmtCtx, AV_LOG_ERROR, "%s", av_err2str(ret));
        goto _ERROR;
    }

    //7. 写多媒体文件头到目的文件
    ret = avformat_write_header(oFmtCtx, NULL);
    if(ret < 0 ){
        av_log(oFmtCtx, AV_LOG_ERROR, "%s", av_err2str(ret));
        goto _ERROR;
    }

    //seek
    ret = av_seek_frame(pFmtCtx, -1, starttime*AV_TIME_BASE, AVSEEK_FLAG_BACKWARD);
    if(ret < 0) {
        av_log(oFmtCtx, AV_LOG_ERROR, "%s", av_err2str(ret));
        goto _ERROR;
    }

    dts_start_time = av_calloc(pFmtCtx->nb_streams, sizeof(int64_t));
    for(int t=0; t < pFmtCtx->nb_streams; t++){
        dts_start_time[t] = -1;
    }
    pts_start_time = av_calloc(pFmtCtx->nb_streams, sizeof(int64_t));
     for(int t=0; t < pFmtCtx->nb_streams; t++){
        pts_start_time[t] = -1;
    }

    //8. 从源多媒体文件中读取音频/视频/字幕数据到目的文件中
    while(av_read_frame(pFmtCtx, &pkt) >= 0) {
        AVStream *inStream, *outStream;

        if(dts_start_time[pkt.stream_index] == -1 && pkt.dts >= 0){
            dts_start_time[pkt.stream_index] = pkt.dts;
        }

        if(pts_start_time[pkt.stream_index] == -1 && pkt.pts >= 0){
            pts_start_time[pkt.stream_index] = pkt.pts;
        }

        inStream = pFmtCtx->streams[pkt.stream_index];

        if(av_q2d(inStream->time_base) * pkt.pts > endtime) {
            av_log(oFmtCtx, AV_LOG_INFO, "success!\n");
            break;
        }
        if(stream_map[pkt.stream_index] < 0){
            av_packet_unref(&pkt);
            continue;
        }
        //printf("pkt.pts=%lld, pkt.dts=%lld\n", pkt.pts, pkt.dts);
        log_packet(pFmtCtx, &pkt, pts_start_time[pkt.stream_index], dts_start_time[pkt.stream_index]);

        pkt.pts = pkt.pts - pts_start_time[pkt.stream_index];
        pkt.dts = pkt.dts - dts_start_time[pkt.stream_index];


        if(pkt.dts > pkt.pts){
            pkt.pts = pkt.dts;
        }

        pkt.stream_index = stream_map[pkt.stream_index];

        outStream = oFmtCtx->streams[pkt.stream_index];
        av_packet_rescale_ts(&pkt, inStream->time_base, outStream->time_base);

        pkt.pos = -1;
        av_interleaved_write_frame(oFmtCtx, &pkt);
        av_packet_unref(&pkt);

    }
    //9. 写多媒体文件尾到文件中
    av_write_trailer(oFmtCtx);

    //10. 将申请的资源释放掉
_ERROR:
    if(pFmtCtx){
        avformat_close_input(&pFmtCtx);
        pFmtCtx = NULL;
    }
    if(oFmtCtx->pb){
        avio_close(oFmtCtx->pb);
    }

    if(oFmtCtx){
        avformat_free_context(oFmtCtx);
        oFmtCtx = NULL;
    }

    if(stream_map){
        av_free(stream_map);
    }

    if(dts_start_time){
        av_free(dts_start_time);
    }

    if(pts_start_time){
        av_free(pts_start_time);
    }
}

#pragma mark 格式转换
void remuxMultimedia(int argc, char* argv[]) {
    int ret = -1;
    int stream_idx = 0;
    int i = 0;

    //1. 处理一些参数；
    char* src;
    char* dst;

    int *stream_map = NULL;

    AVFormatContext *pFmtCtx = NULL;
    AVFormatContext *oFmtCtx = NULL;

    AVPacket pkt;

    av_log_set_level(AV_LOG_DEBUG);
    if (argc < 2)
    {
        av_log(NULL, AV_LOG_INFO, "arguments must be more than 2!\n");
        exit(-1);
    }

    src = argv[0];
    dst = argv[1];

    //2. 打开多媒体文件
    if((ret = avformat_open_input(&pFmtCtx, src, NULL, NULL)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "%s\n", av_err2str(ret));
        exit(-1);
    }

    //4. 打开目的文件的上下文
    avformat_alloc_output_context2(&oFmtCtx, NULL, NULL, dst);
    if(!oFmtCtx){
        av_log(NULL, AV_LOG_ERROR, "NO MEMORY!\n");
        goto _ERROR;
    }

    stream_map = av_calloc(pFmtCtx->nb_streams, sizeof(int));
    if(!stream_map){
        av_log(NULL, AV_LOG_ERROR, "NO MEMORY!\n");
        goto _ERROR;
    }

    for(i=0; i < pFmtCtx->nb_streams; i++){
        AVStream *outStream = NULL;
        AVStream *inStream = pFmtCtx->streams[i];
        AVCodecParameters *inCodecPar = inStream->codecpar;
        if(inCodecPar->codec_type != AVMEDIA_TYPE_AUDIO &&
           inCodecPar->codec_type != AVMEDIA_TYPE_VIDEO &&
           inCodecPar->codec_type != AVMEDIA_TYPE_SUBTITLE)
        {
            stream_map[i] = -1;
            continue;
        }
        stream_map[i] = stream_idx++;

        //5. 为目的文件，创建一个新的视频流
        outStream = avformat_new_stream(oFmtCtx, NULL);
        if(!outStream){
            av_log(oFmtCtx, AV_LOG_ERROR, "NO MEMORY!\n");
            goto _ERROR;
        }

        avcodec_parameters_copy(outStream->codecpar, inStream->codecpar);
        outStream->codecpar->codec_tag = 0;
    }

    //绑定
    ret = avio_open2(&oFmtCtx->pb, dst, AVIO_FLAG_WRITE, NULL, NULL);
    if(ret < 0 ){
        av_log(oFmtCtx, AV_LOG_ERROR, "%s", av_err2str(ret));
        goto _ERROR;
    }

    //7. 写多媒体文件头到目的文件
    ret = avformat_write_header(oFmtCtx, NULL);
    if(ret < 0 ){
        av_log(oFmtCtx, AV_LOG_ERROR, "%s", av_err2str(ret));
        goto _ERROR;
    }
    //8. 从源多媒体文件中读取音频/视频/字幕数据到目的文件中
    while(av_read_frame(pFmtCtx, &pkt) >= 0) {
        AVStream *inStream, *outStream;

        inStream = pFmtCtx->streams[pkt.stream_index];
        if(stream_map[pkt.stream_index] < 0){
            av_packet_unref(&pkt);
            continue;
        }
        pkt.stream_index = stream_map[pkt.stream_index];

        outStream = oFmtCtx->streams[pkt.stream_index];
        av_packet_rescale_ts(&pkt, inStream->time_base, outStream->time_base);
        pkt.pos = -1;
        av_interleaved_write_frame(oFmtCtx, &pkt);
        av_packet_unref(&pkt);
        
    }
    //9. 写多媒体文件尾到文件中
    av_write_trailer(oFmtCtx);

    //10. 将申请的资源释放掉
_ERROR:
    if(pFmtCtx){
        avformat_close_input(&pFmtCtx);
        pFmtCtx = NULL;
    }
    if(oFmtCtx->pb){
        avio_close(oFmtCtx->pb);
    }

    if(oFmtCtx){
        avformat_free_context(oFmtCtx);
        oFmtCtx = NULL;
    }

    if(stream_map){
        av_free(stream_map);
    }
}

#pragma mark 抽取视频数据
void extraVideo(int argc, char* argv[]) {
    
    int ret = -1;
    int idx = -1;

    //1. 处理一些参数；
    char* src;
    char* dst;

    AVFormatContext *pFmtCtx = NULL;
    AVFormatContext *oFmtCtx = NULL;

    const AVOutputFormat *outFmt = NULL;
    AVStream *outStream = NULL;
    AVStream *inStream = NULL;

    AVPacket pkt;

    av_log_set_level(AV_LOG_DEBUG);
    if(argc < 2){
        av_log(NULL, AV_LOG_INFO, "arguments must be more than 2!\n");
        exit(-1);
    }

    src = argv[0];
    dst = argv[1];

    //2. 打开多媒体文件
    if((ret = avformat_open_input(&pFmtCtx, src, NULL, NULL)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "%s\n", av_err2str(ret));
        exit(-1);
    }

    //3. 从多媒体文件中找到视频流
    idx = av_find_best_stream(pFmtCtx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if(idx < 0) {
        av_log(pFmtCtx, AV_LOG_ERROR, "Does not include audio stream!\n");
        goto _ERROR;
    }

    //4. 打开目的文件的上下文
    oFmtCtx = avformat_alloc_context();
    if(!oFmtCtx){
        av_log(NULL, AV_LOG_ERROR, "NO Memory!\n");
        goto _ERROR;
    }
    outFmt = av_guess_format(NULL, dst, NULL);
    oFmtCtx->oformat = outFmt;

    //5. 为目的文件，创建一个新的视频流
    outStream = avformat_new_stream(oFmtCtx, NULL);
    //6. 设置输出视频参数
    inStream = pFmtCtx->streams[idx];
    avcodec_parameters_copy(outStream->codecpar, inStream->codecpar);
    outStream->codecpar->codec_tag = 0;

    //绑定
    ret = avio_open2(&oFmtCtx->pb, dst, AVIO_FLAG_WRITE, NULL, NULL);
    if(ret < 0 ){
        av_log(oFmtCtx, AV_LOG_ERROR, "%s", av_err2str(ret));
        goto _ERROR;
    }

    //7. 写多媒体文件头到目的文件
    ret = avformat_write_header(oFmtCtx, NULL);
    if(ret < 0 ){
        av_log(oFmtCtx, AV_LOG_ERROR, "%s", av_err2str(ret));
        goto _ERROR;
    }
    //8. 从源多媒体文件中读到视频数据到目的文件中
    while(av_read_frame(pFmtCtx, &pkt) >= 0) {
        if(pkt.stream_index == idx) {
            pkt.pts = av_rescale_q_rnd(pkt.pts, inStream->time_base, outStream->time_base, (AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX));
            pkt.dts = av_rescale_q_rnd(pkt.dts, inStream->time_base, outStream->time_base, (AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX));
            pkt.duration = av_rescale_q(pkt.duration, inStream->time_base, outStream->time_base);
            pkt.stream_index = 0;
            pkt.pos = -1;
            av_interleaved_write_frame(oFmtCtx, &pkt);
            av_packet_unref(&pkt);
        }
    }
    //9. 写多媒体文件尾到文件中
    av_write_trailer(oFmtCtx);

    //10. 将申请的资源释放掉
_ERROR:
    if(pFmtCtx){
        avformat_close_input(&pFmtCtx);
        pFmtCtx = NULL;
    }
    if(oFmtCtx->pb){
        avio_close(oFmtCtx->pb);
    }

    if(oFmtCtx){
        avformat_free_context(oFmtCtx);
        oFmtCtx = NULL;
    }
}

#pragma mark 音频抽取 aac
void extraAudio(int argc, char* argv[]) {
    
    int ret = -1;
    int idx = -1;
    
    // 1、处理一些参数
    char* src;
    char* dst;

    av_log_set_level(AV_LOG_DEBUG);
    if (argc < 2)
    {
        av_log(NULL, AV_LOG_INFO, "arguments must be more than 2!\n");
        exit(-1);
    }

    src = argv[0];
    dst = argv[1];
    
    AVFormatContext *pFmtCtx = NULL;
    AVFormatContext *oFmtCtx = NULL;

    const AVOutputFormat *outFmt = NULL;
    AVStream *outStream = NULL;
    AVStream *inStream = NULL;

    AVPacket pkt;

    // 2、打开多媒体文件
    if((ret = avformat_open_input(&pFmtCtx, src, NULL, NULL)) < 0)
    {
        av_log(NULL, AV_LOG_ERROR, "%s\n", av_err2str(ret));
        exit(-1);
    }

    // 3、从多媒体文件中找到音频流
    idx = av_find_best_stream(pFmtCtx, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    if(idx < 0) {
        av_log(pFmtCtx, AV_LOG_ERROR, "Does not include audio stream!\n");
        goto _ERROR;
    }

    // 4、打开目的文件的上下文
    oFmtCtx = avformat_alloc_context();
    if(!oFmtCtx){
        av_log(NULL, AV_LOG_ERROR, "NO Memory!\n");
        goto _ERROR;
    }
    outFmt = av_guess_format(NULL, dst, NULL);
    oFmtCtx->oformat = outFmt;

    // 5、为目的文件创建一个新的音频流
    outStream = avformat_new_stream(oFmtCtx, NULL);

    // 6、设置输出音频参数
    inStream = pFmtCtx->streams[idx];
    avcodec_parameters_copy(outStream->codecpar, inStream->codecpar);
    outStream->codecpar->codec_tag = 0;

    //绑定
    ret = avio_open2(&oFmtCtx->pb, dst, AVIO_FLAG_WRITE, NULL, NULL);
    if(ret < 0 )
    {
        av_log(oFmtCtx, AV_LOG_ERROR, "%s", av_err2str(ret));
        goto _ERROR;
    }

    // 7、写多媒体文件头到目的文件
    ret = avformat_write_header(oFmtCtx, NULL);
    if(ret < 0 ){
        av_log(oFmtCtx, AV_LOG_ERROR, "%s", av_err2str(ret));
        goto _ERROR;
    }

    // 8、从源多媒体文件中读取音频数据到目的文件中
    while(av_read_frame(pFmtCtx, &pkt) >= 0) {
        if(pkt.stream_index == idx) {
            pkt.pts = av_rescale_q_rnd(pkt.pts, inStream->time_base, outStream->time_base, (AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX));
            pkt.dts = pkt.pts;
            pkt.duration = av_rescale_q(pkt.duration, inStream->time_base, outStream->time_base);
            pkt.stream_index = 0;
            pkt.pos = -1;
            av_interleaved_write_frame(oFmtCtx, &pkt);
            av_packet_unref(&pkt);
        }
    }

    // 9、写多媒体文件尾到文件中
    av_write_trailer(oFmtCtx);

    // 10、将申请的资源释放掉
_ERROR:
    if(pFmtCtx)
    {
        avformat_close_input(&pFmtCtx);
        pFmtCtx = NULL;
    }
    if(oFmtCtx->pb)
    {
        avio_close(oFmtCtx->pb);
    }

    if(oFmtCtx)
    {
        avformat_free_context(oFmtCtx);
        oFmtCtx = NULL;
    }
}


@end
