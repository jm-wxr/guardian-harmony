import { promptAction } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import { userAuth } from '@kit.UserAuthenticationKit'

interface AuthType {
  name: string
  type: userAuth.UserAuthType
}

class UserAuthManager {
  // 认证类型列表，按优先级来排列
  private authTypes: AuthType[] = [
    { name: '人脸', type: userAuth.UserAuthType.FACE },
    { name: '指纹', type: userAuth.UserAuthType.FINGERPRINT },
    { name: 'PIN', type: userAuth.UserAuthType.PIN },
  ]
  // 认证信任等级
  private authTrustLevel: userAuth.AuthTrustLevel = userAuth.AuthTrustLevel.ATL3

  // 查询认证能力是否支持
  checkUserAuthSupport(): boolean {
    const authTypeRes: boolean[] = this.authTypes.map(item => {
      try {
        userAuth.getAvailableStatus(item.type, this.authTrustLevel)
        return true
      } catch {
        return false
      }
    })
    promptAction.showToast({
      message: `
      ${this.authTypes[0].name}：${authTypeRes[0] ? '支持' : '不支持'}
      ${this.authTypes[1].name}：${authTypeRes[1] ? '支持' : '不支持'}
      ${this.authTypes[2].name}：${authTypeRes[2] ? '支持' : '不支持'}
      `
    })
    return authTypeRes.some(v => v === true)
  }

  // 开始用户认证
  startUserAuth(): Promise<boolean> {
    return new Promise((resolve, reject) => {
      try {
        // 获取用户认证实例
        const userAuthInstance = userAuth.getUserAuthInstance(
          // 参数一：设置认证参数
          {
            challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
            authType: this.authTypes.map(item => item.type),
            authTrustLevel: this.authTrustLevel
          },
          // 参数二：配置认证界面
          { title: `请验证用户身份` }
        )
        // 执行用户认证
        userAuthInstance.start()
        // 订阅用户身份认证结果
        userAuthInstance.on('result', {
          onResult(result) {
            userAuthInstance.off('result')
            if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
              promptAction.showToast({ message: '用户认证成功' })
              resolve(true)
            } else {
              promptAction.showToast({ message: '用户认证失败' })
              resolve(false)
            }
          }
        })
      } catch (error) {
        const err: BusinessError = error as BusinessError
        AlertDialog.show({ message: `auth catch error. Code is ${err?.code}, message is ${err?.message}` })
        reject(false)
      }
    })
  }
}

export const userAuthManager = new UserAuthManager()