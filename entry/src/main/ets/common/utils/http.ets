import { Log } from '@abner/log';
import { promptAction } from '@kit.ArkUI';
import axios, { AxiosError, AxiosRequestConfig, AxiosResponse, InternalAxiosRequestConfig } from '@ohos/axios';
import { LoginInfoResponse } from '../../api/userAPI';
import { BASE_URL, LOGIN_INFO } from '../constants';

// 创建实例
export const axiosInstance = axios.create({
  baseURL: BASE_URL, // 请求基地址
  timeout: 1000 * 10 // 请求超时时间
})

axiosInstance.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  // 对请求数据做点什么
  const loginInfo = AppStorage.get<LoginInfoResponse>(LOGIN_INFO)
  if (loginInfo?.accessToken) {
    config.headers.set('Authorization', loginInfo.accessToken)
  }
  Log.info(`1-请求配置${config.method!}-${config.url}:${JSON.stringify(config.params || config.data)}`)
  return config;
}, (error: AxiosError) => {
  // 对请求错误做些什么
  Log.error('3-http请求错误：' + JSON.stringify(error))
  return Promise.reject(error);
});

// 添加响应拦截器，AxiosResponse -> AxiosResponseData 书写时有提示
axiosInstance.interceptors.response.use((response: AxiosResponse) => {
  // 对响应数据做点什么
  // response.data.code 存在且不为 200 时，返回错误结果
  if (response.data?.code && response.data.code !== 200) {
    promptAction.showToast({
      message: response.data?.msg
    })
    Log.error('3-code响应错误：' + JSON.stringify(response.data))
    return Promise.reject(response.data)
  }
  Log.warn('2-响应成功结果：' + JSON.stringify(response.data))
  // 简化数据返回，data根据后端返回的数据类型做调整
  return response.data?.result;
}, (error: AxiosError) => {
  promptAction.showToast({ message: error.response?.status + '：' + error.message })
  Log.error('3-http响应错误：' + JSON.stringify(error))
  // 对响应错误做点什么
  return Promise.reject(error);
});

export function request<DataModel = null, DataParams = null>(config: AxiosRequestConfig<DataParams>): Promise<DataModel> {
  return axiosInstance<null, DataModel>(config)
}
