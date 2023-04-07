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
    
    NSString * argv0 = @"";
    char  argvChar [ 1024 ];
    strcpy (argvChar ,( char  *)[argv0  UTF8String]);
    
    //需要处理的视频文件路径
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    char  srcChar [ 1024 ];
    strcpy (srcChar ,( char  *)[path  UTF8String]);
    // 处理好的文件存储路径
    NSString * dstpath = [NSString stringWithFormat:@"%@/Library/Caches/1-1.aac",NSHomeDirectory()];
    char  dstChar [ 1024 ];
    strcpy (dstChar ,( char  *)[dstpath  UTF8String]);

    char * argv[3];
    argv[0] = argvChar;
    argv[1] = srcChar;
    argv[2] = dstChar;
    
    NSLog(@"存储路径：%@", dstpath);
    
    extraAudio(3, argv);
    
}

- (IBAction)extraVedioAction:(id)sender {
    
    NSString * argv0 = @"";
    char  argvChar [ 1024 ];
    strcpy (argvChar ,( char  *)[argv0  UTF8String]);
    
    //需要处理的视频文件路径
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    char  srcChar [ 1024 ];
    strcpy (srcChar ,( char  *)[path  UTF8String]);
    // 处理好的文件存储路径
    NSString * dstpath = [NSString stringWithFormat:@"%@/Library/Caches/1-1.mp4",NSHomeDirectory()];
    char  dstChar [ 1024 ];
    strcpy (dstChar ,( char  *)[dstpath  UTF8String]);

    char * argv[3];
    argv[0] = argvChar;
    argv[1] = srcChar;
    argv[2] = dstChar;
    
    NSLog(@"存储路径：%@", dstpath);
    
    extraVideo(3, argv);
}

- (IBAction)remuxMultimediaAction:(id)sender {
    
    NSString * argv0 = @"";
    char  argvChar [ 1024 ];
    strcpy (argvChar ,( char  *)[argv0  UTF8String]);
    
    //需要处理的视频文件路径
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    char  srcChar [ 1024 ];
    strcpy (srcChar ,( char  *)[path  UTF8String]);
    // 处理好的文件存储路径
    NSString * dstpath = [NSString stringWithFormat:@"%@/Library/Caches/1-1.flv",NSHomeDirectory()];
    char  dstChar [ 1024 ];
    strcpy (dstChar ,( char  *)[dstpath  UTF8String]);

    char * argv[3];
    argv[0] = argvChar;
    argv[1] = srcChar;
    argv[2] = dstChar;
    
    NSLog(@"存储路径：%@", dstpath);
    remuxMultimedia(3, argv);
}

- (IBAction)cutMultimediaAction:(id)sender {
    NSString * argv0 = @"";
    char  argvChar [ 1024 ];
    strcpy (argvChar ,( char  *)[argv0  UTF8String]);
    
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
    
    char * argv[5];
    argv[0] = argvChar;
    argv[1] = srcChar;
    argv[2] = dstChar;
    argv[3] = startChar;
    argv[4] = endChar;
    
    NSLog(@"存储路径：%@", dstpath);
    cutMultimedia(5, argv);
}

- (IBAction)encodeVideoAction:(id)sender {
    NSString * argv0 = @"";
    char  argvChar [ 1024 ];
    strcpy (argvChar ,( char  *)[argv0  UTF8String]);
    
    //编码格式
    NSString * type = @"libx264";
    char  typeChar [ 1024 ];
    strcpy (typeChar ,( char  *)[type  UTF8String]);
    // 处理好的文件存储路径
    NSString * dstpath = [NSString stringWithFormat:@"%@/Library/Caches/1-1.h264",NSHomeDirectory()];
    char  dstChar [ 1024 ];
    strcpy (dstChar ,( char  *)[dstpath  UTF8String]);

    char * argv[3];
    argv[0] = argvChar;
    argv[1] = dstChar;
    argv[2] = typeChar;
    
    NSLog(@"存储路径：%@", dstpath);
    
    encodeVideo(3, argv);
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
    if(argc < 3){
        av_log(NULL, AV_LOG_ERROR, "arguments must be more than 3\n");
        goto _ERROR;
    }

    dst = argv[1];
    codecName = argv[2];

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
    if(argc < 5){
        av_log(NULL, AV_LOG_INFO, "arguments must be more than 5!\n");
        exit(-1);
    }

    src = argv[1];
    dst = argv[2];
    starttime = atof(argv[3]);
    endtime = atof(argv[4]);

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
    if(argc < 3){
        av_log(NULL, AV_LOG_INFO, "arguments must be more than 3!\n");
        exit(-1);
    }

    src = argv[1];
    dst = argv[2];

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
    if(argc < 3){
        av_log(NULL, AV_LOG_INFO, "arguments must be more than 3!\n");
        exit(-1);
    }

    src = argv[1];
    dst = argv[2];

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
    if (argc < 3)
    {
        av_log(NULL, AV_LOG_INFO, "arguments must be more than 3!\n");
        exit(-1);
    }

    src = argv[1];
    dst = argv[2];
    
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
