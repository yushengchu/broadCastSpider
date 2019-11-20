//
//  TensorFlowService.h
//
//
//  Created by joker on 2018/9/12.
//  Copyright © 2018年 Scorpion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#include <vector>

#include "tensorflow/contrib/lite/kernels/register.h"
#include "tensorflow/contrib/lite/model.h"

typedef struct {
    int width;
    int height;
    int channels;
    std::vector<uint8_t> data;
} image_data;

NS_ASSUME_NONNULL_BEGIN

typedef void(^TFResult)(NSArray* result);

@interface TensorFlowService : NSObject {
    std::vector<std::string> labels;
    std::unique_ptr<tflite::FlatBufferModel> model;
    tflite::ops::builtin::BuiltinOpResolver resolver;
    std::unique_ptr<tflite::Interpreter> interpreter;
    
    double total_latency;
    int total_count;
}

+ (TensorFlowService*)shared;
- (void)identifyImage:(UIImage*)image result:(TFResult)result;

@end

NS_ASSUME_NONNULL_END
