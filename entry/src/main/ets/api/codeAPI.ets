import { request } from '../common/utils';

export interface CodeSmsSend {
  /** 业务类型，1：手机号短信验证码登录，2：忘记密码，3：注册账号，4：添加紧急联系人，5：手机号申诉 */
  bizType?: number;

  /** 手机号 */
  phone: string;
}

/** 图形验证码校验 */
export interface CodeGraphicCheck extends CodeSmsSend {
  /** 验证码 */
  verifyCode: string;
}

export enum BizType {
  /** 手机号登录 */
  PhoneLogin = 1,
  /** 找回密码 */
  FindPassword = 2,
  /** 注册账户 */
  RegisterAccount = 3,
  /** 添加紧急联系人 */
  EmergencyContact = 4,
  /** 手机号申诉 */
  PhoneAppeal = 5
}

/**
 * 校验图形验证码
 * @param data 请求数据
 */
export const codeGraphicCheckAPI = (data: CodeGraphicCheck): Promise<object | null> => {
  return request<object | null, CodeGraphicCheck>({
    url: '/code/graphic/check',
    method: 'POST',
    data
  })
}

/**
 * 发送短信验证码
 * @param data 请求数据
 */
export const codeSmsSendAPI = (data: CodeSmsSend): Promise<object | null> => {
  return request<object | null, CodeSmsSend>({
    url: '/code/sms/send',
    method: 'POST',
    data
  })
}