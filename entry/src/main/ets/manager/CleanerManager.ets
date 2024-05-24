import { Permissions } from '@kit.AbilityKit'
import { dataSharePredicates } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import fs from '@ohos.file.fs'
import { permissionManager } from '.'
import { KILO_BYTE } from '../common/utils'

class CleanerManager {
  // 权限
  private permissions: Permissions[] = ["ohos.permission.READ_IMAGEVIDEO", "ohos.permission.WRITE_IMAGEVIDEO"]
  // 图片字段
  private columns: photoAccessHelper.PhotoKeys[] = [
    photoAccessHelper.PhotoKeys.DATE_ADDED,
    photoAccessHelper.PhotoKeys.SIZE,
    photoAccessHelper.PhotoKeys.WIDTH,
    photoAccessHelper.PhotoKeys.HEIGHT,
  ]

  // 申请相册权限
  async requestPermissions() {
    try {
      await permissionManager.requestPermissions(this.permissions)
    } catch (err) {
      // 权限未通过 弹窗提示
      const dialogRes = await promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '手机瘦身功能需要获取权限，请在系统设置中打开相册开关',
        buttons: [
          { text: '取消', color: $r('app.color.font_sub') },
          { text: '立即开启', color: $r('app.color.brand') }
        ]
      })
      if (dialogRes.index === 1) {
        permissionManager.openPermissionSettingsPage()
      }
    }
  }

  // 获取图片/视频
  async getAssets() {
    // 相册管理器
    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
    // 相册筛选条件（谓词查询）
    const predicates = new dataSharePredicates.DataSharePredicates()
    // 根据条件获取结果
    const fetchResult = await phAccessHelper.getAssets({
      // 参数为空时默认查询uri、name、photoType
      fetchColumns: this.columns,
      // 谓词查询，显示过滤条件
      predicates: predicates
    })
    // 获取图片资源
    const photoAssets = await fetchResult.getAllObjects()
    return photoAssets
  }

  // 获取用户相册
  async getAlbums() {
    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
    const fetchResult = await phAccessHelper.getAlbums(
      photoAccessHelper.AlbumType.USER,
      photoAccessHelper.AlbumSubtype.USER_GENERIC
    )
    const albums = await fetchResult.getAllObjects()
    return albums
  }

  // 获取屏幕截图列表
  async getScreenshotList() {
    const photoAssets = await this.getAssets()
    return photoAssets.filter(item => item.displayName.includes('screenshot'))
  }

  // 获取视频列表
  async getVideoList() {
    const photoAssets = await this.getAssets()
    return photoAssets.filter(item => item.photoType === photoAccessHelper.PhotoType.VIDEO)
  }

  // 删除图片/视频
  async deleteAssets(uris: string[]) {
    try {
      const photoAssets = await this.getAssets()
      // 获取要删除的图片数组
      const deleteAssets = photoAssets.filter(v => uris.includes(v.uri))
      await photoAccessHelper.MediaAssetChangeRequest.deleteAssets(getContext(), deleteAssets)
      return Promise.resolve(true)
    } catch (err) {
      return Promise.resolve(false)
    }
  }

  // 获取大尺寸(大于200KB)图片，用于压缩
  async getLargeSizeList() {
    const photoAssets = await this.getAssets()
    return photoAssets.filter(item => item.get(photoAccessHelper.PhotoKeys.SIZE) as number > 200 * KILO_BYTE)
  }

  // 压缩图片
  async compressPhoto(uri: string, quality: number = 20) {
    // --------- 压缩图片核心代码 -----------
    // 根据 uri 打开图片文件
    const file = fs.openSync(uri)
    // 创建图片源实例（用文件fd创建）
    const imageSource = image.createImageSource(file.fd)
    // 创建图片打包器(用于图片压缩)
    const imagePacker = image.createImagePacker()
    // arrayBuffer -> 二进制文件数据流   quality -> 值越小，压缩后的图片越小
    const arrayBuffer = await imagePacker.packing(imageSource, { format: 'image/jpeg', quality: quality })
    // --------- 压缩图片核心代码 -----------

    // --------- 写入图库 -----------
    // 获取相册管理模块实例
    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
    // 创建新的图片资源，返回其uri
    const assetUri = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg')
    // 根据 uri 打开文件，设置打开模式为 READ_WRITE / WRITE_ONLY
    const assetFile = fs.openSync(assetUri, fs.OpenMode.READ_WRITE)
    // 往打开的文件里写入arrayBuffer
    fs.writeSync(assetFile.fd, arrayBuffer)
    // 关闭文件
    fs.closeSync(assetFile.fd)
    // --------- 写入图库 -----------
  }
}

export const cleanerManager = new CleanerManager()