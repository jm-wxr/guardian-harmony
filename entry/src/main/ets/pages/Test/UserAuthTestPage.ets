import { BusinessError } from '@kit.BasicServicesKit'
import { userAuth } from '@kit.UserAuthenticationKit'

@Entry
@Component
struct UserAuthTestPage {
  build() {
    Navigation() {
      Scroll() {
        Column({ space: 10 }) {
          Button('查询认证能力')
            .onClick(() => {
              try {
                userAuth.getAvailableStatus(
                  userAuth.UserAuthType.PIN,
                  userAuth.AuthTrustLevel.ATL1
                )
                AlertDialog.show({ message: '支持 PIN 认证' })
              } catch (error) {
                AlertDialog.show({ message: JSON.stringify(error) })
              }
            })
          Button('用户认证')
            .onClick(() => {
              try {
                // 获取用户认证实例
                const userAuthInstance = userAuth.getUserAuthInstance(
                  // 参数一：设置认证参数
                  {
                    challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
                    authType: [
                      userAuth.UserAuthType.PIN, // 锁屏密码
                      userAuth.UserAuthType.FACE, // 人脸
                      userAuth.UserAuthType.FINGERPRINT// 指纹
                    ],
                    authTrustLevel: userAuth.AuthTrustLevel.ATL3
                  },
                  // 参数二：配置认证界面
                  { title: '请验证用户身份' }
                )
                // 执行用户认证
                userAuthInstance.start()
                // 订阅用户身份认证结果
                userAuthInstance.on('result', {
                  onResult(result) {
                    userAuthInstance.off('result')
                    if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
                      AlertDialog.show({ message: '用户认证成功' })
                    } else {
                      AlertDialog.show({ message: '用户认证失败' })
                    }
                  }
                })
              } catch (error) {
                const err: BusinessError = error as BusinessError
                AlertDialog.show({ message: `auth catch error. Code is ${err?.code}, message is ${err?.message}` })
              }
            })
        }
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
    }
    .title('用户身份认证测试')
    .titleMode(NavigationTitleMode.Mini)
  }
}