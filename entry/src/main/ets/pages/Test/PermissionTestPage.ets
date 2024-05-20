import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { permissionManager } from '../../manager'

@Entry
@Component
struct PermissionTestPage {
  build() {
    Navigation() {
      Scroll() {
        Column({ space: 10 }) {
          Button('检测权限')
            .onClick(() => {
              // 程序访问控制管理
              const atManager = abilityAccessCtrl.createAtManager()
              // 获取 bundle (应用包)信息
              const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
              // 应用唯一标识
              const tokenID = bundleInfo.appInfo.accessTokenId
              // 检测权限
              const grantStatus = atManager.checkAccessTokenSync(tokenID, 'ohos.permission.READ_CALENDAR')
              AlertDialog.show({ message: JSON.stringify(grantStatus, null, 2) })
            })
          Button('向用户申请权限')
            .onClick(async () => {
              // 核心API：requestPermissionsFromUser
              // 1. 程序访问控制管理
              const atManager = abilityAccessCtrl.createAtManager()
              // 2. 动态的向用户申请权限
              const result = await atManager.requestPermissionsFromUser(getContext(),
                // 权限组，共用同一个弹窗
                ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'])
              AlertDialog.show({ message: JSON.stringify(result, null, 2) })
            })
          Button('打开系统设置页')
            .onClick(() => {
              // 获取上下文
              const context = getContext() as common.UIAbilityContext
              // 获取包信息
              const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
              // 打开系统设置页
              context.startAbility({
                bundleName: 'com.huawei.hmos.settings',
                abilityName: 'com.huawei.hmos.settings.MainAbility',
                uri: 'application_info_entry',
                parameters: {
                  // 按照包名打开对应设置页
                  pushParams: bundleInfo.name
                }
              })
            })
          Divider()
          // 测试封装后的权限管理API
          Button('检查权限-封装')
            .onClick(() => {
              const res = permissionManager.checkPermissions(['ohos.permission.CAMERA'])
              AlertDialog.show({ message: res ? '已授权' : '未授权' })
            })
          Button('申请权限-封装')
            .onClick(async () => {
              try {
                const res = await permissionManager.requestPermissions(['ohos.permission.CAMERA'])
                AlertDialog.show({ message: '已授权相机权限：' + res })
              } catch (error) {
                const res = await promptAction.showDialog({
                  message: '未开启相机权限，请到系统设置页进行设置',
                  alignment: DialogAlignment.Center,
                  buttons: [
                    { text: '取消', color: $r('app.color.font_sub') },
                    { text: '去设置', color: $r('app.color.success') }
                  ]
                })
                if (res.index === 1) {
                  permissionManager.openPermissionSettingsPage()
                }
              }
            })
          Button('打开系统设置-封装')
            .onClick(() => {
              permissionManager.openPermissionSettingsPage()
            })
        }
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
    }
    .title('权限测试')
    .titleMode(NavigationTitleMode.Mini)
  }
}