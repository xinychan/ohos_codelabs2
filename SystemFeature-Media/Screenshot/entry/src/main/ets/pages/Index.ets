/*
 * Copyright (c) 2022-2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import prompt from '@ohos.promptAction'
import {
  Logger,
  ResponseData,
  hasPrivate,
  getCurrentWindow,
  setWindowPrivacyMode,
  getScreenshot,
  setFullScreen,
} from '@ohos/feature'

const OPACITY: number = 0.2 // 裁剪框透明度
const CUT_INDEX: number = 2 // 裁剪框z-index
const SAVE_INDEX: number = 3 // 保存按钮z-index
const RANGE: number = 20 // 裁剪框点击范围
const SCALE: number = 0.5 // 缩放比例

@CustomDialog
struct ScreenshotDialog {
  screenshotController: CustomDialogController
  @Link screenshotUrl: PixelMap
  @Link isScroll: boolean

  build() {
    Scroll() {
      Column() {
        Image(this.screenshotUrl)
      }
      .borderRadius(10)
      .padding(20)
      .backgroundColor(Color.White)
    }
    .id('screenResult')
    .scrollable(this.isScroll ? ScrollDirection.None : ScrollDirection.Vertical)
    .scale({ x: SCALE, y: SCALE })
    .onClick(() => {
      this.screenshotController.close()
    })
  }
}

@Entry
@Component
struct Index {
  @State screenshotUrl: PixelMap = undefined
  @State cropBoxWidth: number = 300 // 裁剪框宽
  @State cropBoxHeight: number = 100 // 裁剪框高
  @State leftTopPositionX: number = 50 // 裁剪框左上角X轴坐标
  @State leftTopPositionY: number = 300 // 裁剪框左上角Y轴坐标
  @State startTouchPositionX: number = 0 // 开始触摸点X轴坐标
  @State startTouchPositionY: number = 0 // 开始触摸点Y轴坐标
  @State startOffsetX: number = 0 // 开始触摸点相对于被触摸元素左边缘的X轴坐标
  @State startOffsetY: number = 0 // 开始触摸点相对于被触摸元素左边缘的Y轴坐标
  @State fullScreenWidth: number = 0 // 全屏宽度（单位 px）
  @State fullScreenHeight: number = 0 // 全屏高度（单位 px）
  @State isFullScreen: boolean = false
  @State isTouch: boolean = true
  @State isCut: boolean = true
  @State isPrivacy: boolean = false
  @State isScroll: boolean = true
  screenshotDialogController: CustomDialogController = new CustomDialogController({
    builder: ScreenshotDialog({ screenshotUrl: $screenshotUrl, isScroll: $isScroll }),
    autoCancel: true,
    customStyle: true,
    offset: { dx: -100, dy: 100 }
  })

  // 初始化局部裁剪功能 event 触摸事件
  initCutEvent(event: TouchEvent) {
    // 记录手指信息初始位置
    if (event.type === TouchType.Down && this.isTouch) {
      // 触摸点坐标
      this.startTouchPositionX = event.touches[0].screenX
      this.startTouchPositionY = event.touches[0].screenY
      // 触摸点相对于被触摸元素左边缘的坐标
      this.startOffsetX = event.touches[0].x
      this.startOffsetY = event.touches[0].y
      this.isTouch = false
    }

    // 手指离开
    if (event.type === TouchType.Up) {
      this.isTouch = true
    }

    if (event.type === TouchType.Move) {
      // 表示当前在移动裁剪框左上角
      if (this.startOffsetX < RANGE && this.startOffsetY < RANGE && this.checkLeftTopValid(event)) {
        // 当前触摸点相对先前触摸点的移动距离
        let moveX = event.touches[0].screenX - this.startTouchPositionX
        let moveY = event.touches[0].screenY - this.startTouchPositionY

        // 每次触摸都重新记录触摸位置
        this.startTouchPositionX = event.touches[0].screenX
        this.startTouchPositionY = event.touches[0].screenY

        // 更新裁剪框左上角与屏幕左上角的X轴、Y轴距离
        this.leftTopPositionX = this.leftTopPositionX + moveX
        this.leftTopPositionY = this.leftTopPositionY + moveY

        // 更新裁剪框大小
        this.cropBoxWidth -= moveX
        this.cropBoxHeight -= moveY
      }

      let offsetX = this.cropBoxWidth - this.startOffsetX
      let offsetY = this.cropBoxHeight - this.startOffsetY
      // 表示当前在移动裁剪框右下角
      if (offsetX < RANGE && offsetY < RANGE && this.checkRightBottomValid(event)) {
        // 当前触摸点相对先前触摸点的移动距离
        let moveX = event.touches[0].screenX - this.startTouchPositionX
        let moveY = event.touches[0].screenY - this.startTouchPositionY

        // 每次触摸都重新记录位置
        this.startTouchPositionX = event.touches[0].screenX
        this.startTouchPositionY = event.touches[0].screenY

        // 更新触摸点相对于被触摸元素左边缘的坐标
        this.startOffsetX = event.touches[0].x
        this.startOffsetY = event.touches[0].y

        // 改变裁剪框大小
        this.cropBoxWidth += moveX
        this.cropBoxHeight += moveY
      }
    }
  }

  // 判断裁剪框左上角的坐标移动是否合规
  checkLeftTopValid(event: TouchEvent): boolean {
    // 当前触摸点相对先前触摸点的移动距离
    let moveX = event.touches[0].screenX - this.startTouchPositionX
    let moveY = event.touches[0].screenY - this.startTouchPositionY

    // 触摸点要位于裁剪框的右下角之上、且要保证不溢出屏幕边缘
    if (event.touches[0].screenX < this.cropBoxWidth + this.leftTopPositionX
        && event.touches[0].screenY < this.cropBoxHeight + this.leftTopPositionY
        && this.leftTopPositionX + moveX > 0
        && this.leftTopPositionY + moveY > 0) {
      // 合规
      return true
    }

    // 不合规
    return false
  }

  // 判断裁剪框右下角的坐标移动是否合规
  checkRightBottomValid(event: TouchEvent): boolean {
    // 当前触摸位置相对先前触摸位置的移动距离
    let moveX = event.touches[0].screenX - this.startTouchPositionX
    let moveY = event.touches[0].screenY - this.startTouchPositionY

    // 触摸点要位于裁剪框的左上角之下、且要保证不溢出屏幕边缘
    if (event.touches[0].screenX > this.leftTopPositionX
        && event.touches[0].screenY > this.leftTopPositionY
        && this.leftTopPositionX + this.cropBoxWidth + moveX < px2vp(this.fullScreenWidth)
        && this.leftTopPositionY + this.cropBoxHeight + moveY < px2vp(this.fullScreenHeight)) {
      // 合规
      return true
    }

    // 不合规
    return false
  }

  @Builder MenuBuilder() {
    Column() {
      Column() {
        Text($r('app.string.shot_screen'))
          .fontSize(18)
          .margin({ bottom: 20 })
          .textAlign(TextAlign.Start)

        Row() {
          Image($r('app.media.shot_all'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .margin({ right: 20 })

          Column() {
            Text($r('app.string.shot_full_screen'))
              .fontSize(18)
          }
        }
        .margin({ bottom: 20 })
        .id('screenShot')
        .onClick(() => {
          this.isScroll = true
          let result: ResponseData = hasPrivate()
          if (result.status === 'failed') {
            prompt.showToast({
              message: result.errorMessage
            })
            return
          }
          if (result.status === 'success' && result.result) {
            prompt.showToast({
              message: $r('app.string.private_toast'),
              duration: 10000
            })
            return
          }
          let promise = getScreenshot()
          try {
            promise.then(res => {
              this.screenshotUrl = res
              this.screenshotDialogController.open()
            })
          } catch (error) {
            prompt.showToast({
              message: `${error}`
            })
          }
        })

        Row() {
          Image($r('app.media.shot_part'))
            .width(20)
            .height(20)
            .margin({ right: 20 })
            .objectFit(ImageFit.Contain)

          Column() {
            Text($r('app.string.shot_part_screen'))
              .fontSize(18)
          }
        }
        .id('localScreenShot')
        .onClick(() => {
          this.isScroll = false
          // 恢复裁剪框相关初始参数
          this.cropBoxWidth = 300
          this.cropBoxHeight = 100
          this.leftTopPositionX = 50
          this.leftTopPositionY = 300
          let result: ResponseData = hasPrivate()
          if (result.status === 'failed') {
            prompt.showToast({
              message: result.errorMessage
            })
            return
          }
          if (result.status === 'success' && result.result) {
            prompt.showToast({
              message: $r('app.string.private_toast'),
              duration: 10000
            })
            return
          }
          setFullScreen(getContext(this), true)
          let promise = getScreenshot()
          try {
            promise.then(res => {
              this.screenshotUrl = res
              getCurrentWindow(getContext(this))
                .then(data => data.getProperties())
                .then(res => {
                  this.fullScreenWidth = res.windowRect.width
                  this.fullScreenHeight = res.windowRect.height
                })
              this.isFullScreen = true
            })
          } catch (error) {
            prompt.showToast({
              message: JSON.stringify(error)
            })
          }
        })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding(20)
  }

  build() {
    if (!this.isFullScreen) {
      Column({ space: 30 }) {
        Flex({ justifyContent: FlexAlign.SpaceBetween }) {
          Text($r('app.string.shot_screen'))
            .fontSize(25)

          Image($r('app.media.more'))
            .id('menu')
            .width(30)
            .height(30)
            .objectFit(ImageFit.Contain)
            .bindMenu(this.MenuBuilder)
        }
        .width('100%')
        .padding(20)

        Flex({ justifyContent: FlexAlign.SpaceBetween }) {
          Row() {
            Image($r('app.media.privacy'))
              .width(20)
              .height(20)
              .objectFit(ImageFit.Contain)
              .margin({ right: 10 })

            Text($r('app.string.private_window'))
              .fontSize(18)
          }

          Toggle({ type: ToggleType.Switch, isOn: false })
            .id('privacy')
            .size({ width: 40, height: 20 })
            .selectedColor($r('app.color.selected_color'))
            .switchPointColor($r('app.color.switch_point_color'))
            .onChange((isOn: boolean) => {
              setWindowPrivacyMode(getContext(this), isOn)
            })
            .blur(0)
            .borderStyle(BorderStyle.Dotted)
            .visibility(Visibility.Visible)
            .focusable(true)
            .focusOnTouch(false)
            .defaultFocus(false)
            .touchable(true)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })

        Image($r('app.media.image'))
          .width(400)
          .height(300)
          .objectFit(ImageFit.Contain)
      }
      .width('100.00%')
    } else {
      Stack() {
        Image(this.screenshotUrl)
          .width('100%')
          .height('100%')
          .position({ x: 0, y: 0 })
          .objectFit(ImageFit.Contain)

        Column()
          .width(this.fullScreenWidth)
          .height(this.fullScreenHeight)
          .position({ x: 0, y: 0 })
          .backgroundColor(Color.Black)
          .opacity(OPACITY)
          .clip(new Path({
            width: vp2px(this.cropBoxWidth),
            height: vp2px(this.cropBoxHeight),
            commands: `M 0 0 H ${this.fullScreenWidth} V ${vp2px(this.leftTopPositionY)} H ${vp2px(this.leftTopPositionX)}
             V ${vp2px(this.leftTopPositionY + this.cropBoxHeight)} H ${vp2px(this.leftTopPositionX + this.cropBoxWidth)}
              V ${vp2px(this.leftTopPositionY)} H ${this.fullScreenWidth} V ${this.fullScreenHeight} H 0 V 0 Z`
          }))

        if (this.isCut) {
          Column() {
            Image($r('app.media.left_top'))
              .width(22)
              .height(22)
              .objectFit(ImageFit.Contain)
              .position({ x: -4, y: -4 })

            Image($r('app.media.right_bottom'))
              .width(22)
              .height(22)
              .objectFit(ImageFit.Contain)
              .position({ x: this.cropBoxWidth - 18, y: this.cropBoxHeight - 18 })
          }
          .width(this.cropBoxWidth)
          .height(this.cropBoxHeight)
          .zIndex(CUT_INDEX)
          .position({ x: this.leftTopPositionX, y: this.leftTopPositionY })
          .onTouch((event: TouchEvent) => {
            this.initCutEvent(event)
          })

          Button($r('app.string.finish'))
            .id('finish')
            .zIndex(SAVE_INDEX)
            .position({ x: '80%', y: '80%' })
            .translate({ x: '-100%', y: '-100%' })
            .onClick(() => {
              let screenshotOption = {
                'screenRect': {
                  'left': vp2px(this.leftTopPositionX),
                  'top': vp2px(this.leftTopPositionY),
                  'width': vp2px(this.cropBoxWidth),
                  'height': vp2px(this.cropBoxHeight) },
                'imageSize': {
                  'width': vp2px(this.cropBoxWidth),
                  'height': vp2px(this.cropBoxHeight) }
              }
              this.isCut = false
              try {
                let promise = getScreenshot(screenshotOption)
                promise.then(res => {
                  this.screenshotUrl = res
                  this.isFullScreen = false
                  setFullScreen(getContext(this), false)
                  this.screenshotDialogController.open()
                  this.isCut = true
                })
              } catch (exception) {
                Logger.error('fail to get because ' + JSON.stringify(exception))
              }
            })
        }
      }
      .height('100%')
      .width('100%')
    }
  }
}
