import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit'

@Entry
@Component
struct PermissionTestPage {

  build() {
    Navigation() {
      Scroll() {
          Column() {
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
                AlertDialog.show({message: JSON.stringify(grantStatus, null, 2)})
              })
          }
        .constraintSize({minHeight: '100%'})
      }
      .width('100%')
      .height('100%')
    }
    .title('权限学习')
    .titleMode(NavigationTitleMode.Mini)
  }
}