//
//  TensorFlowService.m
//  MoxieAISDK
//
//  Created by joker on 2018/9/12.
//  Copyright © 2018年 Scorpion. All rights reserved.
//

#import "TensorFlowService.h"
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

#include <sys/time.h>
#include <fstream>
#include <iostream>
#include <queue>

#include "tensorflow/contrib/lite/kernels/register.h"
#include "tensorflow/contrib/lite/model.h"
#include "tensorflow/contrib/lite/string_util.h"
#include "tensorflow/contrib/lite/tools/mutable_op_resolver.h"

#define LOG(x) std::cerr

#define kScreenWidth     [UIScreen mainScreen].bounds.size.width  //设备的宽度
#define kScreenHeight    [UIScreen mainScreen].bounds.size.height //设备的高

// If you have your own model, modify this to the file name, and make sure
// you've added the file to your app resources too.
static NSString* model_file_name = @"wechat_model";
static NSString* model_file_type = @"tflite";

// If you have your own model, point this to the labels file.
static NSString* labels_file_name = @"wechat_model";
static NSString* labels_file_type = @"txt";

// These dimensions need to match those the model was trained with.
static const int wanted_input_width = 224;
static const int wanted_input_height = 224;
static const int wanted_input_channels = 3;

static NSString* FilePathForResourceName(NSString* name, NSString* extension) {
    NSString* file_path = [[NSBundle mainBundle] pathForResource:name ofType:extension];
    if (file_path == NULL) {
        LOG(FATAL) << "Couldn't find '" << [name UTF8String] << "." << [extension UTF8String]
        << "' in bundle.";
    }
    return file_path;
}

static void LoadLabels(NSString* file_name, NSString* file_type,
                       std::vector<std::string>* label_strings) {
//    NSDictionary* info = [[MXAIModelManage shared] getCurrentModelPath];
    NSString* labels_path = FilePathForResourceName(file_name, file_type);
//    NSLog(@"labels_path --------------- %@",labels_path);
    if (!labels_path) {
        LOG(ERROR) << "Failed to find model proto at" << [file_name UTF8String]
        << [file_type UTF8String];
    }
    std::ifstream t;
    t.open([labels_path UTF8String]);
    std::string line;
    while (t) {
        std::getline(t, line);
        if (line.length()){
            label_strings->push_back(line);
        }
    }
    t.close();
}

// Returns the top N confidence values over threshold in the provided vector,
// sorted by confidence in descending order.
static void GetTopN(const float* prediction, const int prediction_size, const int num_results,
                    const float threshold, std::vector<std::pair<float, int>>* top_results) {
    // Will contain top N results in ascending order.
    std::priority_queue<std::pair<float, int>, std::vector<std::pair<float, int>>,
    std::greater<std::pair<float, int>>>
    top_result_pq;
    
    const long count = prediction_size;
    for (int i = 0; i < count; ++i) {
        const float value = prediction[i];
        // Only add it if it beats the threshold and has a chance at being in
        // the top N.
        if (value < threshold) {
            continue;
        }
        
        top_result_pq.push(std::pair<float, int>(value, i));
        
        // If at capacity, kick the smallest value out.
        if (top_result_pq.size() > num_results) {
            top_result_pq.pop();
        }
    }
    
    // Copy to output vector and reverse into descending order.
    while (!top_result_pq.empty()) {
        top_results->push_back(top_result_pq.top());
        top_result_pq.pop();
    }
    std::reverse(top_results->begin(), top_results->end());
}

@interface TensorFlowService()

@property (nonatomic, copy) TFResult resultCallBack;

@end

@implementation TensorFlowService

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self config];
    }
    return self;
}

- (void)config {
    NSString* graph_path = FilePathForResourceName(model_file_name, model_file_type);
//    NSLog(@"graph_path --------------- %@",graph_path);
    model = tflite::FlatBufferModel::BuildFromFile([graph_path UTF8String]);
    if (!model) {
        LOG(FATAL) << "Failed to mmap model " << graph_path;
    }
    LOG(INFO) << "Loaded model " << graph_path;
    model->error_reporter();
    LOG(INFO) << "resolved reporter";
    
    tflite::ops::builtin::BuiltinOpResolver resolver;
    LoadLabels(labels_file_name, labels_file_type, &labels);
    
    tflite::InterpreterBuilder(*model, resolver)(&interpreter);
    if (!interpreter) {
        LOG(FATAL) << "Failed to construct interpreter";
    }
    if (interpreter->AllocateTensors() != kTfLiteOk) {
        LOG(FATAL) << "Failed to allocate tensors!";
    }
}

