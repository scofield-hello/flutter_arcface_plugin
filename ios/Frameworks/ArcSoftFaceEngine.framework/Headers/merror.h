/*----------------------------------------------------------------------------------------------
*
* This file is ArcSoft's property. It contains ArcSoft's trade secret, proprietary and
* confidential information.
*
* The information and code contained in this file is only for authorized ArcSoft employees
* to design, create, modify, or review.
*
* DO NOT DISTRIBUTE, DO NOT DUPLICATE OR TRANSMIT IN ANY FORM WITHOUT PROPER AUTHORIZATION.
*
* If you are not an intended recipient of this file, you must not copy, distribute, modify,
* or take any action in reliance on it.
*
* If you have received this file in error, please immediately notify ArcSoft and
* permanently delete the original and any copy of any file and any printout thereof.
*
*-------------------------------------------------------------------------------------------------*/


#ifndef __MERROR_H__
#define __MERROR_H__


#define MERR_NONE						(0)
#define MOK								(0)
#define ASF_MOK                         (200)

#define MERR_BASIC_BASE                   0X0001                            //通用错误类型
#define MERR_UNKNOWN                      MERR_BASIC_BASE                    //错误原因不明
#define MERR_INVALID_PARAM               (MERR_BASIC_BASE+1)                //无效的参数
#define MERR_UNSUPPORTED                 (MERR_BASIC_BASE+2)                //引擎不支持
#define MERR_NO_MEMORY                   (MERR_BASIC_BASE+3)                //内存不足
#define MERR_BAD_STATE                   (MERR_BASIC_BASE+4)                //状态错误
#define MERR_USER_CANCEL                 (MERR_BASIC_BASE+5)                //用户取消相关操作
#define MERR_EXPIRED                     (MERR_BASIC_BASE+6)                //操作时间过期
#define MERR_USER_PAUSE                  (MERR_BASIC_BASE+7)                //用户暂停操作
#define MERR_BUFFER_OVERFLOW             (MERR_BASIC_BASE+8)                //缓冲上溢
#define MERR_BUFFER_UNDERFLOW            (MERR_BASIC_BASE+9)                //缓冲下溢
#define MERR_NO_DISKSPACE                (MERR_BASIC_BASE+10)            //存贮空间不足
#define MERR_COMPONENT_NOT_EXIST         (MERR_BASIC_BASE+11)            //组件不存在
#define MERR_GLOBAL_DATA_NOT_EXIST       (MERR_BASIC_BASE+12)            //全局数据不存在


#define MERR_FSDK_BASE                           0X7000                    //Free SDK通用错误类型
#define MERR_FSDK_INVALID_APP_ID                 (MERR_FSDK_BASE+1)        //无效的App Id
#define MERR_FSDK_INVALID_SDK_ID                 (MERR_FSDK_BASE+2)        //无效的SDK key
#define MERR_FSDK_INVALID_ID_PAIR                (MERR_FSDK_BASE+3)        //AppId和SDKKey不匹配
#define MERR_FSDK_MISMATCH_ID_AND_SDK            (MERR_FSDK_BASE+4)        //SDKKey 和使用的SDK 不匹配
#define MERR_FSDK_SYSTEM_VERSION_UNSUPPORTED     (MERR_FSDK_BASE+5)        //系统版本不被当前SDK所支持
#define MERR_FSDK_LICENCE_EXPIRED                (MERR_FSDK_BASE+6)        //SDK有效期过期，需要重新下载更新

#define MERR_FSDK_APS_ERROR_BASE                0x11000                            //PhotoStyling 错误类型
#define MERR_FSDK_APS_ENGINE_HANDLE             (MERR_FSDK_APS_ERROR_BASE+1)    //引擎句柄非法
#define MERR_FSDK_APS_MEMMGR_HANDLE             (MERR_FSDK_APS_ERROR_BASE+2)    //内存句柄非法
#define MERR_FSDK_APS_DEVICEID_INVALID          (MERR_FSDK_APS_ERROR_BASE+3)    //Device ID 非法
#define MERR_FSDK_APS_DEVICEID_UNSUPPORTED      (MERR_FSDK_APS_ERROR_BASE+4)    //Device ID 不支持
#define MERR_FSDK_APS_MODEL_HANDLE              (MERR_FSDK_APS_ERROR_BASE+5)    //模板数据指针非法
#define MERR_FSDK_APS_MODEL_SIZE                (MERR_FSDK_APS_ERROR_BASE+6)    //模板数据长度非法
#define MERR_FSDK_APS_IMAGE_HANDLE              (MERR_FSDK_APS_ERROR_BASE+7)    //图像结构体指针非法
#define MERR_FSDK_APS_IMAGE_FORMAT_UNSUPPORTED  (MERR_FSDK_APS_ERROR_BASE+8)    //图像格式不支持
#define MERR_FSDK_APS_IMAGE_PARAM               (MERR_FSDK_APS_ERROR_BASE+9)    //图像参数非法
#define MERR_FSDK_APS_IMAGE_SIZE                (MERR_FSDK_APS_ERROR_BASE+10)    //图像尺寸大小超过支持范围
#define MERR_FSDK_APS_DEVICE_AVX2_UNSUPPORTED   (MERR_FSDK_APS_ERROR_BASE+11)    //处理器不支持AVX2指令

