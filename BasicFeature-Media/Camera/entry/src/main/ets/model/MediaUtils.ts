/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// @ts-nocheck

import photoAccessHelper from '@ohos.file.photoAccessHelper';
import DateTimeUtil from '../model/DateTimeUtil';
import Logger from '../model/Logger';
import { Constants, SettingDataObj } from '../common/Constants';
import common from '@ohos.app.ability.common';

let context = getContext(this) as common.Context;

export default class MediaUtils {
  private tag: string = 'MediaUtils';
  private mediaTest: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
  private static instance: MediaUtils = new MediaUtils();
  private num: number = 0;
  private settingDataObj: SettingDataObj = {
    mirrorBol: false,
    videoStabilizationMode: 0,
    exposureMode: 1,
    focusMode: 2,
    photoQuality: 1,
    locationBol: false,
    photoFormat: 1,
    photoOrientation: 0,
    photoResolution: 0,
    videoResolution: 0,
    videoFrame: 0,
    referenceLineBol: false
  };

  public static getInstance() {
    if (this.instance === undefined) {
      this.instance = new MediaUtils();
    }
    return this.instance;
  }

  async createAndGetUri(mediaType: number) {
    let info = this.getInfoFromType(mediaType);
    let dateTimeUtil = new DateTimeUtil();
    let name = `${dateTimeUtil.getDate()}_${dateTimeUtil.getTime()}`;
    let displayName = `${info.prefix}${name}${info.suffix}`;
    Logger.info(this.tag, `createAndGetUri displayName = ${displayName},mediaType = ${mediaType}`);
    try {
      return await this.mediaTest.createAsset(displayName);
    } catch {
      this.num++;
      displayName = `${info.prefix}${name}_${this.num}${info.suffix}`;
      return await this.mediaTest.createAsset(displayName);
    }
  }

  async getFdPath(fileAsset: photoAccessHelper.PhotoAsset) {
    let fd = await fileAsset.open('rw');
    Logger.info(this.tag, `fd = ${fd}`);
    return fd;
  }

  // Photo Format
  onChangePhotoFormat() {
    if (this.settingDataObj.photoFormat === 0) {
      return 'png';
    }
    if (this.settingDataObj.photoFormat === 1) {
      return 'jpg';
    }
    if (this.settingDataObj.photoFormat === 2) { // 2:photoFormat
      return 'bmp';
    }
    if (this.settingDataObj.photoFormat === 3) { // 3:photoFormat
      return 'webp';
    }
    if (this.settingDataObj.photoFormat === 4) { // 4:photoFormat
      return 'jpeg';
    }
  }

  getInfoFromType(mediaType: number) {
    let result = {
      prefix: '', suffix: ''
    };
    switch (mediaType) {
      case Constants.IMAGE:
        result.prefix = 'IMG_';
        result.suffix = `.${this.onChangePhotoFormat()}`;
        break;
      case Constants.VIDEO:
        result.prefix = 'VID_';
        result.suffix = '.mp4';
        break;
      default:
        break;
    }
    return result;
  }
}