import { photoAccessHelper } from '@kit.MediaLibraryKit'
import dayjs from 'dayjs'
import { cleanerManager } from '../../manager'

const KILO_BYTE = 1000

@Entry
@Component
struct MediaLibraryKitTestPage {
  @State photoAssets: photoAccessHelper.PhotoAsset[] = []
  @State albums: photoAccessHelper.Album[] = []

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 10 }) {
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('获取相册权限')
              .onClick(() => {
                cleanerManager.requestPermissions()
              })
            Button('获取所有图片/视频')
              .onClick(async () => {
                this.photoAssets = await cleanerManager.getAssets()
              })
            Button('获取相册')
              .onClick(async () => {
                this.albums = await cleanerManager.getAlbums()
              })
            Button('获取所有截图')
              .onClick(async () => {
                this.photoAssets = await cleanerManager.getScreenshotList()
              })
            Button('获取所有视频')
              .onClick(async () => {
                this.photoAssets = await cleanerManager.getVideoList()
              })
            Button('删除第一张图片')
              .onClick(async () => {
                await cleanerManager.deleteAssets([this.photoAssets[0].uri])
                this.photoAssets = await cleanerManager.getAssets()
              })
            Button('删除所有图片')
              .onClick(async () => {
                await cleanerManager.deleteAssets(this.photoAssets.map(v => v.uri))
                this.photoAssets = await cleanerManager.getAssets()
              })
          }

          Text('照片')
            .fontSize(20)
          ForEach(this.photoAssets, (item: photoAccessHelper.PhotoAsset) => {
            Row() {
              Image(item.uri)
                .width(100)
              Column() {
                Text('图片大小：' + (item.get('size') as number / KILO_BYTE).toFixed(2) + 'kb')
                Text('图片添加时间：' +
                  (item.get('date_added') as number ? dayjs(item.get('date_added') as number * 1000)
                    .format('YYYY-MM-DD HH:mm:ss') : ''))
                Text('图片宽度：' + item.get('width'))
                Text('图片高度：' + item.get('height'))
              }
            }
          })
          Text('相册')
            .fontSize(20)
          ForEach(this.albums, (item: photoAccessHelper.Album) => {
            Row() {
              Image(item.coverUri)
                .width(100)
              Column() {
                Text('相册名：' + item.albumName)
                Text('照片数：' + item.count)
              }
            }
            .width('100%')
          })
        }
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
    }
    .title('媒体库管理测试')
    .titleMode(NavigationTitleMode.Mini)
  }
}