#define MERR_FSDK_FR_ERROR_BASE                   0x12000                            //Face Recognition错误类型
#define MERR_FSDK_FR_INVALID_MEMORY_INFO          (MERR_FSDK_FR_ERROR_BASE+1)        //无效的输入内存
#define MERR_FSDK_FR_INVALID_IMAGE_INFO           (MERR_FSDK_FR_ERROR_BASE+2)        //无效的输入图像参数
#define MERR_FSDK_FR_INVALID_FACE_INFO            (MERR_FSDK_FR_ERROR_BASE+3)        //无效的脸部信息
#define MERR_FSDK_FR_NO_GPU_AVAILABLE             (MERR_FSDK_FR_ERROR_BASE+4)        //当前设备无GPU可用
#define MERR_FSDK_FR_MISMATCHED_FEATURE_LEVEL     (MERR_FSDK_FR_ERROR_BASE+5)        //待比较的两个人脸特征的版本不一致


#define MERR_FSDK_FACEFEATURE_ERROR_BASE                0x14000                                    //人脸特征检测错误类型
#define MERR_FSDK_FACEFEATURE_UNKNOWN                   (MERR_FSDK_FACEFEATURE_ERROR_BASE+1)    //人脸特征检测错误未知
#define MERR_FSDK_FACEFEATURE_MEMORY                    (MERR_FSDK_FACEFEATURE_ERROR_BASE+2)    //人脸特征检测内存错误
#define MERR_FSDK_FACEFEATURE_INVALID_FORMAT            (MERR_FSDK_FACEFEATURE_ERROR_BASE+3)    //人脸特征检测格式错误
#define MERR_FSDK_FACEFEATURE_INVALID_PARAM             (MERR_FSDK_FACEFEATURE_ERROR_BASE+4)    //人脸特征检测参数错误
#define MERR_FSDK_FACEFEATURE_LOW_CONFIDENCE_LEVEL      (MERR_FSDK_FACEFEATURE_ERROR_BASE+5)    //人脸特征检测结果置信度低

#define MERR_ASF_EX_BASE                                0x15000                            //ASF错误类型
#define MERR_ASF_EX_FEATURE_UNSUPPORTED_ON_INIT         (MERR_ASF_EX_BASE+1)            //Engine不支持的检测属性
#define MERR_ASF_EX_FEATURE_UNINITED                    (MERR_ASF_EX_BASE+2)            //需要检测的属性未初始化
#define MERR_ASF_EX_FEATURE_UNPROCESSED                 (MERR_ASF_EX_BASE+3)            //待获取的属性未在process中处理过
#define MERR_ASF_EX_FEATURE_UNSUPPORTED_ON_PROCESS      (MERR_ASF_EX_BASE+4)            //PROCESS不支持的检测属性组合，例如FR，有自己独立的处理函数
#define MERR_ASF_EX_INVALID_IMAGE_INFO                  (MERR_ASF_EX_BASE+5)            //无效的输入图像
#define MERR_ASF_EX_INVALID_FACE_INFO                   (MERR_ASF_EX_BASE+6)            //无效的脸部信息

#define MERR_ASF_ACTIVE_BASE                            0x16000                            //激活结果类型
#define MERR_ASF_ACTIVATION_FAIL                        (MERR_ASF_ACTIVE_BASE+1)        //SDK激活失败,请打开读写权限
#define MERR_ASF_ALREADY_ACTIVATED                      (MERR_ASF_ACTIVE_BASE+2)        //SDK已激活
#define MERR_ASF_NOT_ACTIVATED                          (MERR_ASF_ACTIVE_BASE+3)        //SDK未激活

#define MERR_ASF_NETWORK_BASE                           0x17000                            //网络错误类型
#define MERR_ASF_NETWORK_COULDNT_RESOLVE_HOST           (MERR_ASF_NETWORK_BASE+1)        //无法解析主机地址
#define MERR_ASF_NETWORK_COULDNT_CONNECT_SERVER         (MERR_ASF_NETWORK_BASE+2)        //无法连接服务器
#define MERR_ASF_NETWORK_CONNECT_TIMEOUT                (MERR_ASF_NETWORK_BASE+3)        //网络连接超时
#define MERR_ASF_NETWORK_UNKNOWN_ERROR                  (MERR_ASF_NETWORK_BASE+4)        //网络未知错误

