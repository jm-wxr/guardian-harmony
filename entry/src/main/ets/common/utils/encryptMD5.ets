import { CryptoJS } from '@ohos/crypto-js'

// MD5 加密函数
export function encryptMD5(str: string) {
  const wordArray = CryptoJS.MD5(str)
  return wordArray.toString()
}