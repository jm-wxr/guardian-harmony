import { router } from '@kit.ArkUI'

@Entry
@Component
struct TestIndexPage {
  build() {
    Navigation() {
      Scroll() {
        Column() {

        }
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
    }
    .title('')
    .titleMode(NavigationTitleMode.Mini)
  }
}