#define MERR_ASF_ACTIVE_EX_BASE                         0x20000                            //激活结果类型
#define MERR_ASF_ACTIVE_FILE_NO_EXIST                   (MERR_ASF_ACTIVE_EX_BASE+1)        //激活文件不存在
#define MERR_ASF_PACKAGEID_MISMATCH                     (MERR_ASF_ACTIVE_EX_BASE+2)        //包名不匹配
#define MERR_ASF_PACKAGE_SIGN_MISMATCH                  (MERR_ASF_ACTIVE_EX_BASE+3)        //包签名不匹配
#define MERR_ASF_DEVICE_MISMATCH                        (MERR_ASF_ACTIVE_EX_BASE+4)        //设备不匹配，清重新激活
#define MERR_ASF_CURRENT_DEVICE_TIME_INCORRECT          (MERR_ASF_ACTIVE_EX_BASE+5)        //当前设备时间不正确，请调整设备时间
#define MERR_ASF_ACTIVATION_DATA_DESTROYED              (MERR_ASF_ACTIVE_EX_BASE+6)        //激活数据被破坏,请删除激活文件，重新进行激活
#define MERR_ASF_ACTIVEFILE_SDK_MISMATCH                (MERR_ASF_ACTIVE_EX_BASE+7)        //激活文件与SDK版本不匹配,请重新激活
#define MERR_ASF_SDK_SIGN_CHECK_ERROR                   (MERR_ASF_ACTIVE_EX_BASE+8)        //SDK签名校验错误

#define MERR_ASF_INIT_BASE                              0x21000
#define MERR_ASF_VERSION_NOT_SUPPORT                    (MERR_ASF_INIT_BASE+1)            //操作系统版本不支持
#define MERR_ASF_AUTHORIZATION_EXPIRED                  (MERR_ASF_INIT_BASE+2)            //包授权已过期
#define MERR_ASF_SCALE_NOT_SUPPORT                      (MERR_ASF_INIT_BASE+3)            //detectFaceScaleVal 不支持
#define MERR_ASF_FILE_SDK_INFO_MISMATCH                 (MERR_ASF_INIT_BASE+4)            //激活文件与SDK基础信息不匹配

#define MERR_ASF_FUNCTION_BASE                          0x22000
#define MERR_ASF_COLOR_SPACE_NOT_SUPPORT                (MERR_ASF_FUNCTION_BASE+1)        //颜色空间不支持
#define MERR_ASF_IMAGE_WIDTH_HEIGHT_NOT_SUPPORT         (MERR_ASF_FUNCTION_BASE+2)        //图片宽高不支持，宽度需四字节对齐
#define MERR_ASF_DETECT_MODEL_UNSUPPORTED               (MERR_ASF_FUNCTION_BASE+3)        //检测模型不支持，请查看对应接口说明，使用当前支持的检测模型
#define MERR_ASF_FILE_VERSION_MISMATCH                  (MERR_ASF_FUNCTION_BASE+4)        //文件版本号不匹配

#define MERR_ASF_SERVER_BASE                            0x23000                            //网络错误类型
#define MERR_ASF_PARAM_FORMAT_ERROR                     (MERR_ASF_SERVER_BASE+1)        //请求数据格式错误
#define MERR_ASF_LOCAL_TIME_NOT_CALIBRATED              (MERR_ASF_SERVER_BASE+2)        //客户端时间与服务器时间（即北京时间）前后相差在30分钟以上
#define MERR_ASF_APPID_SDKKEY_PACKAGEID_ERROR           (MERR_ASF_SERVER_BASE+3)        //APPID || SDKKEY || PACKAGEID 存在格式错误
#define MERR_ASF_APPID_PACKAGEID_MISMATCH               (MERR_ASF_SERVER_BASE+4)        //APPID、PACKAGEID 组合不存在
#define MERR_ASF_APPID_PACKAGEID_EXPIRED                (MERR_ASF_SERVER_BASE+5)        //APPID、PACKAGEID 组合授权已过期
#define MERR_ASF_SERVER_PACKAGE_SIGN_MISMATCH           (MERR_ASF_SERVER_BASE+6)        //包签名验证不通过
#define MERR_ASF_ILLEGAL_REQUEST                        (MERR_ASF_SERVER_BASE+7)        //非法请求
#define MERR_ASF_SERVER_SIGN_CHECK_ERROR                (MERR_ASF_SERVER_BASE+8)        //服务端签名校验错误
#define MERR_ASF_SERVER_DECRYPTION_FAILED               (MERR_ASF_SERVER_BASE+9)        //服务端解密失败
#define MERR_ASF_SHORT_TIME_LARGE_REQUEST               (MERR_ASF_SERVER_BASE+10)        //短时间大量请求会被禁止请求,30分钟之后解封
#define MERR_ASF_DATABASE_ERROR                         (MERR_ASF_SERVER_BASE+11)        //激活数据保存异常
#define MERR_ASF_SERVER_UNKNOWN_ERROR                   (MERR_ASF_SERVER_BASE+12)        //服务端未知错误
#define MERR_ASF_ACTIVE_LIMIT_REACHED                   (MERR_ASF_SERVER_BASE+13)        //有效期内授权次数已超出

#endif

