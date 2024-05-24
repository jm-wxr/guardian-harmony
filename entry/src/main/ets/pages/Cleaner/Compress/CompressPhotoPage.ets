import { promptAction } from '@kit.ArkUI'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { NavigationTitleBuilder } from '../../../common/builders'
import { formatByteLength } from '../../../common/utils'
import { cleanerManager, themeManager } from '../../../manager'

@Entry
@Component
struct CompressPhotoIndexPage {
  @State list: photoAccessHelper.PhotoAsset[] = []
  @State selectedName: string[] = []
  @State selectedSize: number = 0

  onPageShow() {
    themeManager.settingStatusBarWhite()
    this.getList()
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
  }

  // TODO：立即瘦身（压缩照片）
  async getList() {
    this.list = await cleanerManager.getLargeSizeList()
  }

  // 立即瘦身
  async startCompress() {
    const promiseTasks = this.selectedName.map(async item => {
      return await cleanerManager.compressPhoto(item)
    })
    await Promise.all(promiseTasks)
    const res = await promptAction.showDialog({
      alignment: DialogAlignment.Center,
      title: '瘦身成功',
      message: `成功压缩${this.selectedName.length}张图片，是否删除原图`,
      buttons: [
        { text: '取消', color: '#999' },
        { text: '确定', color: $r('sys.color.ohos_id_color_primary') }
      ]
    })
    if (res.index === 1) {
      await cleanerManager.deleteAssets(this.selectedName)
      this.getList()
    }
  }

  build() {
    Navigation() {
      Stack({ alignContent: Alignment.Bottom }) {
        Scroll() {
          Column() {
            Column() {
              Column({ space: 10 }) {
                Text() {
                  Span('预计节省')
                  Span(formatByteLength(this.selectedSize))
                }
                .fontSize(16)
                .fontColor($r('app.color.white'))

                Text(this.selectedName.length + '张可瘦身照片')
                  .fontSize(12)
                  .fontColor($r('app.color.white'))
              }
            }
            .height(80)
            .justifyContent(FlexAlign.Center)

            Column() {
              Column({ space: 20 }) {
                Text('瘦身后的照片会被放到系统相册最前，以便查看')
                  .fontSize(14)
                  .fontColor($r('app.color.font_sub'))
                  .width('100%')
                  .padding({ left: 20, right: 20 })
                List() {
                  ListItem() {
                    GridRow({ gutter: 8, columns: 4 }) {
                      ForEach(this.list, (item: photoAccessHelper.PhotoAsset) => {
                        GridCol() {
                          Stack({ alignContent: Alignment.TopStart }) {
                            // TODO: 共享元素转场
                            Image(item.uri)
                              .width('100%')
                              .height('100%')
                              .objectFit(ImageFit.Cover)
                              .autoResize(true)
                              .interpolation(ImageInterpolation.Medium)
                              .onClick(() => {
                                // 打开对比
                              })
                            Checkbox({ name: item.uri })
                              .selectedColor($r('app.color.brand'))
                          }
                          .width('100%')
                          .aspectRatio(1)
                          .borderRadius(6)
                          .clip(true)
                        }
                      })
                    }
                  }

                  ListItem()
                    .height(120)
                }
                .width('100%')
                .height('100%')
                .sticky(StickyStyle.Header) // 固定分组标题
                .padding({ left: 20, right: 20 })
              }
              .padding({ top: 20, bottom: 20 })
            }
            .backgroundColor($r('app.color.white'))
            .layoutWeight(1)
            .width('100%')
          }
        }
        .width('100%')
        .height('100%')

        // 底部操作按钮
        Row({ space: 15 }) {
          Column() {
            CheckboxGroup()
              .selectedColor($r('app.color.brand'))
              .onChange((value) => {
                this.selectedName = value.name
              })
            Text('全选')
              .fontSize(14)
              .fontColor($r('app.color.font2'))
          }

          Button(`立即瘦身(${this.selectedName.length}张）`)
            .type(ButtonType.Normal)
            .borderRadius(10)
            .backgroundColor($r('app.color.brand'))
            .layoutWeight(1)
            .enabled(this.selectedName.length > 0)
            .onClick(() => {
              // TODO：立即瘦身（压缩照片）
              this.startCompress()
            })
        }
        .width('100%')
        .height(76)
        .backgroundColor($r('app.color.white'))
        .padding({ left: 20, right: 20 })
        .border({ width: { top: 1 }, color: $r('app.color.border') })
      }
    }
    .title(NavigationTitleBuilder('照片瘦身'))
    .hideBackButton(true)
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .linearGradient({
      direction: 213,
      colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 0.3], [$r('app.color.white'), 0.3]]
    })
  }
}