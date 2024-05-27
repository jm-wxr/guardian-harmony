import { router } from '@kit.ArkUI'
import { PRIVACY_SETTINGS, PrivacySettings } from '../../../common/constants'
import { encryptMD5 } from '../../../common/utils'
import { userAuthManager } from '../../../manager'

@Entry
@Component
struct AuthPatternLockPage {
  // 获取 AppStorage 的数据
  @StorageLink(PRIVACY_SETTINGS) privacySettings: PrivacySettings = {}
  // 错误提示语
  @State errorMessage: string = ''
  // 错误输入次数
  @State errorInputCount: number = 0
  // 是否允许操作
  @State isEnable: boolean = true
  // 图形密码控制器
  private patternLockController: PatternLockController = new PatternLockController()

  onPageShow(): void {
    this.startUserAuth()
  }

  // 设置错误提示
  setErrorMessage(message: string) {
    this.errorMessage = message
    this.patternLockController.setChallengeResult(PatternLockChallengeResult.WRONG)
  }

  // 清除错误提示
  clearErrorMessage() {
    this.errorMessage = ''
    this.patternLockController.setChallengeResult(PatternLockChallengeResult.CORRECT)
  }

  // 手势密码输入完成
  onPatternComplete(input: number[]) {
    // 校验长度，如果小于4，提示重新输入
    if (input.length < 4) {
      this.setErrorMessage('手势密码长度不能小于4位，请重新输入')
    } else {
      // 长度符合规范
      this.clearErrorMessage()
      if (this.privacySettings.patternPassword === encryptMD5(input.toString())) {
        router.pushUrl({ url: 'pages/Privacy/PrivacyIndexPage' })
      } else {
        this.setErrorMessage('手势密码不正确，请重新绘制')
      }
    }
  }

  // 用户身份识别
  async startUserAuth() {
    // 检查是否已经开启了用户身份认证
    if (this.privacySettings.isOpenUserAuthLock) {
      // 用户认证
      if (await userAuthManager.startUserAuth()) {
        // 认证成功，跳转到隐私空间
        router.replaceUrl({ url: 'pages/Privacy/PrivacyIndexPage' })
      } else if (this.privacySettings.isOpenAntiCracking) {
        // TODO: 防破解，超过 3 次锁定 1 分钟
      }
    }
  }

  build() {
    Column() {
      // 标题
      Navigation() {
        Column({ space: 20 }) {
          Column({ space: 10 }) {
            // 请输入密码
            Text(this.isEnable ? '请输入密码' : '隐私空间已锁定')
              .fontSize(16)
              .fontColor($r('app.color.font'))
            if (this.errorMessage) {
              Text(this.errorMessage)
                .fontSize(12)
                .fontColor($r('app.color.danger'))
            } else {
              Text('输入密码进入隐私空间')
                .fontSize(12)
                .fontColor($r('app.color.font_sub'))
            }
          }

          PatternLock(this.patternLockController)
            .sideLength(320)// 宽高
            .circleRadius(12)// 圆点半径
            .pathStrokeWidth(10)// 线宽度
            .regularColor('#ffd9d9d9')// 未选中圆点色
            .activeColor('#800a59f7')// 经过圆点色
            .selectedColor(this.errorMessage ? '#ffff5e5d' : '#ff0a59f7')// 选中圆点色
            .pathColor(this.errorMessage ? '#ccff5e5d' : '#cc0a59f7')// 线颜色
            .enabled(this.isEnable)
            .onDotConnect(() => {
              this.clearErrorMessage()
            })
            .onPatternComplete((input: number[]) => {
              // TODO：密码输入结束时触发该回调
              this.onPatternComplete(input)
            })

          Row({ space: 20 }) {
            Text('忘记密码')
              .fontSize(14)
              .fontColor($r('app.color.font2'))
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/Privacy/Auth/ForgetPasswordPage',
                })
              })
          }
        }
        .padding({ top: 140 })
      }
      .title('隐私空间')
      .titleMode(NavigationTitleMode.Mini)
      .mode(NavigationMode.Stack)
      .hideTitleBar(false)
    }
    .height('100%')
  }
}