+ (TensorFlowService *)shared {
    static TensorFlowService* share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[TensorFlowService alloc]init];
    });
    return share;
}

- (void)identifyImage:(UIImage *)image result:(nonnull TFResult)result{
//    NSLog(@" -------------- identifyImage --------------- ");
    _resultCallBack = result;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        image_data imageData = [self CGImageToPixels:image.CGImage];
        [self inputImageToModel:imageData];
        [self runModel];
    });
}

//TensorFlow识别
- (void)inputImageToModel:(image_data)image{
    float* out = interpreter->typed_input_tensor<float>(0);
    
    const float input_mean = 127.5f;
    const float input_std = 127.5f;
    assert(image.channels >= wanted_input_channels);
    uint8_t* in = image.data.data();
    
    for (int y = 0; y < wanted_input_height; ++y) {
        const int in_y = (y * image.height) / wanted_input_height;
        uint8_t* in_row = in + (in_y * image.width * image.channels);
        float* out_row = out + (y * wanted_input_width * wanted_input_channels);
        for (int x = 0; x < wanted_input_width; ++x) {
            const int in_x = (x * image.width) / wanted_input_width;
            uint8_t* in_pixel = in_row + (in_x * image.channels);
            float* out_pixel = out_row + (x * wanted_input_channels);
            if(!in_pixel){
//                NSLog(@"模型初始化失败,重试");
                return;
            }
            for (int c = 0; c < wanted_input_channels; ++c) {
                out_pixel[c] = (in_pixel[c] - input_mean) / input_std;
            }
        }
    }
}


- (image_data)CGImageToPixels:(CGImage *)image {
    image_data result;
    result.width = (int)CGImageGetWidth(image);
    result.height = (int)CGImageGetHeight(image);
    result.channels = 4;
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    const int bytes_per_row = (result.width * result.channels);
    const int bytes_in_image = (bytes_per_row * result.height);
    result.data = std::vector<uint8_t>(bytes_in_image);
    const int bits_per_component = 8;
    CGContextRef context =
    CGBitmapContextCreate(result.data.data(), result.width, result.height, bits_per_component, bytes_per_row,
                          color_space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color_space);
    CGContextDrawImage(context, CGRectMake(0, 0, result.width, result.height), image);
    CGContextRelease(context);
    return result;
}

- (void)runModel {
    double startTimestamp = [[NSDate new] timeIntervalSince1970];
    if (interpreter->Invoke() != kTfLiteOk) {
        LOG(FATAL) << "Failed to invoke!";
    }
    double endTimestamp = [[NSDate new] timeIntervalSince1970];
    total_latency += (endTimestamp - startTimestamp);
    total_count += 1;
//    NSLog(@"Time: %.4lf, avg: %.4lf, count: %d", endTimestamp - startTimestamp,
//          total_latency / total_count,  total_count);
    
    const int output_size = (int)labels.size();
    const int kNumResults = 5;
    const float kThreshold = 0.1f;
    
    std::vector<std::pair<float, int>> top_results;
    
    float* output = interpreter->typed_output_tensor<float>(0);
    GetTopN(output, output_size, kNumResults, kThreshold, &top_results);
    
    std::vector<std::pair<float, std::string>> newValues;
    for (const auto& result : top_results) {
        std::pair<float, std::string> item;
        item.first = result.first;
        item.second = labels[result.second];
        
        newValues.push_back(item);
    }
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self setPredictionValues:newValues];
    });
}

- (void)setPredictionValues:(std::vector<std::pair<float, std::string>>)newValues {
    NSMutableArray* result = [[NSMutableArray alloc]initWithCapacity:0];
    int labelCount = 0;
    for  (const auto& item : newValues) {
        std::string label = item.second;
        const float value = item.first;
        const int valuePercentage = (int)roundf(value * 100.0f);
        NSString* valueText = [NSString stringWithFormat:@"%d", valuePercentage];
        NSString *nsLabel = [NSString stringWithCString:label.c_str()
                                               encoding:[NSString defaultCStringEncoding]];
        NSDictionary* tmp = @{@"per":valueText,@"page":nsLabel};
        [result addObject:tmp];
        labelCount += 1;
        if (labelCount > 4) {
            break;
        }
    }
    _resultCallBack(result);
}


- (void)dealloc {
//    NSLog(@"TensorFlowService dealloc ---------");
}
@end
